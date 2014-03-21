@REM Script para ejecutar mstar_movimientos.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)
call "setEnv.bat"

%CYGWIN_BIN%\bash %MSTAR%\mstar_movimientos.sh -b %MSTAR_BACKUP% -c %MSTAR%\cookies.txt -u usuario -p password -o %MSTAR_SALIDA% 123456
@pause
