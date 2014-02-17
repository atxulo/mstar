@REM Script para ejecutar mstar_euro_dolar.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)
call "../setEnv.bat"

%CYGWIN_BIN%\bash %MSTAR%\util\mstar_euro_dolar.sh -o %MSTAR%\salida
@pause
