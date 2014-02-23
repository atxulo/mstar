#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para eliminar del fichero mstar_portolio_xxx.dat las lineas anteriores a una fecha

# Comprobamos los parametros
if (($# != 2)); then
  echo "ERROR; faltan parametros"
  echo "Ejemplo: $0 mstar_portfolio_xxx.dat 20131231 para eliminar las lineas con fecha anterior al 31 de Dic. 2013 (incluido)"
  exit 1
fi

# Comprobamos si existe el fichero
if [[ ! -f "$1" ]]; then
  echo "No existe el fichero $1, abortando"
  exit 1
fi

# Eliminamos las lineas innecesarias del fichero .dat utilizando un fichero tmp intermedio
awk -v cmpdate=$2 'BEGIN{FS=";"} {line=$0; aaaammdd=$3; if (aaaammdd>cmpdate) print line;}' $1 > $1.tmp && mv $1.tmp $1

nombreCSV=${1%.dat}".csv"

# Copiamos el fichero dat como csv y eliminamos las fechas AAAAMMDD que solo necesitabamos para ordenar
cp $1 $nombreCSV
sed -i -e 's/\;[0-9]*\;/\;/1' $nombreCSV