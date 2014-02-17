@REM Script para ejecutar limpiar_cookies.sh desde entornos Windows utilizando Cygwin (http://www.cygwin.com/)

@REM Antes de ejecutar, es necesario tener Cygwin instalado y modificar la ruta de instalacion en la siguiente linea
@REM Tambien puede ser necesario modificar en la ultima linea el fichero de cookies a editar

@set CYGWIN_BIN="c:\cygwin64\bin"
@set PATH=%CYGWIN_BIN%;%PATH%

%CYGWIN_BIN%\bash limpiar_cookies.sh cookies.txt
@pause
