@REM Script para configurar las rutas en entornos Windows utilizando Cygwin (http://www.cygwin.com/)

@REM Antes de ejecutar, es necesario tener Cygwin instalado y modificar la ruta de instalacion en la siguiente linea
@REM Tambien es necesario modificar la ruta de instalacion de los scripts

@REM Ruta de instalacion de Cygwin
@set CYGWIN_BIN="c:\cygwin64\bin"
@set PATH=%CYGWIN_BIN%;%PATH%

@REM Ruta de instalacion del script mstar
@set MSTAR="c:\mstar"

@REM Ruta de salida de los scripts
@set MSTAR_SALIDA="c:\mstar\salida"

@REM Ruta de copias de seguridad
@set MSTAR_BACKUP="c:\mstar\backup"