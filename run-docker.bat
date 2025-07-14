@echo off
setlocal enabledelayedexpansion

:: Supprimer les containers et volumes, puis les reconstruire
docker compose -p alif down --rmi all -v --remove-orphans
docker compose -f compose/docker-compose.yml down -v --remove-orphans
docker compose -p alif -f compose/docker-compose.yml up -d --build

:: Attendre que le container gitlab soit bien configurer
echo Attente de GitLab...
:waitGitLab
docker compose -p alif exec gitlab curl -s http://localhost/-/health | findstr "OK" >nul
if errorlevel 1 (
    timeout /t 3 >nul
    goto waitGitLab
)
echo GitLab est pret !

:: Récupérer le password gitlab admin
echo Recuperation des informations gitlab

set "password="
for /F "delims=" %%A in ('
  docker compose -p alif exec gitlab bash -c "if [ -f /etc/gitlab/initial_root_password ]; then cat /etc/gitlab/initial_root_password | grep Password: | cut -d' ' -f2-; fi"
') do set "password=%%A"

:: Récupérer l'email gitlab admin
set "email="
for /F "delims=" %%A in ('
  docker compose -p alif exec postgres psql -U gitlab -d gitlabhq_production -t -c "select email from users where username = 'root' limit 1"
') do set "email=%%A"

setlocal disabledelayedexpansion
set "token="
for /F "delims=" %%A in ('docker compose -p alif exec gitlab gitlab-rails runner "puts PersonalAccessToken.create!(user: User.find_by_username('root'), name: 'token-script', scopes: [:api], expires_at: 30.days.from_now).token;"') do set "token=%%A"
setlocal enabledelayedexpansion


:: Creer les projets gitlab
echo --------------------------------
echo Intialiser gitlab et verdaccio

set "line#=0"
for /f "usebackq delims=" %%A in (`node --no-warnings .\script\start.js %token%`) do (
    if !line#! EQU 0 (
      set "PLUGIN_AUTH_GITLAB_APPLICATION_ID=%%A"
    ) else if !line#! EQU 1 (
      set "PLUGIN_AUTH_GITLAB_APPLICATION_SECRET=%%A"
    )
    set /a line#+=1
)

git -C ../services-custom/storybook push "http://root:%token%@gitlab.local/storybook/storybook.git" HEAD:main
docker compose -p alif -f compose\docker-compose.yml --profile manual up -d verdaccio

:: set .npmrc dans storybook
echo Mettre storybook dans verdaccio

set "VERDACCIO_URL="
for /f "tokens=2 delims==" %%V in ('findstr /b "VERDACCIO_URL=" "compose\.env"') do (
    set "VERDACCIO_URL=%%V"
    goto :found
)
:found

:: utilisation de la commande call car npm-cli-login cloture le processus
call npx -y npm-cli-login ^
   -u root ^
   -p %password% ^
   -e %email% ^
   -r %VERDACCIO_URL% ^
   -s @das/storybook

call npm publish ../services-custom/storybook --registry http://localhost:4873

:: Afficher les informations gitlab
echo --------------------------------
echo GitLab root Email: %email%
echo GitLab root Password: %password%
echo GitLab root Token: %token%