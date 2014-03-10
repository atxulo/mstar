@REM Script para comprobar que el entorno se ha configurado correctamente
@set result=0

@REM Comprobamos que existe el fichero setEnv.bat en este mismo directorio
@if not exist "./setEnv.bat" (
  echo ERROR: No existe el fichero setEnv.bat
  set result=1
) else (
  echo Fichero setEnv.bat encontrado. CORRECTO
)

@REM Ejecutamos el fichero setEnv.bat para poder comprobar sus variables
@call "setEnv.bat"

@REM Comprobando CYGWIN_BIN
@if "%CYGWIN_BIN%"==""  (
  echo ERROR: No se ha definido la variable CYGWIN_BIN
  set result=1
) else (
  echo Variable CYGWIN_BIN definida con valor %CYGWIN_BIN%. CORRECTO
  @if not exist "%CYGWIN_BIN%\bash.exe" (
	echo ERROR: No se ha encontrado el fichero %CYGWIN_BIN%/bash.exe. Comprueba que la ruta definida por la variable CYGWIN_BIN es correcta
	set result=1
  ) else (
    echo Fichero %CYGWIN_BIN%\bash.exe encontrado. CORRECTO
  )
)

@REM Comprobamos que podemos ejecutar el comando wget y gawk
@wget --version > NUL
@if %errorlevel% neq 0 (
  echo ERROR: No se encuentra el comando wget. Comprueba que se halla instalado con Cygwin y que la ruta de Cygwin esta en el path
  set result=1
) else (
  echo Comando wget encontrado en el PATH. CORRECTO
)

@gawk --version > NUL
@if %errorlevel% neq 0 (
  echo ERROR No se encuentra el comando gawk. Comprueba que se halla instalado con Cygwin y que la ruta de Cygwin esta en el path
  set result=1
) else (
  echo Comando gawk encontrado en el PATH. CORRECTO
)

@REM Comprobamos que la ruta del script esta definida y que existen los ficheros mstar.sh y mstar.bat
@if "%MSTAR%"==""  (
  echo ERROR: No se ha definido la variable MSTAR
  set result=1
) else (
  echo Variable MSTAR definida con valor %MSTAR%. CORRECTO
  @if not exist "%MSTAR%\mstar.sh" (
	echo ERROR: No se ha encontrado el fichero %MSTAR%\mstar.sh. Comprueba que la ruta definida por la variable MSTAR es correcta
	set result=1
  ) else (
    echo Fichero %MSTAR%\mstar.sh encontrado. CORRECTO
  )
  @if not exist "%MSTAR%\Windows\mstar.bat" (
	echo ERROR: No se ha encontrado el fichero %MSTAR%\Windows\mstar.bat. Comprueba que la ruta definida por la variable MSTAR es correcta
	set result=1
  ) else (
    echo Fichero %MSTAR%\Windows\mstar.bat encontrado. CORRECTO
  )  
)

@REM Mostramos un mensaje al final
@if %result% equ 0 (
	echo Comprobaciones finalizadas sin haber encontrado errores
) else (
	echo Se han encontrado errores al realizar las comprobaciones, revise los mensajes anteriores
)

@pause
