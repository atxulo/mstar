#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para generar un fichero CSV a partir de la lista de categorias de la pagina Morningstar.es
AHORA=$(date +"%Y%m%d_%H%M%S_%N")

# Parametros que se leen de la linea de comandos con sus valores por defecto
CARPETA_BACKUP=
CARPETA_OUT="out"
VERBOSE=false
DEBUG=false

# Funcion para copiar un fichero en una ruta de backup
# $1 ruta del fichero del que hacer backup
backupFichero() {
  nombreFichero="${1##*/}"
  cp $1 $CARPETA_BACKUP"/"$AHORA"_"$nombreFichero".bak"
  if [ ! $? -eq 0 ]; then
    echo "Error al hacer una copia de seguridad del fichero '$1' en '$CARPETA_BACKUP/$AHORA_$nombreFichero.bak', abortando."
    exit 1
  fi
}

# Funcion para escribir los mensajes en modo verbose
# $1 mensaje a escribir
mensaje() {
	if [[ "$VERBOSE" = true ]]; then echo $1 1>&2; fi
}

# Funcion para escribir los mensajes en modo debug
# $1 mensaje a escribir
mensaje_debug() {
  if [[ "$DEBUG" = true ]]; then echo "DEBUG: $1" 1>&2; fi
}

trim() {
    local var=$@
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}

# Funcion para explicar como los parametros
usage() {
cat << EOF

USO: $0 opciones

OPCIONES:
   -b [ruta]       Path de la carpeta donde dejar una copia de seguridad de los ficheros. Si no se indica, no se hace copia.
   -d              Modo debug para depurar con mas informacion que en modo verbose
   -h              Muestra este mensaje de ayuda y finaliza
   -o [ruta]       Path de la carpeta donde dejar los ficheros resultado. Si no existe, la intenta crear
   -v              Modo verbose para depurar los pasos ejecutados

EJEMPLOS:
  $0 -o salida
	  Genera el fichero en la carpeta 'salida'
EOF
}

# Leemos los parametros del script
while getopts "b:dho:v" opt; do
  case $opt in
    b)
      CARPETA_BACKUP=$OPTARG
	  ;;
	  d)
	    # Debug implica Verbose tambien
	    DEBUG=true
      VERBOSE=true
      ;;
    h)
      usage
      exit 1
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

# Si no existe la carpeta de salida, la intentamos crear
if [[ ! -d "${CARPETA_OUT}" ]]; then
  mensaje "La carpeta $CARPETA_OUT no existe"
  mkdir "$CARPETA_OUT"
  mensaje "Carpeta $CARPETA_OUT creada"
fi

# Si se ha indicado, intentamos crear la carpeta de backup
if [ ! -z "$CARPETA_BACKUP" ]; then
  if [[ ! -d "${CARPETA_BACKUP}" ]]; then
    mkdir "$CARPETA_BACKUP"
    if [ ! $? -eq 0 ]; then
      echo "Error crear la carpeta de backup '$CARPETA_BACKUP', abortando."
      exit 1
    fi
  fi
fi

# Creamos los ficheros dat si no existen, y si existen, hacemos backup si asi se ha indicado
if [ ! -f $CARPETA_OUT/mstar_categorias.dat ]; then
  > $CARPETA_OUT/mstar_categorias.dat
  mensaje "Creado fichero $CARPETA_OUT/mstar_categorias.dat"
else
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_categorias.dat"
  fi
fi

# Nos conectamos a la pagina para extraer los datos de las categorias
# No se puede poner --remote-encoding=ISO-8859-1 porque da error en windows
wget --output-document=$CARPETA_OUT/mstar_categorias.html.tmp "http://www.morningstar.es/es/tools/categoryoverview.aspx"
if [ $? -ne 0 ]; then
  echo "Error al descargar el contenido de http://www.morningstar.es/es/tools/categoryoverview.aspx, abortando"
  exit $?
fi

# Leemos el fichero descargado y lo convertimos en un fichero con este formato: "ID;Nombre;YTD;Fecha"
# Como es susceptible de fallar, lo hacemos paso a paso y así podemos depurar mas facil
# No usamos sed -i porque en MacOS da problemas: http://stackoverflow.com/questions/5694228/sed-in-place-flag-that-works-both-on-mac-bsd-and-linux

# Buscamos la linea con CategoryOverviewTable
grep -i CategoryOverviewTable "$CARPETA_OUT/mstar_categorias.html.tmp" > "$CARPETA_OUT/mstar_categorias.dat.tmp2"
mensaje_debug "---------- Linea CategoryOverviewTable ----------"
mensaje_debug "$(cat $CARPETA_OUT/mstar_categorias.dat.tmp2)"
mensaje_debug "---------- Fin linea CategoryOverviewTable ----------"

# Cambiamos los /td y el tbody por saltos de linea para tener cada campo en una linea 
sed -e 's/<\/td>/\n/g' -e 's/<tbody>/<tbody>\n/g' "$CARPETA_OUT/mstar_categorias.dat.tmp2" > "$CARPETA_OUT/mstar_categorias.dat.tmp" 
mensaje_debug "---------- Separado en lineas ----------"
mensaje_debug "$(cat $CARPETA_OUT/mstar_categorias.dat.tmp)"
mensaje_debug "---------- Fin separado en lineas ----------"

# Eliminamos los campos que no interesan
sed -ne '/gridCategoryName/p' -ne '/gridReturnM0/p' -ne '/gridTrailingDate/p' "$CARPETA_OUT/mstar_categorias.dat.tmp" > "$CARPETA_OUT/mstar_categorias.dat.tmp2"
mensaje_debug "---------- Filtrado campos ----------"
mensaje_debug "$(cat $CARPETA_OUT/mstar_categorias.dat.tmp2)"
mensaje_debug "---------- Fin filtrado campos ----------"

# Eliminamos los td que quedan
sed -ne 's/.*<td[^>]*>//p' "$CARPETA_OUT/mstar_categorias.dat.tmp2" > "$CARPETA_OUT/mstar_categorias.dat.tmp"
mensaje_debug "---------- Eliminacion td restantes ----------"
mensaje_debug "$(cat $CARPETA_OUT/mstar_categorias.dat.tmp)"
mensaje_debug "---------- Fin eliminacion td restantes ----------"

# Obtenemos el titulo y el ID del enlace
sed -e 's/.*default\.aspx?category=\([^"]*\)" title="\([^"]*\)".*/\1\n\2/' "$CARPETA_OUT/mstar_categorias.dat.tmp" > "$CARPETA_OUT/mstar_categorias.dat.tmp2"
mensaje_debug "---------- Obtencion de campos del enlace ----------"
mensaje_debug "$(cat $CARPETA_OUT/mstar_categorias.dat.tmp2)"
mensaje_debug "---------- Fin obtencion de campos del enlace ----------"

# Pintamos los campos separados por ; cada 4 campos
gawk 'ORS=NR%4?";":"\n"' "$CARPETA_OUT/mstar_categorias.dat.tmp2" > "$CARPETA_OUT/mstar_categorias.dat.tmp"
mensaje_debug "---------- Agrupacion de campos ----------"
mensaje_debug "$(cat $CARPETA_OUT/mstar_categorias.dat.tmp)"
mensaje_debug "---------- Fin agrupacion de campos ----------"

# Quitamos las lineas que tienen un - al final porque no tienen valor
sed -e '/\;-$/d' "$CARPETA_OUT/mstar_categorias.dat.tmp" > "$CARPETA_OUT/mstar_categorias.dat.tmp2" 
mensaje_debug "---------- Borrado lineas sin valor ----------"
mensaje_debug "$(cat $CARPETA_OUT/mstar_categorias.dat.tmp2)"
mensaje_debug "---------- Fin borrado lineas sin valor ----------"

# Movemos el fichero temporal auxiliar 
mv -f $CARPETA_OUT/mstar_categorias.dat.tmp2 $CARPETA_OUT/mstar_categorias.dat.tmp

# Juntamos el fichero temporal con el dat, ordenando alfabeticamente (asc) y por fecha (desc)
cat $CARPETA_OUT/mstar_categorias.dat $CARPETA_OUT/mstar_categorias.dat.tmp | sort -u -t\; -k2,2r -k4,4 -o $CARPETA_OUT/mstar_categorias.dat

# Si ya existe el CSV, hacemos el backup si asi se ha indicado 
if [[ -f "${CARPETA_OUT}/mstar_categorias.csv" ]]; then
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_categorias.csv"
  fi
fi

# Copiamos el fichero dat como csv corrigiendo el encoding para no perder acentos
# solo si esta instalado iconv
command -v iconv >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "iconv NO INSTALADO. Es posible que se pierdan los acentos y caracteres especiales"
  cp -f $CARPETA_OUT/mstar_categorias.dat $CARPETA_OUT/mstar_categorias.csv 
else
  iconv -f utf-8 -t iso-8859-1 <  $CARPETA_OUT/mstar_categorias.dat > $CARPETA_OUT/mstar_categorias.csv
fi


# Borramos los ficheros temporales generados
rm $CARPETA_OUT/mstar_categorias.html.tmp
rm $CARPETA_OUT/mstar_categorias.dat.tmp

mensaje "Proceso finalizado correctamente"
exit 0
