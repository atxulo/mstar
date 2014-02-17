@REM Script para ejecutar limpiar_cookies.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)
call "../setEnv.bat"

%CYGWIN_BIN%\bash %MSTAR%\util\limpiar_cookies.sh %MSTAR%\cookies.txt
@pause
