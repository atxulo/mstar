@REM Script para ejecutar mstar_consolidar.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)
call "setEnv.bat"

%CYGWIN_BIN%\bash %MSTAR%\mstar_consolidar.sh -b %MSTAR_BACKUP% mstar_portfolio_123456.dat 19991231
@pause
