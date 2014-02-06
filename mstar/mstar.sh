#!/bin/bash
#
# Autor: Eneko Gonzalez
# Version: 1.0
#
# Script para generar uno o varios ficheros CSV a partir de una cartera de la pagina Morningstar.es

# Parametros que se leen de la linea de comandos con sus valores por defecto
FICHERO_COOKIES="cookies.txt"
GENERAR_FICHEROS_INDIVIDUALES=true
CARPETA_OUT="out"
VERBOSE=false
PORTFOLIO_ID=

# Funcion para escribir los mensajes en modo verbose
mensaje() {
	if [[ "$VERBOSE" = true ]]; then echo $1; fi
}

# Funcion para explicar como los parametros
usage() {
cat << EOF

USO: $0 opciones portfolio_id

OPCIONES:
   -c [fichero]    Path del fichero con la cookie de morningstar.es. Por defecto $FICHERO_COOKIES
   -h              Muestra este mensaje de ayuda y finaliza
   -i              No generar los ficheros individuales (uno por cada fondo), solo genera un fichero CSV
   -o [ruta]       Path de la carpeta donde dejar los ficheros resultado. Si no existe, la intenta crear
   -v              Modo verbose para depurar los pasos ejecutados

EJEMPLOS:
  $0 2176038  
      
	  Genera los ficheros individuales para la cartera '2176038' en la carpeta '$CARPETA_OUT' usando el fichero de cookies '$FICHERO_COOKIES'
	  
  $0 -o salida 2176038  
      
	  Genera los ficheros individuales para la cartera '2176038' en la carpeta 'salida' usando el fichero de cookies '$FICHERO_COOKIES'
	  
  $0 -o salida -c mis_cookies.txt 2176038 
      
	  Genera los ficheros individuales para la cartera '2176038' en la carpeta 'salida' usando el fichero de cookies 'mis_cookies.txt'
EOF
}

# Leemos los parametros del script
while getopts "c:hio:v" opt; do
  case $opt in
    c)
      FICHERO_COOKIES=$OPTARG
	  ;;
    h)
      usage
      exit 1
      ;;
    i)
      GENERAR_FICHEROS_INDIVIDUALES=false
      ;;
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
shift $((OPTIND-1))
if (( $# != 1 )); then
    echo "Falta el parametro portfolio_id" 
	usage
	exit 1
else 
	PORTFOLIO_ID=$1
fi

# Comprobamos si existe el fichero de cookies
if [[ ! -f "${FICHERO_COOKIES}" ]]; then
  echo "No existe el fichero ${FICHERO_COOKIES}, abortando"
  usage
  exit 1
fi

# Si no existe la carpeta de salida, la intentamos crear
if [[ ! -d "${CARPETA_OUT}" ]]; then
	mensaje "La carpeta $CARPETA_OUT no existe"
	mkdir "$CARPETA_OUT"
	mensaje "Carpeta $CARPETA_OUT creada"
fi

# Creamos el fichero dat si no existe
if [ ! -f $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat ]; then
  > $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat
  mensaje "Creado fichero $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat"
fi

# Nos conectamos a la pagina para extraer los datos de la cartera
wget --load-cookies $FICHERO_COOKIES --output-document=$CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm "http://www.morningstar.es/es/portfoliomanager/portfolio.aspx?Portfolio_ID=$PORTFOLIO_ID"
if [ $? -ne 0 ]; then
  echo "Error al descargar el portfolio de http://www.morningstar.es/es/portfoliomanager/portfolio.aspx?Portfolio_ID=$PORTFOLIO_ID, abortando"
  exit $?
fi

# Leemos el fichero descargado y lo convertimos en un fichero con este formato: "ID;Nombre;AAAAMMDD;Fecha;VL"
cat $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm | gawk 'match( $0, /snapshot\.aspx\?id=([A-Za-z0-9]*)">([^<]*).*title="([^"/]*)\/([^/]*)\/([^"]*)[^>]*>([^<]*)/, grupos) { print grupos[1] ";" grupos[2] ";" grupos[5] grupos[4] grupos[3] ";" grupos[3] "/" grupos[4] "/" grupos[5] ";" grupos[6]}' > $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp 

# Juntamos el fichero temporal con el dat, ordenando alfabeticamente
cat $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp| sort -r -u -o $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat

# Copiamos el fichero dat como csv
cp $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.csv

# Partimos el fichero dat en varios ficheros csv, uno por ID, usando como nombre ID-Nombre
gawk -F ";" -v OUT="$CARPETA_OUT/" '{close(f);c=gensub("[^[:alnum:]]", "_", "g", $2);f=$1"-"c}{print > OUT f ".csv"}' $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat

# Borramos los ficheros temporales generados
rm $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm
rm $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp
