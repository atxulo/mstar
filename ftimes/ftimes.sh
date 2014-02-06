#!/bin/bash
#
# Autor: Eneko Gonzalez
# Version: 1.0
#
# Script para generar un fichero CSV a partir de la informacion del Financial Times

# Parametros que se leen de la linea de comandos con sus valores por defecto
FICHERO_CONFIG="ftimes.cfg"
CARPETA_OUT="out"
VERBOSE=false

# Funcion para escribir los mensajes en modo verbose
mensaje() {
	if [[ "$VERBOSE" = true ]]; then echo $1; fi
}

# Funcion para explicar como los parametros
usage() {
cat << EOF

USO: $0 options

OPCIONES:
   -h              Muestra este mensaje de ayuda y finaliza.
   -i [fichero]    Ruta del fichero de configuracion con los ISIN de los fondos. Por defecto '$FICHERO_CONFIG'
   -o [ruta]       Path de la carpeta donde dejar los ficheros resultado. Si no existe, la intenta crear
   -v              Modo verbose para depurar los pasos ejecutados
   
   
EOF
}

# Parametros que se leen de la linea de comandos con sus valores por defecto
while getopts "hi:o:v" opt; do
  case $opt in
    h)
      usage
      exit 1
      ;;
    i)
      FICHERO_CONFIG=$OPTARG
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

# Comprobamos si existe el fichero de configuracion
if [[ ! -f "${FICHERO_CONFIG}" ]]; then
  echo "No existe el fichero ${FICHERO_CONFIG}, abortando."
  usage
  exit 1
fi

# Si no existe la carpeta de salida, la intentamos crear
if [[ ! -d "${CARPETA_OUT}" ]]; then
	mensaje "La carpeta $CARPETA_OUT no existe"
	mkdir "$CARPETA_OUT"
	mensaje "Carpeta $CARPETA_OUT creada"
fi

# Calculamos fechas auxiliares que se usan en el procesado
hoy=$(date +"%Y%m%d")
pasadoAnyo=$(date -d "-1 year" +"%Y")

# Procesamos el fichero de entrada
while read linea_fichero_config; do
  if [[ $linea_fichero_config != \#* ]]; then # Saltamos los comentarios
    # Leemos ambos lados del =
    isin=${linea_fichero_config%=*}
    isin_desc=${linea_fichero_config#*=}

    mensaje "Obteniendo informacion de $isin_desc - ISIN: $isin"

    # Descargamos datos del Finantial Times y nos quedamos con la tabla de datos
    lynx -dump http://markets.ft.com/research//Tearsheets/PriceHistoryPopup?symbol=$isin | grep -o '.*day.*\%$' | cut -d' ' -f5,6,7 > "$CARPETA_OUT/$isin-$isin_desc.tmp"
    mensaje "Generado fichero $CARPETA_OUT/$isin-$isin_desc.tmp"

    # Creamos el fichero csv si no existe
    if [ ! -f "$CARPETA_OUT/$isin-$isin_desc.csv" ]; then
      > "$CARPETA_OUT/$isin-$isin_desc.csv"
      mensaje "Creado fichero $CARPETA_OUT/$isin-$isin_desc.csv"
    fi

    # Borramos el fichero csv.tmp si ya existe, y lo creamos vacio
    if [ -f "$CARPETA_OUT/$isin-$isin_desc.csv.tmp" ]; then
      rm "$CARPETA_OUT/$isin-$isin_desc.csv.tmp"
      mensaje "Borrado fichero $CARPETA_OUT/$isin-$isin_desc.csv.tmp de una ejecucion anterior y creado de nuevo"
    fi
    > "$CARPETA_OUT/$isin-$isin_desc.csv.tmp"

    # Leemos el fichero temporal y por cada linea, extraemos la fecha
    while read linea_fichero_tmp; do
      fecha=$(echo $linea_fichero_tmp | cut -d' ' -f1,2)
      valor=$(echo ${linea_fichero_tmp//./,} | cut -d' ' -f3)  # Reemplazamos el . por la ,
      fechaEsteAnyo=$(date -d "$fecha" +"%Y%m%d")
      fechaAnyoPasado=$(date -d "$fecha $pasadoAnyo" +"%Y%m%d")

      # Vemos si la fecha es de este anyo o el anterior
      if [[ $hoy -lt $fechaEsteAnyo ]]; then
        fechaConAnyo=$(date -d "$fechaAnyoPasado" +"%d/%m/%Y")
        fechaConAnyoAMD=$(date -d "$fechaAnyoPasado" +"%Y%m%d")
      else
        fechaConAnyo=$(date -d "$fechaEsteAnyo" +"%d/%m/%Y")
        fechaConAnyoAMD=$(date -d "$fechaEsteAnyo" +"%Y%m%d")
      fi
      lineaCSV="$fechaConAnyoAMD;$fechaConAnyo;$valor"

      # Escribimos las lineas que no existan ya en el fichero
      if ! grep -qe "$lineaCSV" "$CARPETA_OUT/$isin-$isin_desc.csv"; then
        echo "$lineaCSV" >> "$CARPETA_OUT/$isin-$isin_desc.csv.tmp"
      fi
    done <"$CARPETA_OUT/$isin-$isin_desc.tmp"

    # Mezclamos los ficheros .csv y .csv.tmp en uno solo, ordenado
    sort -r -m -u "$CARPETA_OUT/$isin-$isin_desc.csv" "$CARPETA_OUT/$isin-$isin_desc.csv.tmp" -o "$CARPETA_OUT/$isin-$isin_desc.csv"
	
	# Borramos los ficheros temporales generados
	rm "$CARPETA_OUT/$isin-$isin_desc.csv.tmp"
	rm "$CARPETA_OUT/$isin-$isin_desc.tmp"
  fi
done <"$FICHERO_CONFIG"
