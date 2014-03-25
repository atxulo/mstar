#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para generar un fichero CSV a partir de una cartera de la pagina Morningstar.es con valores obtenidos del Finantial Times
AHORA=$(date +"%Y%m%d_%H%M%S_%N")

# Parametros que se leen de la linea de comandos con sus valores por defecto
ALIAS=
CARPETA_BACKUP=
FICHERO_COOKIES="cookies.txt"
FECHA_INICIO=00000000
FECHA_FIN=99999999
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

trim() {
    local var=$@
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}

# Funcion para explicar como los parametros
usage() {
cat << EOF

USO: $0 opciones portfolio_id

OPCIONES:
   -a alias        Alias de la cartera. Si se indica, los ficheros generados se llamaran xxx_ALIAS en vez de xxx_ID.
   -b [ruta]       Path de la carpeta donde dejar una copia de seguridad de los ficheros. Si no se indica, no se hace copia.
   -c [fichero]    Path del fichero con la cookie de morningstar.es. Por defecto $FICHERO_COOKIES
   -f AAAAMMDD     Solo extrae los VLs hasta esta fecha (<=)
   -h              Muestra este mensaje de ayuda y finaliza
   -i AAAAMMDD     Solo extrae los VLs a partir de esta fecha (>=)
   -o [ruta]       Path de la carpeta donde dejar los ficheros resultado. Si no existe, la intenta crear
   -p password     Password de morningstar, para generar el fichero de cookies (opcional)
   -u usuario      Usuario de morningstar, para generar el fichero de cookies (opcional)
   -v              Modo verbose para depurar los pasos ejecutados

EJEMPLOS:
  $0 2176038  
      
	  Genera el fichero para la cartera '2176038' en la carpeta '$CARPETA_OUT' usando el fichero de cookies '$FICHERO_COOKIES'
	  
  $0 -o salida 2176038  
      
	  Genera el fichero para la cartera '2176038' en la carpeta 'salida' usando el fichero de cookies '$FICHERO_COOKIES'
	  
  $0 -o salida -c mis_cookies.txt 2176038 
      
	  Genera el fichero para la cartera '2176038' en la carpeta 'salida' usando el fichero de cookies 'mis_cookies.txt'
EOF
}

# Leemos los parametros del script
while getopts "a:b:c:f:hi:o:p:u:v" opt; do
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
    f)
      FECHA_FIN=$OPTARG
	  ;;
    h)
      usage
      exit 1
      ;;
    i)
      FECHA_INICIO=$OPTARG
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

# Creamos los ficheros dat si no existen, y si existen, hacemos backup si asi se ha indicado
if [ ! -f $CARPETA_OUT/mstar_portfolio_$sufijo.dat ]; then
  > $CARPETA_OUT/mstar_portfolio_$sufijo.dat
  mensaje "Creado fichero $CARPETA_OUT/mstar_portfolio_$sufijo.dat"
else
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_portfolio_$sufijo.dat"
  fi
fi

if [ ! -f $CARPETA_OUT/mstar_isin_$sufijo.dat ]; then
  echo "# ID_MSTAR = ISIN" > $CARPETA_OUT/mstar_isin_$sufijo.dat
  mensaje "Creado fichero $CARPETA_OUT/mstar_isin_$sufijo.dat"
else
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_isin_$sufijo.dat"
  fi
fi

# Nos conectamos a la pagina para extraer los datos de la cartera
wget --load-cookies $FICHERO_COOKIES --output-document=$CARPETA_OUT/mstar_portfolio_$sufijo.html.tmp "http://www.morningstar.es/es/portfoliomanager/portfolio.aspx?Portfolio_ID=$PORTFOLIO_ID"
if [ $? -ne 0 ]; then
  echo "Error al descargar el portfolio de http://www.morningstar.es/es/portfoliomanager/portfolio.aspx?Portfolio_ID=$PORTFOLIO_ID, abortando"
  exit $?
else
  # Comprobamos que el login sea correcto
  comprobarLogin "$CARPETA_OUT/mstar_portfolio_$sufijo.html.tmp"
  
  # Comprobamos que el html descargado tiene fondos
  # "portfolio_addHoldingPanel" es la clase de la tabla que contiene los fondos y sus VLs, si no se encuentra es que no hay fondos o el ID no es correcto
  grep "portfolio_addHoldingPanel" "$CARPETA_OUT/mstar_portfolio_$sufijo.html.tmp" > /dev/null
  if [ ! $? -eq 0 ]; then
    rm "$CARPETA_OUT/mstar_portfolio_$sufijo.html.tmp"
    echo "Error al obtener los fondos de la pagina de morningstar.es (comprueba que el ID de portfolio es correcto y que tiene fondos), abortando." 1>&2
    exit 1
  fi
fi

# Leemos el fichero descargado y lo convertimos en un fichero con este formato: "ID;Nombre;AAAAMMDD;Fecha;VL;MONEDA"
cat $CARPETA_OUT/mstar_portfolio_$sufijo.html.tmp | gawk 'match( $0, /snapshot\.aspx\?id=([A-Za-z0-9]*)">([^<]*).*title="([^"/]*)\/([^/]*)\/([^"]*)[^>]*>([^<]*)/, grupos) { print grupos[1] ";" grupos[2] ";" grupos[5] grupos[4] grupos[3] ";" grupos[3] "/" grupos[4] "/" grupos[5] ";" grupos[6] ";EUR"}' > $CARPETA_OUT/mstar_portfolio_$sufijo.dat.tmp 

# Calculamos fechas auxiliares que se usan en el procesado
hoy=$(date +"%Y%m%d")
pasadoAnyo=$(date -d "-1 year" +"%Y")

# Leemos el fichero temporal descargado
while read linea_dat_tmp; do
	mstar_id=${linea_dat_tmp%%;*}  # Elimina el mayor ;* por el final
	nombre=${linea_dat_tmp#*;}     # Elimina el menor *; por el principio
	nombre=${nombre%%;*}           # Elimina el mayor ;* por el final

	# Leemos el ISIN del fichero o de MStar si no lo tenemos
	isin_dat=$(grep "$mstar_id=" "$CARPETA_OUT/mstar_isin_$sufijo.dat")
	if [ $? -eq 0 ]; then
		# Nos quedamos con la parte derecha de la linea del fichero de configuracion
		isin=${isin_dat#*=} 
		if [ -z "$isin" ]; then
          echo "Error al obtener el ISIN '$isin' del fichero '$CARPETA_OUT/mstar_isin_$sufijo.dat', abortando" 1>&2
		  exit 1
		fi

	else
		wget --output-document=$CARPETA_OUT/mstar_$mstar_id.html.tmp "http://www.morningstar.es/es/funds/snapshot/snapshot.aspx?id=$mstar_id"
		
		# Comprobamos si el fichero contiene el texto ISIN (es un fondo) o DGS (es un plan de pensiones)
		isin=$(cat "$CARPETA_OUT/mstar_$mstar_id.html.tmp" | sed -n -e 's/.*heading\">ISIN<\/td>.*text">\([^<]*\).*Patrimonio (.*/\1/p')
		if [ ! -z "$isin" ]; then
		  mensaje "Obtenido isin $isin para id $mstar_id"
		else
          isin=$(cat "$CARPETA_OUT/mstar_$mstar_id.html.tmp" | sed -n -e 's/.*DGS<\/div><div class=\"value_div text\">\([^<]*\)<\/div>.*/\1/p')
          if [ ! -z "$isin" ]; then
		    mensaje "Obtenido dgs $isin para id $mstar_id"
	      fi
		fi
		
		if [ -z "$isin" ]; then
		  echo "Error al obtener el ISIN o DGS para el fondo '$mstar_id' de la pagina de morningstar, abortando" 1>&2
		  rm "$CARPETA_OUT/mstar_$mstar_id.html.tmp"
          exit 1
        fi

		rm "$CARPETA_OUT/mstar_$mstar_id.html.tmp"
		# Escribimos el ISIN/DGS en el fichero
		echo "$mstar_id=$isin" >> $CARPETA_OUT/mstar_isin_$sufijo.dat
	fi
	
	# Descargamos los VLs de Finantial Times
	wget --load-cookies $FICHERO_COOKIES --output-document=$CARPETA_OUT/mstar_ftimes_$isin.html.tmp "http://markets.ft.com/research/Tearsheets/PriceHistoryPopup?symbol=$isin"
	
	# Convertimos lo descargado en un CSV con este formato DiaSemana;Mes y Dia;VL;Cambio;%Cambio
	# Elimina las lineas que no tienen tableContainer
	# Elimina lo anterior a <tbody>
	# Elimina lo posterior a </tbody>
	# Elimina los <tr>
	# Elimina los <td>
	# Sustituye los </td> por ;
	# Sustituye los </tr> por saltos de linea
	cat $CARPETA_OUT/mstar_ftimes_$isin.html.tmp | \
	sed -e '/tableContainer/!d' -e 's/.*<tbody>//' -e 's/<\/tbody>.*//' -e 's/<tr>//g' -e 's/<td[^>]*>//g' -e 's/<\/td>/\;/g' -e 's/<\/tr>/\n/g' > $CARPETA_OUT/mstar_ftimes_$isin.csv.tmp

	# Leemos cada linea del CSV
    while read linea_csv_tmp; do
	
      linea_csv_tmp=$(trim "$linea_csv_tmp")
	
      # Extraemos la fecha y el VL	
      fecha=$(echo $linea_csv_tmp | cut -d\; -f1,2 | sed -e 's/\;/ /g')
      valor=$(echo ${linea_csv_tmp//./,} | cut -d\; -f3)  # Reemplazamos el . por la ,
      
	  # Si no hay valor, ignoramos la linea
	  if [ ! -z "$valor" ]; then
	    # Convertimos la fecha al formato que necesitamos
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
        
	    # Solo escribimos los movimientos cuyas fechas estan en el rango y que no esten ya en el dat
        if [ $fechaConAnyoAMD -ge $FECHA_INICIO ] && [ $fechaConAnyoAMD -le $FECHA_FIN ]; then 
          grep "$isin;.*;fechaConAnyoAMD" "$CARPETA_OUT/mstar_portfolio_$sufijo.dat" > /dev/null
		  if [ ! $? -eq 0 ]; then
		    echo "$isin;$nombre;$fechaConAnyoAMD;$fechaConAnyo;$valor;EUR;1;$valor"
		  fi
        fi
	  fi
	  
    done <$CARPETA_OUT/mstar_ftimes_$isin.csv.tmp
	
    # Borramos los ficheros temporales
	rm $CARPETA_OUT/mstar_ftimes_$isin.html.tmp
	rm $CARPETA_OUT/mstar_ftimes_$isin.csv.tmp
	
	# Guardamos la linea modificada en el fichero
done <$CARPETA_OUT/mstar_portfolio_$sufijo.dat.tmp > $CARPETA_OUT/mstar_portfolio_$sufijo.dat.tmp.2; mv $CARPETA_OUT/mstar_portfolio_$sufijo.dat.tmp{.2,}

# Juntamos el fichero temporal con el dat, ordenando alfabeticamente (asc) y por fecha (desc)	
cat $CARPETA_OUT/mstar_portfolio_$sufijo.dat $CARPETA_OUT/mstar_portfolio_$sufijo.dat.tmp | sort -u -t\; -k3,3r -k2,2 -o $CARPETA_OUT/mstar_portfolio_$sufijo.dat

# Si ya existe el CSV, hacemos el backup si asi se ha indicado 
if [[ -f "${CARPETA_OUT}/mstar_portfolio_$sufijo.csv" ]]; then
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_portfolio_$sufijo.csv"
  fi
fi

# Copiamos el fichero dat como csv y eliminamos el nombre y fechas AAAAMMDD que solo necesitabamos para ordenar
cut -d\; -f1,4- $CARPETA_OUT/mstar_portfolio_$sufijo.dat > $CARPETA_OUT/mstar_portfolio_$sufijo.csv

# Borramos los ficheros temporales generados
rm $CARPETA_OUT/mstar_portfolio_$sufijo.html.tmp
rm $CARPETA_OUT/mstar_portfolio_$sufijo.dat.tmp

mensaje "Proceso finalizado correctamente"
exit 0
