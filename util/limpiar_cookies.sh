#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para limpiar el fichero de cookies, eliminando las que no son necesarias

# Parametros que se leen de la linea de comandos con sus valores por defecto

# Comprobamos los parametros
if (($# != 1)); then
  echo "ERROR; falta el parametro con el fichero de cookies a limpiar"
  echo "Ejemplo: $0 cookies.txt"
  exit 1
fi

# Comprobamos si existe el fichero de cookies
if [[ ! -f "$1" ]]; then
  echo "No existe el fichero $1, abortando"
  exit 1
fi

# Eliminamos las lineas innecesarias
sed -i".bak" -e '/morningstar/!d' $1
