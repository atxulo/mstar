## 1.1.0 (??/03/2014)

Correciones:

 - Cuando el ID del portolio es incorrecto, el script ya finaliza sin avisar al usuario (https://github.com/enekogb/mstar/issues/45)
 - Al descargar los fuentes de GitHub con el cliente Windows, ya no se modifican los saltos de linea de los scripts (https://github.com/enekogb/mstar/issues/46)
 - Cuando la carterar de Morningstar tiene acciones, el script mstar ya no las ignora, sino que obtiene su VL como si fuese un fondo (https://github.com/enekogb/mstar/issues/50)
 - El script mstar_movimientos ya permite tener más de un movimiento en la misma fecha, siempre que no sean exactamente iguales.


Cambios:

  - Añadido parametro -a para permitir cambiar de nombre a los ficheros generados (https://github.com/enekogb/mstar/issues/47)
  - Añadida verificación de que el login se ha hecho correctamente (https://github.com/enekogb/mstar/issues/36)
  - Añadido nuevo script mstar_ftimes.sh para obtener los datos de ftimes.
