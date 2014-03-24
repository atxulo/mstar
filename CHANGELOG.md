## 1.1.0 (24/03/2014)

Correciones:

 - Cuando el ID del portolio es incorrecto, el script ya finaliza sin avisar al usuario (https://github.com/enekogb/mstar/issues/45)
 - Al descargar los fuentes de GitHub con el cliente Windows, ya no se modifican los saltos de linea de los scripts (https://github.com/enekogb/mstar/issues/46)
 - El script mstar_movimientos ya permite tener más de un movimiento en la misma fecha, siempre que no sean exactamente iguales.

Cambios:

  - Añadido parametro -a para permitir cambiar de nombre a los ficheros generados (https://github.com/enekogb/mstar/issues/47)
  - Añadida verificación de que el login se ha hecho correctamente (https://github.com/enekogb/mstar/issues/36)
  - El script mstar.sh ajusta los saltos de linea del fichero DAT en cada ejecución para permitir la edición del mismo.
