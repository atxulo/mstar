@REM Script para ejecutar mstar.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)

@REM Antes de ejecutar, es necesario tener Cygwin instalado y modificar la ruta de instalacion en la siguiente linea

@set CYGWIN_BIN="c:\cygwin64\bin"
@set PATH=%CYGWIN_BIN%;%PATH%

%CYGWIN_BIN%\bash ftimes.sh
@pause
