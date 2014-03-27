@REM Script para corregir los saltos de linea en el fichero que se recibe como parametro
@REM para que sean como en Linux y asi los scripts funcionen sin problemas
call "setEnv.bat"

%CYGWIN_BIN%\perl -pi -e 's/\r//g' %1
@pause
