#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para eliminar del fichero mstar_portolio_xxx.dat las lineas anteriores a una fecha
AHORA=$(date +"%Y%m%d_%H%M%S_%N")

# Parametros que se leen de la linea de comandos con sus valores por defecto
CARPETA_BACKUP=

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

# Funcion para explicar como los parametros
usage() {
cat << EOF

USO: $0 opciones mstar_portfolio_id.dat fecha(AAAAMMDD)

OPCIONES:
   -b [ruta]       Path de la carpeta donde dejar una copia de seguridad de los ficheros. Si no se indica, no se hace copia.

EJEMPLOS:
  $0 mstar_portfolio_2176038.dat 20131231   
      
	  Elimina del fichero mstar_portfolio_2176038.dat y mstar_portfolio_2176038.csv los datos anteriores al 31 de Dic. 2013 (incluido)
EOF
}

# Leemos los parametros del script
while getopts "b:" opt; do
  case $opt in
    b)
      CARPETA_BACKUP=$OPTARG
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
if (($# != 2)); then
  echo "ERROR; faltan parametros"
  usage
  exit 1
fi

# Comprobamos si existe el fichero
if [[ ! -f "$1" ]]; then
  echo "No existe el fichero $1, abortando"
  exit 1
fi

# Nombre que debe tener el fichero CSV
nombreCSV=${1%.dat}".csv"

# Si se ha indicado, hacemos el backup
if [ ! -z "$CARPETA_BACKUP" ]; then
	# Si no existe la carpeta de backup, la intentamos crear
	if [[ ! -d "${CARPETA_BACKUP}" ]]; then
        mkdir "$CARPETA_BACKUP"
        if [ ! $? -eq 0 ]; then
          echo "Error crear la carpeta de backup '$CARPETA_BACKUP', abortando."
          exit 1
        fi
	fi
	backupFichero "$1"
	backupFichero "$nombreCSV"
fi

# Eliminamos las lineas innecesarias del fichero .dat utilizando un fichero tmp intermedio
awk -v cmpdate=$2 'BEGIN{FS=";"} {line=$0; aaaammdd=$3; if (aaaammdd>cmpdate) print line;}' $1 > $1.tmp && mv $1.tmp $1

# Copiamos el fichero dat como csv y eliminamos el nombre y fechas AAAAMMDD que solo necesitabamos para ordenar
cut -d\; -f1,4- $1 > $nombreCSV

exit 0