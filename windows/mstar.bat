@REM Script para ejecutar mstar.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)
call "setEnv.bat"

%CYGWIN_BIN%\bash %MSTAR%\mstar.sh -i -c %MSTAR%\salida\cookies.txt -o %MSTAR%\salida 123456
@pause
