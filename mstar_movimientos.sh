#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para generar un fichero CSV a partir de los movimientos de una cartera de la pagina Morningstar.es
AHORA=$(date +"%Y%m%d_%H%M%S_%N")

# Parametros que se leen de la linea de comandos con sus valores por defecto
ALIAS=
CARPETA_BACKUP=
FICHERO_COOKIES="cookies.txt"
ELIMINAR_DUPLICADOS=false
FICHERO_HTML_MOVIMIENTOS=
CARPETA_OUT="out"
MSTAR_PASS=
MSTAR_USER=
VERBOSE=false
PORTFOLIO_ID=

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

# Funcion para comprobar si el login se ha hecho correctamente
# $1 ruta del fichero html descargado de Morningstar.es
comprobarLogin() {
  # Buscamos el texto "Bienvenido a Morningstar, " para comprobar el nombre de usuario
  nombreUsuario=$(cat "$1" | sed -n -e 's/.*Bienvenido a Morningstar[, ]*\(.*\)/\1/p')
  if [ -z "$nombreUsuario" ]; then
	echo "Error al hacer login en la pagina de morningstar.es (comprueba el usuario y password), abortando." 1>&2
	rm "$1"
	exit 1
  else
    mensaje "Login verificado; nombre del usuario $nombreUsuario"
  fi	
}

# Funcion para explicar como los parametros
usage() {
cat << EOF

USO: $0 opciones portfolio_id

OPCIONES:
   -a alias        Alias de la cartera. Si se indica, los ficheros generados se llamaran xxx_ALIAS en vez de xxx_ID.
   -b [ruta]       Path de la carpeta donde dejar una copia de seguridad de los ficheros. Si no se indica, no se hace copia.
   -c [fichero]    Path del fichero con la cookie de morningstar.es. Por defecto $FICHERO_COOKIES
   -d              Indica si se quieren eliminar registros duplicados. Si no se indica, no se eliminan.   
   -f [fichero]    Path del fichero HTML descargado manualmente. Si no se indica, se conecta a Mstar para obtener los datos.
   -h              Muestra este mensaje de ayuda y finaliza
   -o [ruta]       Path de la carpeta donde dejar los ficheros resultado. Si no existe, la intenta crear
   -p password     Password de morningstar, para generar el fichero de cookies (opcional)
   -u usuario      Usuario de morningstar, para generar el fichero de cookies (opcional)
   -v              Modo verbose para depurar los pasos ejecutados

EOF
}

# Leemos los parametros del script
while getopts "a:b:c:df:ho:p:u:v" opt; do
  case $opt in
    a)
      ALIAS=$OPTARG
      ;;  
    b)
      CARPETA_BACKUP=$OPTARG
	  ;;
    c)
      FICHERO_COOKIES=$OPTARG
	  ;;
    d)
      ELIMINAR_DUPLICADOS=true
      ;;	  
	f)
	  FICHERO_HTML_MOVIMIENTOS=$OPTARG
	  ;;
    h)
      usage
      exit 1
      ;;
    o)
      CARPETA_OUT=$OPTARG
      ;;
    p)
      MSTAR_PASS=$OPTARG
      ;;
    u)
      MSTAR_USER=$OPTARG
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

# Calculamos el sujijo de los ficheros; si hay alias es el alias, si no, el ID
if [ ! -z "$ALIAS" ]; then
  sufijo=$ALIAS
else
  sufijo=$PORTFOLIO_ID
fi

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

# Si no se indica fichero de movimientos creamos las cookies
if [ -z "$FICHERO_HTML_MOVIMIENTOS" ]; then
  # Si hay usuario y password, intentamos crear el fichero de cookies aunque ya exista
  if [ ! -z "$MSTAR_USER" ] && [ ! -z "$MSTAR_PASS" ]; then
    mensaje "Generando fichero de cookies"
    wget --verbose -o log  --keep-session-cookies --save-cookies $FICHERO_COOKIES --output-document=$CARPETA_OUT/mstar_login.html.tmp --post-data "__VIEWSTATE=%2FwEPDwUKLTI2ODU5ODc1OA9kFgJmD2QWAgIDD2QWBgIBD2QWAgIBDxYCHgRocmVmBThodHRwOi8vd3d3Lm1vcm5pbmdzdGFyLmVzL2VzL0RlZmF1bHQuYXNweD9yZWRpcmVjdD1mYWxzZWQCCQ9kFgYCAQ8PFgIeBFRleHQFBkVudHJhcmRkAgMPDxYEHwEFVE5vIHNlIGhhIHBvZGlkbyBjb25lY3Rhci4gwqFFbCBjb3JyZW8gZWxlY3Ryw7NuaWNvIG8gbGEgY29udHJhc2XDsWEgc29uIGluY29ycmVjdG9zIR4HVmlzaWJsZWdkZAIFDzwrAAoBAA8WAh4IVXNlck5hbWUFDHBlcGVAcGVwZS5lc2QWAmYPZBYCAgMPDxYCHwEFDHBlcGVAcGVwZS5lc2RkAg0PZBYCAgEPFgIfAQWNATxzY3JpcHQgdHlwZT0ndGV4dC9qYXZhc2NyaXB0Jz50cnkge3ZhciBwYWdlVHJhY2tlciA9IF9nYXQuX2dldFRyYWNrZXIoJ1VBLTE4NDMxNy04Jyk7cGFnZVRyYWNrZXIuX3RyYWNrUGFnZXZpZXcoKTt9IGNhdGNoIChlcnIpIHsgfTwvc2NyaXB0PmRk&__EVENTVALIDATION=%2FwEWBAKepfiyAwKOlq3CBgLPsofsAwL6hO7FCQ%3D%3D&ctl00%24_MobilePlaceHolder%24LoginPanel%24UserName=$MSTAR_USER&ctl00%24_MobilePlaceHolder%24LoginPanel%24Password=$MSTAR_PASS&ctl00%24_MobilePlaceHolder%24LoginPanel%24loginBtn=Login" "http://www.morningstar.es/es/mobile/membership/login.aspx"
    if [[ -f "${CARPETA_OUT}/mstar_login.html.tmp" ]]; then
  	# Comprobamos si el fichero contiene el texto _loginError
  	grep "_loginError" "$CARPETA_OUT/mstar_login.html.tmp" > /dev/null
  	if [ $? -eq 0 ]; then
        rm "$CARPETA_OUT/mstar_login.html.tmp"
        echo "Error al generar el fichero de cookies (revisa el usuario y password) abortando" 1>&2
        exit 1
      fi
      rm "$CARPETA_OUT/mstar_login.html.tmp"
    fi
    mensaje "Fichero de cookies generado"
  fi
  
  # Comprobamos si existe el fichero de cookies
  if [[ ! -f "${FICHERO_COOKIES}" ]]; then
    echo "No existe el fichero ${FICHERO_COOKIES}, abortando"
    exit 1
  fi
fi

# Creamos el ficheros csv si no existe, y si existe, hacemos backup si asi se ha indicado
if [ ! -f $CARPETA_OUT/mstar_movimientos_$sufijo.csv ]; then
  > $CARPETA_OUT/mstar_movimientos_$sufijo.csv
  mensaje "Creado fichero $CARPETA_OUT/mstar_movimientos_$sufijo.csv"
else
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_movimientos_$sufijo.csv"
  fi
fi

# Si no se indica fichero de movimientos nos conectamos a la pagina para extraer los datos de los movimientos la cartera
if [ -z "$FICHERO_HTML_MOVIMIENTOS" ]; then
  wget --load-cookies $FICHERO_COOKIES --output-document=$CARPETA_OUT/mstar_movimientos_$sufijo.html.tmp --post-data "__EVENTTARGET=ctl00%24ctl00%24MainContent%24PM_MainContent%24pageSizeDropDownList&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATEFIELDCOUNT=8&__VIEWSTATE=%2FwEPDwUKLTY4MzczODgwNA8WBB4JU29ydEZpZWxkBQREYXRlHg1Tb3J0RGlyZWN0aW9uBQRERVNDFgJmD2QWAmYPZBYEZg9kFgICCA8WAh4HY29udGVudAWPAU1vcm5pbmdzdGFy4oCZcyBmcmVlIFBvcnRmb2xpbyBUb29sIGhlbHBzIHlvdSB1cGRhdGUsIHRyYWNrIGFuZCBhbmFseXNlIHRoZSBhc3NldCBhbGxvY2F0aW9uIGFuZCBwZXJmb3JtYW5jZSBvZiB5b3VyIGZ1bmRzIGFuZCBzdG9ja3MgcG9ydGZvbGlvZAIDD2QWAgIBD2QWAgIBD2QWBmYPZBYCAgEPZBYQAgIPZBYCZg8QZA8WBGYCAQICAgMWBBAFHy0tLUNhcnRlcmFzIHRyYW5zYWNjaW9uYWxlcyAtLS1lZxAFDVRyYW5zYWNjaW9uYWwFBzIxOTA1ODJnEAUYLS0tQ2FydGVyYXMgUsOhcGlkYXMgLS0tZWcQBQxFbmVrbyAtIFJlYWwFBzIxODYwOTZnFgECAWQCAw8WAh4EVGV4dAWNBA0KPCEtLVN0YXJ0IG9mIFByaW1hcnkgVGFiLS0%2BDQo8ZGl2IGNsYXNzPSJwbV90YWIiIHN0eWxlPSJ6LWluZGV4OiAtMSI%2BDQogICAgIDwhLS0gVHJhY2tpbmcgVGFiIC0tPg0KICAgIDxzcGFuIGNsYXNzPSJwbV90YWJfaW5hY3RpdmUiIG9uY2xpY2s9ImphdmFzY3JpcHQ6bG9jYXRpb249J3BvcnRmb2xpby5hc3B4P1BvcnRmb2xpb19JRD0yMTkwNTgyJyI%2BDQogICAgICAgIDxkaXYgY2xhc3M9InBtX3RhYl9pbmFjdGl2ZXRleHQiPlNlZ3VpbWllbnRvPC9kaXY%2BDQogICAgPC9zcGFuPg0KICAgIA0KICAgIDwhLS0gRWRpdCBUYWIgLS0%2BDQogICAgPHNwYW4gY2xhc3M9InBtX3RhYl9hY3RpdmUiIG9uY2xpY2s9ImphdmFzY3JpcHQ6bG9jYXRpb249J2VkaXR0cmFuc2FjdGlvbi5hc3B4P1BvcnRmb2xpb19JRD0yMTkwNTgyJyI%2BDQogICAgICAgIDxkaXYgY2xhc3M9InBtX3RhYl9hY3RpdmV0ZXh0ICI%2BRWRpdGFyPC9kaXY%2BDQogICAgPC9zcGFuPg0KDQogICAgDQo8L2Rpdj4NCjwhLS1FbmQgb2YgUHJpbWFyeSBUYWItLT4NCmQCBA8WAh8DBdoFPGRpdiBjbGFzcz0icG9ydGZvbGlvX3RhYl9iYXIiIHN0eWxlPSJ6LWluZGV4Oi0xIj48c3BhbiBjbGFzcz0icG9ydGZvbGlvX3RhYl9hY3RpdmUiIG9uY2xpY2s9ImphdmFzY3JpcHQ6bG9jYXRpb249J2VkaXR0cmFuc2FjdGlvbi5hc3B4P1BvcnRmb2xpb19JRD0yMTkwNTgyJzsiPjxkaXYgY2xhc3M9InBvcnRmb2xpb190YWJfYWN0aXZldGV4dCI%2BVHJhbnNhY2Npb25lczwvZGl2Pjwvc3Bhbj48c3BhbiBjbGFzcz0icG9ydGZvbGlvX3RhYl9pbmFjdGl2ZSIgb25jbGljaz0iamF2YXNjcmlwdDpsb2NhdGlvbj0nZGl2aWRlbmRzLmFzcHg%2FUG9ydGZvbGlvX0lEPTIxOTA1ODInOyI%2BPGRpdiBjbGFzcz0icG9ydGZvbGlvX3RhYl9pbmFjdGl2ZXRleHQiPkRpdmlkZW5kb3M8L2Rpdj48L3NwYW4%2BPHNwYW4gY2xhc3M9InBvcnRmb2xpb190YWJfaW5hY3RpdmUiIG9uY2xpY2s9ImphdmFzY3JpcHQ6bG9jYXRpb249J3NwbGl0cy5hc3B4P1BvcnRmb2xpb19JRD0yMTkwNTgyJzsiPjxkaXYgY2xhc3M9InBvcnRmb2xpb190YWJfaW5hY3RpdmV0ZXh0Ij5TcGxpdHM8&__VIEWSTATE1=L2Rpdj48L3NwYW4%2BPHNwYW4gY2xhc3M9InBvcnRmb2xpb190YWJfaW5hY3RpdmUiIG9uY2xpY2s9ImphdmFzY3JpcHQ6bG9jYXRpb249J3JlY3VycmluZy5hc3B4P1BvcnRmb2xpb19JRD0yMTkwNTgyJzsiPjxkaXYgY2xhc3M9InBvcnRmb2xpb190YWJfaW5hY3RpdmV0ZXh0Ij5SZWN1cnJlbnRlPC9kaXY%2BPC9zcGFuPjwvZGl2PmQCBg88KwANAQAPFgYeCFBhZ2VTaXplAhQeC18hRGF0YUJvdW5kZx4LXyFJdGVtQ291bnQCFGQWAmYPZBYqAgEPZBYIAgEPZBYCAgEPDxYCHwMFHk0mRyBPcHRpbWFsIEluY29tZSBBLUggRVVSIEluY2RkAgIPZBYCAgEPEA8WAh8FZ2RkZGQCBQ9kFgICAQ8QDxYCHwVnZBAVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFQUDRVVSA1VTRANHQlADSlBZA0NIRhQrAwVnZ2dnZ2RkAggPZBYCAgEPDxYCHwMFBTEyLDAwZGQCAg9kFggCAQ9kFgICAQ8PFgIfAwUIRWZlY3Rpdm9kZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQU2NSwwMGRkAgMPZBYIAgEPZBYCAgEPDxYCHwMFGUFiYW50ZSBBc2Vzb3JlcyBHbG9iYWwgRklkZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQQxLDAwZGQCBA9kFggCAQ9kFgICAQ8PFgIfAwUZQWJhbnRlIEFzZXNvcmVzIEdsb2JhbCBGSWRkAgIPZBYCAgEPEA8WAh8FZ2RkZGQCBQ9kFgICAQ8QDxYCHwVnZBAVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFQUDRVVSA1VTRANHQlADSlBZA0NIRhQrAwVnZ2dnZ2RkAggPZBYCAgEPDxYCHwMFBDEsMDBkZAIFD2QWCAIBD2QWAgIBDw8WAh8DBRlBYmFudGUgQXNlc29yZXMgR2xvYmFsIEZJZGQCAg9kFgICAQ8QDxYCHwVnZGRkZAIFD2QWAgIBDxAPFgIfBWdkEBUFA0VVUgNVU0QDR0JQA0pQWQNDSEYVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFCsDBWdnZ2dnZGQCCA9kFgICAQ8PFgIfAwUEMSwwMGRkAgYPZBYIAgEPZBYCAgEPDxYCHwMFGUFiYW50ZSBBc2Vzb3JlcyBHbG9iYWwgRklkZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQUxMiwwMGRkAgcPZBYIAgEPZBYCAgEPDxYCHwMFGUFiYW50ZSBBc2Vzb3JlcyBHbG9iYWwgRklkZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQYxNDQsMDBkZAIID2QWCAIBD2QWAgIBDw8WAh8DBRlBYmFudGUgQXNlc29yZXMgR2xvYmFsIEZJZGQCAg9kFgICAQ8QDxYCHwVnZGRkZAIFD2QWAgIBDxAPFgIfBWdkEBUFA0VVUgNVU0QDR0JQA0pQWQNDSEYV&__VIEWSTATE2=BQNFVVIDVVNEA0dCUANKUFkDQ0hGFCsDBWdnZ2dnZGQCCA9kFgICAQ8PFgIfAwUGMTQ0LDAwZGQCCQ9kFggCAQ9kFgICAQ8PFgIfAwUZQWJhbnRlIEFzZXNvcmVzIEdsb2JhbCBGSWRkAgIPZBYCAgEPEA8WAh8FZ2RkZGQCBQ9kFgICAQ8QDxYCHwVnZBAVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFQUDRVVSA1VTRANHQlADSlBZA0NIRhQrAwVnZ2dnZ2RkAggPZBYCAgEPDxYCHwMFCTE0LjU0NCwwMGRkAgoPZBYIAgEPZBYCAgEPDxYCHwMFGUFiYW50ZSBBc2Vzb3JlcyBHbG9iYWwgRklkZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQYxNDQsMDBkZAILD2QWCAIBD2QWAgIBDw8WAh8DBRlBYmFudGUgQXNlc29yZXMgR2xvYmFsIEZJZGQCAg9kFgICAQ8QDxYCHwVnZGRkZAIFD2QWAgIBDxAPFgIfBWdkEBUFA0VVUgNVU0QDR0JQA0pQWQNDSEYVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFCsDBWdnZ2dnZGQCCA9kFgICAQ8PFgIfAwUFMTIsMDBkZAIMD2QWCAIBD2QWAgIBDw8WAh8DBRlBYmFudGUgQXNlc29yZXMgR2xvYmFsIEZJZGQCAg9kFgICAQ8QDxYCHwVnZGRkZAIFD2QWAgIBDxAPFgIfBWdkEBUFA0VVUgNVU0QDR0JQA0pQWQNDSEYVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFCsDBWdnZ2dnZGQCCA9kFgICAQ8PFgIfAwUGMTMyLDAwZGQCDQ9kFggCAQ9kFgICAQ8PFgIfAwUIRWZlY3Rpdm9kZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQQxLDAwZGQCDg9kFggCAQ9kFgICAQ8PFgIfAwUIRWZlY3Rpdm9kZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQQxLDAwZGQCDw9kFggCAQ9kFgICAQ8PFgIfAwUIRWZlY3Rpdm9kZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQQxLDAwZGQCEA9kFggCAQ9kFgICAQ8PFgIfAwUeTSZHIE9wdGltYWwgSW5jb21lIEEtSCBFVVIgSW5jZGQCAg9kFgICAQ8QDxYCHwVnZGRkZAIFD2QWAgIBDxAPFgIfBWdkEBUFA0VVUgNVU0QDR0JQA0pQWQNDSEYVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFCsDBWdnZ2dnZGQCCA9kFgICAQ8PFgIfAwUIMS40NzYsMDBkZAIRD2QWCAIBD2QWAgIBDw8WAh8DBQhFZmVjdGl2b2RkAgIPZBYCAgEPEA8WAh8FZ2RkZGQCBQ9kFgICAQ8QDxYCHwVnZBAVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFQUDRVVSA1VTRANHQlADSlBZA0NIRhQrAwVnZ2dnZ2RkAggPZBYCAgEPDxYCHwMFBDIsMDBkZAISD2QWCAIBD2QWAgIBDw8W&__VIEWSTATE3=Ah8DBRlBYmFudGUgQXNlc29yZXMgR2xvYmFsIEZJZGQCAg9kFgICAQ8QDxYCHwVnZGRkZAIFD2QWAgIBDxAPFgIfBWdkEBUFA0VVUgNVU0QDR0JQA0pQWQNDSEYVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFCsDBWdnZ2dnZGQCCA9kFgICAQ8PFgIfAwUGMTQ0LDAwZGQCEw9kFggCAQ9kFgICAQ8PFgIfAwUIRWZlY3Rpdm9kZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQQxLDAwZGQCFA9kFggCAQ9kFgICAQ8PFgIfAwUIRWZlY3Rpdm9kZAICD2QWAgIBDxAPFgIfBWdkZGRkAgUPZBYCAgEPEA8WAh8FZ2QQFQUDRVVSA1VTRANHQlADSlBZA0NIRhUFA0VVUgNVU0QDR0JQA0pQWQNDSEYUKwMFZ2dnZ2dkZAIID2QWAgIBDw8WAh8DBQUxMiwwMGRkAhUPDxYCHgdWaXNpYmxlaGRkAgcPZBYIAhEPZBYEAgEPDxYCHwMFGEludHJvZHV6Y2Egbm9tYnJlIG8gSVNJThYEHgZvbmJsdXIFqwJjaGVja0Nhc2godGhpcy52YWx1ZSwnY3RsMDBfY3RsMDBfTWFpbkNvbnRlbnRfUE1fTWFpbkNvbnRlbnRfUE1DdXJyZW5jeScsJ2N0bDAwX2N0bDAwX01haW5Db250ZW50X1BNX01haW5Db250ZW50X3RiUHJpY2UnKTtjaGVja1NlbGxBbGwoJ2N0bDAwX2N0bDAwX01haW5Db250ZW50X1BNX01haW5Db250ZW50X2RkbFRyYW5zVHlwZUV4dGVuZGVkJywnY3RsMDBfY3RsMDBfTWFpbkNvbnRlbnRfUE1fTWFpbkNvbnRlbnRfaGZTZWNJbmZvJywnY3RsMDBfY3RsMDBfTWFpbkNvbnRlbnRfUE1fTWFpbkNvbnRlbnRfdGJTaGFyZXMnKR4Hb25jbGljawUyQ2xlYXJTZWFyY2hCb3godGhpcy5pZCwnSW50cm9kdXpjYSBub21icmUgbyBJU0lOJylkAgMPFgIfCQWKAXNob3dQb3B1cCh0aGlzLmlkLCdjdGwwMF9jdGwwMF9NYWluQ29udGVudF9QTV9NYWluQ29udGVudF90YlNlY05hbWUnLCdjdGwwMF9jdGwwMF9NYWluQ29udGVudF9QTV9NYWluQ29udGVudF9oZlNlY0luZm8nLCdlZGl0dHJhbnNhY3Rpb24nKWQCEw8QD2QWAh4Ib25jaGFuZ2UFemNoZWNrU2VsbEFsbCh0aGlzLmlkLCdjdGwwMF9jdGwwMF9NYWluQ29udGVudF9QTV9NYWluQ29udGVudF9oZlNlY0luZm8nLCdjdGwwMF9jdGwwMF9NYWluQ29udGVudF9QTV9NYWluQ29udGVudF90YlNoYXJlcycpEBUDB0NvbXByYXIGVmVuZGVyDFZlbmRlciB0b2RvcxUDATEBMgItMRQrAwNnZ2dkZAIXDw9kFgQeB29uZm9jdXMFH3Nob3dDYWxlbmRhcih0aGlzLmlkLCdkZC9tbS95JykfCQUfc2hvd0NhbGVuZGFyKHRoaXMuaWQsJ2RkL21tL3knKWQCGQ8QDxYGHg1EYXRhVGV4dEZpZWxkBQV0aXRsZR4ORGF0YVZhbHVlRmllbGQFBXZhbHVlHwVnZBAVBQNFVVIDVVNEA0dCUANKUFkDQ0hGFQUDRVVSA1VTRANHQlADSlBZA0NIRhQrAwVnZ2dnZ2RkAggPDxYOHgxQcmV2UGFnZVRleHQFCGFudGVyaW9yHg5DdXN0b21JbmZvVGV4dAUXPHNwYW4%2BMS0yMCBkZSA0MTwvc3Bhbj4eDUZpcnN0UGFn&__VIEWSTATE4=ZVRleHQFB3ByaW1lcm8eC1JlY29yZGNvdW50AikfBAIUHgxMYXN0UGFnZVRleHQFB8O6bHRpbW8eDE5leHRQYWdlVGV4dAUJc2lndWllbnRlZGQCCQ8QDxYGHwwFBXRpdGxlHw0FBXZhbHVlHwVnZBAVAwwyMCBwb3IgcMOhZy4MNTAgcG9yIHDDoWcuDTEwMCBwb3IgcMOhZy4VAwIyMAI1MAMxMDAUKwMDZ2dnFgFmZAIKDxAPFgYfDAUHc2VjbmFtZR8NBQlob2xkaW5naWQfBWdkEBUGEFRvZG9zIGxvcyBmb25kb3MZQWJhbnRlIEFzZXNvcmVzIEdsb2JhbCBGSSBCYXJjbGF5cyBSZW5kaW1pZW50byBFZmVjdGl2byBGSRNCZXN0aW52ZXIgR2xvYmFsIFBQCEVmZWN0aXZvHk0mRyBPcHRpbWFsIEluY29tZSBBLUggRVVSIEluYxUGAAg2MTYyMjI2NQg2MTY2NTEwMAg2MTY1NDIxMgg2MTYzOTA2NAg2MTY2NDM0NhQrAwZnZ2dnZ2cWAWZkAgEPZBYCAgEPDxYCHwdoZGQCAg9kFgQCAQ8WAh8DBYUWPHRhYmxlIGJvcmRlcj0iMCI%2BDQoJPHRyPg0KCQk8dGQgY2xhc3M9IkwyTW9zdFJlYWRMYXN0V2VlayI%2BPGRpdj4NCgkJCTxhIGNsYXNzPSJCMk1vc3RSZWFkTGFzdFdlZWsiIGhyZWY9Imh0dHA6Ly93d3cubW9ybmluZ3N0YXIuZXMvZXMvbmV3cy8xMjA4OTQvcHJlbWlvcy1tb3JuaW5nc3Rhci0yMDE0LS0tbG9zLW1lam9yZXMtZm9uZG9zLmFzcHg%2FcmVmc291cmNlPW1vc3RyZWFkIj7igKIgUHJlbWlvcyBNb3JuaW5nc3RhciAyMDE0IC0gTG9zLi4uPC9hPg0KCQk8L2Rpdj48L3RkPg0KCTwvdHI%2BPHRyPg0KCQk8dGQgY2xhc3M9IkwyTW9zdFJlYWRMYXN0V2VlayI%2BPGRpdj4NCgkJCTxhIGNsYXNzPSJCMk1vc3RSZWFkTGFzdFdlZWsiIGhyZWY9Imh0dHA6Ly93d3cubW9ybmluZ3N0YXIuZXMvZXMvbmV3cy8xMDkzNjkvdHJhcy1sYXMtJWMzJWJhbHRpbWFzLWNhJWMzJWFkZGFzLWVzLWVsLW1vbWVudG8taWRlYWwtcGFyYS1lbGV2YXItbGEtZXhwb3NpY2klYzMlYjNuLWVuLXZhbG9yZXMtZXVyb3Blb3MuYXNweD9yZWZzb3VyY2U9bW9zdHJlYWQiPuKAoiAiVHJhcyBsYXMgw7psdGltYXMgY2HDrWRhcywgZXMgZWwuLi48L2E%2BDQoJCTwvZGl2PjwvdGQ%2BDQoJPC90cj48dHI%2BDQoJCTx0ZCBjbGFzcz0iTDJNb3N0UmVhZExhc3RXZWVrIj48ZGl2Pg0KCQkJPGEgY2xhc3M9IkIyTW9zdFJlYWRMYXN0V2VlayIgaHJlZj0iaHR0cDovL3d3dy5tb3JuaW5nc3Rhci5lcy9lcy9uZXdzLzExNDY4NC9kaXNjdXNpJWMzJWIzbi0lYzIlYmZxdSVjMyVhOS1jb25zZWpvLWRhciVjMyVhZGEtYS11bi1pbnZlcnNvci1ub3ZhdG8uYXNweD9yZWZzb3VyY2U9bW9zdHJlYWQiPuKAoiBEaXNjdXNpw7NuOiDCv1F1w6kgY29uc2VqbyBkYXLDrWEgYSB1bi4uLjwvYT4NCgkJPC9kaXY%2BPC90ZD4NCgk8L3RyPjx0cj4NCgkJPHRkIGNsYXNzPSJMMk1vc3RSZWFkTGFzdFdlZWsiPjxkaXY%2BDQoJCQk8YSBjbGFzcz0iQjJNb3N0UmVhZExhc3RXZWVrIiBocmVmPSJodHRwOi8vd3d3Lm1vcm5pbmdzdGFyLmVzL2VzL25ld3MvMTIwOTExL3ByZW1pb3MtbW9ybmluZ3N0YXItMjAxNC0tLWxv&__VIEWSTATE5=cy1tZWpvcmVzLXBsYW5lcy1kZS1wZW5zaW9uZXMuYXNweD9yZWZzb3VyY2U9bW9zdHJlYWQiPuKAoiBQcmVtaW9zIE1vcm5pbmdzdGFyIDIwMTQgLSBMb3MuLi48L2E%2BDQoJCTwvZGl2PjwvdGQ%2BDQoJPC90cj48dHI%2BDQoJCTx0ZCBjbGFzcz0iTDJNb3N0UmVhZExhc3RXZWVrIj48ZGl2Pg0KCQkJPGEgY2xhc3M9IkIyTW9zdFJlYWRMYXN0V2VlazEiIGhyZWY9Imh0dHA6Ly93d3cubW9ybmluZ3N0YXIuZXMvZXMvbmV3cy8xMjIzOTcvcmF5b3MteC12YWxvcmVzLXF1ZS1lbnRyYW4teS1zYWxlbi1kZS1sb3MtbWVqb3Jlcy1mb25kb3MtZGUtcnYtZXNwYSVjMyViMWEuYXNweD9yZWZzb3VyY2U9bW9zdHJlYWQiPuKAoiBSYXlvcyBYOiBWYWxvcmVzIHF1ZSBlbnRyYW4geSBzYWxlbiBkZSBsb3MgbWVqb3Jlcy4uLjwvYT4NCgkJPC9kaXY%2BPC90ZD4NCgk8L3RyPjx0cj4NCgkJPHRkIGNsYXNzPSJMMk1vc3RSZWFkTGFzdFdlZWsiPjxkaXY%2BDQoJCQk8YSBjbGFzcz0iQjJNb3N0UmVhZExhc3RXZWVrMSIgaHJlZj0iaHR0cDovL3d3dy5tb3JuaW5nc3Rhci5lcy9lcy9uZXdzLzEyMjQ3MC9jJWMzJWIzbW8tY29uc3RydWlyLWxhLWNhcnRlcmEtaWRlYWwuYXNweD9yZWZzb3VyY2U9bW9zdHJlYWQiPuKAoiBDw7NtbyBjb25zdHJ1aXIgbGEgY2FydGVyYSBpZGVhbDwvYT4NCgkJPC9kaXY%2BPC90ZD4NCgk8L3RyPjx0cj4NCgkJPHRkIGNsYXNzPSJMMk1vc3RSZWFkTGFzdFdlZWsiPjxkaXY%2BDQoJCQk8YSBjbGFzcz0iQjJNb3N0UmVhZExhc3RXZWVrMSIgaHJlZj0iaHR0cDovL3d3dy5tb3JuaW5nc3Rhci5lcy9lcy9uZXdzLzEyMjQ3NS9jaW5jby1oJWMzJWExYml0b3MtZGUtbG9zLWludmVyc29yZXMtZGUtJWMzJWE5eGl0by5hc3B4P3JlZnNvdXJjZT1tb3N0cmVhZCI%2B4oCiIENpbmNvIGjDoWJpdG9zIGRlIGxvcyBpbnZlcnNvcmVzIGRlIMOpeGl0bzwvYT4NCgkJPC9kaXY%2BPC90ZD4NCgk8L3RyPjx0cj4NCgkJPHRkIGNsYXNzPSJMMk1vc3RSZWFkTGFzdFdlZWsiPjxkaXY%2BDQoJCQk8YSBjbGFzcz0iQjJNb3N0UmVhZExhc3RXZWVrMSIgaHJlZj0iaHR0cDovL3d3dy5tb3JuaW5nc3Rhci5lcy9lcy9uZXdzLzEyMjUwOS90b3AtMTAtYWNjaW9uZXMtZmVicmVyby5hc3B4P3JlZnNvdXJjZT1tb3N0cmVhZCI%2B4oCiIFRvcCAxMCBBY2Npb25lczogRmVicmVybzwvYT4NCgkJPC9kaXY%2BPC90ZD4NCgk8L3RyPjx0cj4NCgkJPHRkIGNsYXNzPSJMMk1vc3RSZWFkTGFzdFdlZWsiPjxkaXY%2BDQoJCQk8YSBjbGFzcz0iQjJNb3N0UmVhZExhc3RXZWVrMSIgaHJlZj0iaHR0cDovL3d3dy5tb3JuaW5nc3Rhci5lcy9lcy9uZXdzLzEyMjU0MC9jciVjMyViM25pY2EtZGVsLWl2LWZvcm8tZGUtZmluYW56YXMtcGVyc29uYWxlcy1lbi1mb3JpbnZlc3QtMjAxNC5hc3B4P3JlZnNvdXJjZT1tb3N0cmVhZCI%2B4oCiIENyw7NuaWNhIGRlbCBJViBGb3JvIGRlIEZpbmFuemFzIFBlcnNvbmFsZXMgZW4uLi48L2E%2BDQoJCTwvZGl2PjwvdGQ%2BDQoJPC90cj48dHI%2BDQoJCTx0ZCBj&__VIEWSTATE6=bGFzcz0iTDJNb3N0UmVhZExhc3RXZWVrIj48ZGl2Pg0KCQkJPGEgY2xhc3M9IkIyTW9zdFJlYWRMYXN0V2VlazEiIGhyZWY9Imh0dHA6Ly93d3cubW9ybmluZ3N0YXIuZXMvZXMvbmV3cy8xMjI1NDIvcHJvYmxlbWFzLWNvbi1sYXMtY2FydGVyYXMtZW4tbW9ybmluZ3N0YXJlcy5hc3B4P3JlZnNvdXJjZT1tb3N0cmVhZCI%2B4oCiIFByb2JsZW1hcyBjb24gbGFzIGNhcnRlcmFzIGVuIE1vcm5pbmdzdGFyLmVzPC9hPg0KCQk8L2Rpdj48L3RkPg0KCTwvdHI%2BDQo8L3RhYmxlPmQCAg8WAh4EaHJlZgUVL2VzL25ld3MvYXJjaGl2ZS5hc3B4ZBgCBR5fX0NvbnRyb2xzUmVxdWlyZVBvc3RCYWNrS2V5X18WFAU%2FY3RsMDAkY3RsMDAkTWFpbkNvbnRlbnQkUE1fTWFpbkNvbnRlbnQkR3JpZFZpZXcxJGN0bDAyJGNiRGVsZXRlBT9jdGwwMCRjdGwwMCRNYWluQ29udGVudCRQTV9NYWluQ29udGVudCRHcmlkVmlldzEkY3RsMDMkY2JEZWxldGUFP2N0bDAwJGN0bDAwJE1haW5Db250ZW50JFBNX01haW5Db250ZW50JEdyaWRWaWV3MSRjdGwwNCRjYkRlbGV0ZQU%2FY3RsMDAkY3RsMDAkTWFpbkNvbnRlbnQkUE1fTWFpbkNvbnRlbnQkR3JpZFZpZXcxJGN0bDA1JGNiRGVsZXRlBT9jdGwwMCRjdGwwMCRNYWluQ29udGVudCRQTV9NYWluQ29udGVudCRHcmlkVmlldzEkY3RsMDYkY2JEZWxldGUFP2N0bDAwJGN0bDAwJE1haW5Db250ZW50JFBNX01haW5Db250ZW50JEdyaWRWaWV3MSRjdGwwNyRjYkRlbGV0ZQU%2FY3RsMDAkY3RsMDAkTWFpbkNvbnRlbnQkUE1fTWFpbkNvbnRlbnQkR3JpZFZpZXcxJGN0bDA4JGNiRGVsZXRlBT9jdGwwMCRjdGwwMCRNYWluQ29udGVudCRQTV9NYWluQ29udGVudCRHcmlkVmlldzEkY3RsMDkkY2JEZWxldGUFP2N0bDAwJGN0bDAwJE1haW5Db250ZW50JFBNX01haW5Db250ZW50JEdyaWRWaWV3MSRjdGwxMCRjYkRlbGV0ZQU%2FY3RsMDAkY3RsMDAkTWFpbkNvbnRlbnQkUE1fTWFpbkNvbnRlbnQkR3JpZFZpZXcxJGN0bDExJGNiRGVsZXRlBT9jdGwwMCRjdGwwMCRNYWluQ29udGVudCRQTV9NYWluQ29udGVudCRHcmlkVmlldzEkY3RsMTIkY2JEZWxldGUFP2N0bDAwJGN0bDAwJE1haW5Db250ZW50JFBNX01haW5Db250ZW50JEdyaWRWaWV3MSRjdGwxMyRjYkRlbGV0ZQU%2FY3RsMDAkY3RsMDAkTWFpbkNvbnRlbnQkUE1fTWFpbkNvbnRlbnQkR3JpZFZpZXcxJGN0bDE0JGNiRGVsZXRlBT9jdGwwMCRjdGwwMCRNYWluQ29udGVudCRQTV9NYWluQ29udGVudCRHcmlkVmlldzEkY3RsMTUkY2JEZWxldGUFP2N0bDAwJGN0bDAwJE1haW5Db250ZW50JFBNX01haW5Db250ZW50JEdyaWRWaWV3MSRjdGwxNiRjYkRlbGV0ZQU%2FY3RsMDAkY3RsMDAkTWFpbkNvbnRlbnQkUE1fTWFpbkNvbnRlbnQkR3JpZFZpZXcxJGN0bDE3JGNiRGVsZXRlBT9jdGwwMCRjdGwwMCRNYWluQ29udGVudCRQTV9NYWluQ29udGVudCRHcmlkVmlldzEkY3RsMTgkY2JEZWxldGUFP2N0bDAwJGN0bDAwJE1haW5Db250ZW50JFBNX01haW5Db250ZW50JEdyaWRWaWV3MSRjdGwx&__VIEWSTATE7=OSRjYkRlbGV0ZQU%2FY3RsMDAkY3RsMDAkTWFpbkNvbnRlbnQkUE1fTWFpbkNvbnRlbnQkR3JpZFZpZXcxJGN0bDIwJGNiRGVsZXRlBT9jdGwwMCRjdGwwMCRNYWluQ29udGVudCRQTV9NYWluQ29udGVudCRHcmlkVmlldzEkY3RsMjEkY2JEZWxldGUFMGN0bDAwJGN0bDAwJE1haW5Db250ZW50JFBNX01haW5Db250ZW50JEdyaWRWaWV3MQ88KwAKAQgCAWQ%3D&ddToolsTitleBar=&ctl00%24ctl00%24MainContent%24PM_MainContent%24PortfolioBarPanel%24PortfoliosDropDownList=2190582&ctl00%24ctl00%24MainContent%24PM_MainContent%24PortfolioBarPanel%24SelectedIndex=&ctl00%24ctl00%24MainContent%24PM_MainContent%24pageSizeDropDownList=100&ctl00%24ctl00%24MainContent%24PM_MainContent%24ddlHolding=" "http://www.morningstar.es/es/portfoliomanager/edittransaction.aspx?Portfolio_ID=$PORTFOLIO_ID"
  if [ $? -ne 0 ]; then
    echo "Error al descargar la pagina $pagina de los movimientos de http://www.morningstar.es/es/portfoliomanager/edittransaction.aspx?Portfolio_ID=$PORTFOLIO_ID, abortando"
    exit $?
  else
    # Comprobamos que el login sea correcto
    comprobarLogin "$CARPETA_OUT/mstar_movimientos_$sufijo.html.tmp"
  fi
else
  # Hacemos una copia del fichero que nos han pasado como si lo hubiesemos descargado
  cp $FICHERO_HTML_MOVIMIENTOS $CARPETA_OUT/mstar_movimientos_$sufijo.html.tmp
fi

# Leemos el fichero descargado y lo convertimos en un fichero csv
# Elimina las lineas anteriores a "transactionsGridPanel"
# Elimina las posteriores a /table
# Elimina las que no tengan value
# Elimina las que tengan option value (combos no seleccionados)
# Elimina las que tienen "hidden" (campos ocultos)
# Cambia selected value="1" por selected value="+" (compra)
# Cambia selected value="2" por selected value="-" (venta)
#
# Elimina todos los ; para que no estropeen el CSV, cambiando &amp; por &
#
# Junta cada uno de los campos, que estan en filas separadas, hasta formar una unica fila
cat $CARPETA_OUT/mstar_movimientos_$sufijo.html.tmp | \
sed -e '1,/div class=\"transactionsGridPanel/d' -e '/\/table/,$ d' -e '/value/ !d' -e '/option value/ d' -e '/hidden/ d' -e 's/selected" value="1"/selected value="+"/' -e 's/selected" value="2"/selected value="-"/' -e 's/.*value="\([^"]*\)".*/\1/' -e 's/.*transactionvalue_label">\([^<]*\).*/\1/' -e '/</ d' | \
sed -e 's/\&amp\;/\&/g' -e 's/\;//g' | \
sed -e 'N;s/\n/\;/' -e 'N;s/\n//'  -e 'N;s/\n/\;/'  -e 'N;s/\n/\;/' -e 'N;s/\n/\;/' -e 'N;s/\n/\;/' -e 'N;s/\n/\;/' >> $CARPETA_OUT/mstar_movimientos_$sufijo.csv.tmp

# Juntamos el tmp con el csv, eliminamos lineas duplicadas y ordenamos por fecha y nombre
if [[ "$ELIMINAR_DUPLICADOS" = true ]]; then
  cat $CARPETA_OUT/mstar_movimientos_$sufijo.csv $CARPETA_OUT/mstar_movimientos_$sufijo.csv.tmp | \
  awk '!x[$0]++' | \
  sort -t\; -k3.7,3.10nr -k3.5,3.6nr -k3.1,3.2nr -k1,1 -o $CARPETA_OUT/mstar_movimientos_$sufijo.csv
else
  cat $CARPETA_OUT/mstar_movimientos_$sufijo.csv $CARPETA_OUT/mstar_movimientos_$sufijo.csv.tmp | \
  sort -t\; -k3.7,3.10nr -k3.5,3.6nr -k3.1,3.2nr -k1,1 -o $CARPETA_OUT/mstar_movimientos_$sufijo.csv 
fi

# Borramos los ficheros temporales generados
rm $CARPETA_OUT/mstar_movimientos_$sufijo.csv.tmp
rm $CARPETA_OUT/mstar_movimientos_$sufijo.html.tmp

mensaje "Proceso finalizado correctamente"
exit 0
