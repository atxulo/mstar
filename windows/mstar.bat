@REM Script para ejecutar mstar.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)
call "setEnv.bat"

%CYGWIN_BIN%\bash %MSTAR%\mstar.sh -i -c %MSTAR%\cookies.txt -o %MSTAR_SALIDA% 123456
@pause
