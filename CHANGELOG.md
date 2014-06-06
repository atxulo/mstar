## 1.1.4 (06/06/2014)

Cambios:

  - Cuando la moneda del fondo no es EUR, ahora no falla si no es USD, sino que intenta localizar el cambio en la pagina del BCE. Esto funciona siempre que la moneda que muestra Morningstar tenga el mismo codigo que usa el BCE en sus enlaces (cambiando XXX por la moneda en cuestion): http://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.XXX.EUR.SP00.A

  Por ejemplo, funciona con dolares americanos (USD) y libras esterlinas (GBP):
  
  - http://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.USD.EUR.SP00.A
  - http://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.GBP.EUR.SP00.A

## 1.1.3 (05/05/2014)

Correcciones:

  - El script mstar_ftimes ya no ignora las acciones, sino que obtiene el valor de cierre de la pagina de ftimes.

## 1.1.2 (15/04/2014)

  - Nueva plantilla mstar_portfolio_plantilla_2.xlsm

## 1.1.1 (28/03/2014)

Correciones:

 - Cuando el VL es mayor que 1.000, el script mstar_ftimes ya convierte correctamente el separador de miles (https://github.com/enekogb/mstar/issues/53)

## 1.1.0 (27/03/2014)

Correciones:

 - Cuando el ID del portolio es incorrecto, el script ya finaliza sin avisar al usuario (https://github.com/enekogb/mstar/issues/45)
 - Al descargar los fuentes de GitHub con el cliente Windows, ya no se modifican los saltos de linea de los scripts (https://github.com/enekogb/mstar/issues/46)
 - Cuando la carterar de Morningstar tiene acciones, el script mstar ya no las ignora, sino que obtiene su VL como si fuese un fondo (https://github.com/enekogb/mstar/issues/50)
 - El script mstar_movimientos ya permite tener mas de un movimiento en la misma fecha, siempre que no sean exactamente iguales.


Cambios:

  - Nuevo parametro -a para permitir cambiar de nombre a los ficheros generados (https://github.com/enekogb/mstar/issues/47)
  - Nueva verificacion de que el login se ha hecho correctamente (https://github.com/enekogb/mstar/issues/36)
  - Nuevo nuevo script mstar_ftimes.sh (windows/mstar_ftimes.bat) para obtener los datos de ftimes.
  - Nuevo archivo windows/corregirSaltosLinea.bat para corregir saltos de linea despues de la edicion.
  - Nuevo archivo windows/mstar_consolidar.bat para eliminar registros de los ficheros dat y csv.
