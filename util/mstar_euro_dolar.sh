#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para obtener el historico de cambio euro-dolar de esta pagina:
# http://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.USD.EUR.SP00.A

# Parametros que se leen de la linea de comandos con sus valores por defecto
CARPETA_OUT="out"
VERBOSE=false

# Funcion para escribir los mensajes en modo verbose
mensaje() {
	if [[ "$VERBOSE" = true ]]; then echo $1; fi
}

# Funcion para explicar como los parametros
usage() {
cat << EOF

USO: $0 opciones

OPCIONES:
   -o [ruta]       Path de la carpeta donde dejar los ficheros resultado. Si no existe, la intenta crear
   -v              Modo verbose para depurar los pasos ejecutados

EJEMPLOS:  
  $0 -o salida  
	  Genera los ficheros individuales para la cartera '2176038' en la carpeta 'salida' usando el fichero de cookies 'mis_cookies.txt'
EOF
}

# Leemos los parametros del script
while getopts "c:hio:v" opt; do
  case $opt in
    o)
      CARPETA_OUT=$OPTARG
      ;;
    v)
      VERBOSE=true
      ;;	  
    \?)
      echo "Opcion desconocida: -$OPTARG" >&2
      usage
      exit 1
      ;;
    :)
      echo "La opcion -$OPTARG requiere un parametro" >&2
      usage
      exit 1
      ;;
  esac
done

# Si no existe la carpeta de salida, la intentamos crear
if [[ ! -d "${CARPETA_OUT}" ]]; then
	mensaje "La carpeta $CARPETA_OUT no existe"
	mkdir "$CARPETA_OUT"
	mensaje "Carpeta $CARPETA_OUT creada"
fi

# Creamos el fichero .dat si no existe
if [ ! -f $CARPETA_OUT/mstar_euro_dolar.dat ]; then
  > $CARPETA_OUT/mstar_euro_dolar.dat
  mensaje "Creado fichero $CARPETA_OUT/mstar_euro_dolar.dat"
  START=""
else
  # Si existe, obtenemos la ultima fecha del mismo, en formato dd-mm-aaaa
  START=$(head -1 $CARPETA_OUT/mstar_euro_dolar.dat | sed -e 's/[0-9]*\;\([0123456789/]*\)\;.*/\1/' -e 's/\//-/g')
  mensaje "Buscando cambios desde $START"
fi

# Nos conectamos a la pagina para extraer los datos de la cartera
wget --output-document=$CARPETA_OUT/mstar_euro_dolar.htm "http://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.USD.EUR.SP00.A&start=$START&ubmitOptions.x=55&submitOptions.y=4&trans=N"
if [ $? -ne 0 ]; then
  echo "Error al descargar la informacion de http://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.USD.EUR.SP00.A&start=$START&ubmitOptions.x=55&submitOptions.y=4&trans=N, abortando"
  exit $?
fi

# Leemos el fichero descargado y lo convertimos en un fichero con este formato: "AAAAMMDD;Fecha;Valor"
# Elimina las lineas anteriores a "tablestats"
# Elimina las posteriores a /table
# Elimina las que no tengan 8%
# Extrae y formatea la fecha (dd/mm/aaaa ) y el valor (#,####)
# Elimina las lineas que no han podido ser formateada y aun tienen el 8%
cat $CARPETA_OUT/mstar_euro_dolar.htm | sed -e '1,/table class=\"tablestats\">/ d' -e '/\/table/,$ d' -e '/8%/ !d' -e 's/.*8%[^>]*>\([0-9]*\)-\([0-9]*\)-\([0-9]*\)<\/td\>.*right\;\">\([0-9]*\)\.\([0-9]*\).*/\1\2\3\;\3\/\2\/\1\;\4,\5/' -e '/8%/ d' > $CARPETA_OUT/mstar_euro_dolar.dat.tmp

# Juntamos el fichero temporal con el dat, ordenando por AAAAMMDD (desc)
cat $CARPETA_OUT/mstar_euro_dolar.dat $CARPETA_OUT/mstar_euro_dolar.dat.tmp | sort -u -t\; -k1,1r -o $CARPETA_OUT/mstar_euro_dolar.dat

# Copiamos el fichero dat como csv y eliminamos las fechas AAAAMMDD que solo necesitabamos para ordenar
cp $CARPETA_OUT/mstar_euro_dolar.dat $CARPETA_OUT/mstar_euro_dolar.csv
sed -i -e 's/[0-9]*\;//1' $CARPETA_OUT/mstar_euro_dolar.csv

# Borramos los ficheros temporales generados
rm $CARPETA_OUT/mstar_euro_dolar.htm
rm $CARPETA_OUT/mstar_euro_dolar.dat.tmp
