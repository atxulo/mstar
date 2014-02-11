@REM Script para ejecutar mstar.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)

@REM Antes de ejecutar, es necesario tener Cygwin instalado y modificar la ruta de instalacion en la siguiente linea
@REM Tambien es necesario modificar en la ultima linea el valor 123456 por el ID de portfolio de MStar.

@set CYGWIN_BIN="c:\cygwin64\bin"
@set PATH=%CYGWIN_BIN%;%PATH%

%CYGWIN_BIN%\bash mstar.sh -i -o salida 123456
@pause
