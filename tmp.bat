@echo off
setlocal EnableDelayedExpansion


for /f "tokens=2 delims==" %%V in ('findstr /b "VERDACCIO_URL=" "compose\.env"') do (
    set "VERDACCIO_URL=%%V"
    goto :found
)
:found

npx -y npm-cli-login `
   -u root `
   -p %password% `
   -e %email% `
   -r %VERDACCIO_URL% `
   -s @alif/storybook `
   -s true          # always-auth


echo !VERDACCIO_URL!
endlocal