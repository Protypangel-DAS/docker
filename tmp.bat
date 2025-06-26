@echo off
setlocal enabledelayedexpansion


docker rm -f -v verdaccio-custom
docker volume rm -f verdaccio-conf
docker volume rm -f verdaccio-storage

docker rmi verdaccio-custom
docker build -t verdaccio-custom -f docker/verdaccio/.dockerfile docker/verdaccio


set "token="
set "email="
set "password="

set "line#=0"
for /f "usebackq delims=" %%A in (`node --no-warnings .\script\start.js %token%`) do (
    if !line#! EQU 0 (
      set "PLUGIN_AUTH_GITLAB_APPLICATION_ID=%%A"
    ) else if !line#! EQU 1 (
      set "PLUGIN_AUTH_GITLAB_APPLICATION_SECRET=%%A"
    )
    set /a line#+=1
)

echo PLUGIN_AUTH_GITLAB_APPLICATION_ID=%PLUGIN_AUTH_GITLAB_APPLICATION_ID%
echo PLUGIN_AUTH_GITLAB_APPLICATION_SECRET=%PLUGIN_AUTH_GITLAB_APPLICATION_SECRET%

docker run -d ^
  --name verdaccio-custom ^
  --restart unless-stopped ^
  -p 4873:4873 ^
  --add-host gitlab.local:host-gateway ^
  -e PLUGIN_AUTH_GITLAB_APPLICATION_ID=%PLUGIN_AUTH_GITLAB_APPLICATION_ID% ^
  -e PLUGIN_AUTH_GITLAB_APPLICATION_SECRET=%PLUGIN_AUTH_GITLAB_APPLICATION_SECRET% ^
  -v verdaccio-storage:/verdaccio/storage ^
  -v verdaccio-conf:/verdaccio/conf ^
  verdaccio-custom

npm-cli-login -u root -p 'lWV5Q8sScA/ot5sZBRGr8zuzUPkhYIEfFV+c4s6D/eg=' -e 'gitlab_admin_748d30@example.com' -r http://localhost:4873

start /wait "" cmd /c "npm-cli-login -u root -p %password% -e %email% -r http://localhost:4873" && npm publish ..\storybook\ --registry  http://localhost:4873