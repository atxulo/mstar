#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para generar uno o varios ficheros CSV a partir de una cartera de la pagina Morningstar.es
AHORA=$(date +"%Y%m%d_%H%M%S_%N")

# Parametros que se leen de la linea de comandos con sus valores por defecto
CARPETA_BACKUP=
FICHERO_COOKIES="cookies.txt"
CARPETA_OUT="out"
MSTAR_PASS=
CARTERA_RAPIDA=false
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
	if [[ "$VERBOSE" = true ]]; then echo $1; fi
}

# Funcion para explicar como los parametros
usage() {
cat << EOF

USO: $0 opciones portfolio_id

OPCIONES:
   -b [ruta]       Path de la carpeta donde dejar una copia de seguridad de los ficheros. Si no se indica, no se hace copia.
   -c [fichero]    Path del fichero con la cookie de morningstar.es. Por defecto $FICHERO_COOKIES
   -h              Muestra este mensaje de ayuda y finaliza
   -o [ruta]       Path de la carpeta donde dejar los ficheros resultado. Si no existe, la intenta crear
   -p password     Password de morningstar, para generar el fichero de cookies (opcional)
   -r              Indica que la cartera MStar es de tipo rapida. Si no se indica, se supone transaccional
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
while getopts "b:c:ho:p:ru:v" opt; do
  case $opt in
    b)
      CARPETA_BACKUP=$OPTARG
	  ;;
    c)
      FICHERO_COOKIES=$OPTARG
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
    r)
      CARTERA_RAPIDA=true
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
	if [grep -q "_loginError" "$CARPETA_OUT/mstar_login.html.tmp"]; then
      rm "$CARPETA_OUT/mstar_login.html.tmp"
      mensaje "Error al generar el fichero de cookies; revisa el usuario y password"
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
if [ ! -f $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat ]; then
  > $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat
  mensaje "Creado fichero $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat"
else
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat"
  fi
fi

if [ ! -f $CARPETA_OUT/mstar_isin_$PORTFOLIO_ID.dat ]; then
  echo "# ID_MSTAR = ISIN" > $CARPETA_OUT/mstar_isin_$PORTFOLIO_ID.dat
  mensaje "Creado fichero $CARPETA_OUT/mstar_isin_$PORTFOLIO_ID.dat"
else
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_isin_$PORTFOLIO_ID.dat"
  fi
fi

# Nos conectamos a la pagina para extraer los datos de la cartera
wget --load-cookies $FICHERO_COOKIES --output-document=$CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm "http://www.morningstar.es/es/portfoliomanager/portfolio.aspx?Portfolio_ID=$PORTFOLIO_ID"
if [ $? -ne 0 ]; then
  echo "Error al descargar el portfolio de http://www.morningstar.es/es/portfoliomanager/portfolio.aspx?Portfolio_ID=$PORTFOLIO_ID, abortando"
  exit $?
fi
# Usado para pruebas sin conexion https a Mstar
#if [[ "$CARTERA_RAPIDA" = true ]]; then 
#  cp cartera_rapida.html $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm
#else
#  cp cartera_transaccional.html $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm
#fi

# Leemos el fichero descargado y lo convertimos en un fichero con este formato: "ID;Nombre;AAAAMMDD;Fecha;VL;MONEDA"
if [[ "$CARTERA_RAPIDA" = true ]]; then 
  cat $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm | gawk 'match( $0, /snapshot\.aspx\?id=([A-Za-z0-9]*)">([^<]*).*title="([^"/]*)\/([^/]*)\/([^"]*)[^>]*>([^<]*)<.*msDataText[^>]*>([^<]*)/, grupos) { print grupos[1] ";" grupos[2] ";" grupos[5] grupos[4] grupos[3] ";" grupos[3] "/" grupos[4] "/" grupos[5] ";" grupos[6] ";" grupos[7]}' > $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp  
else
  cat $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm | gawk 'match( $0, /snapshot\.aspx\?id=([A-Za-z0-9]*)">([^<]*).*title="([^"/]*)\/([^/]*)\/([^"]*)[^>]*>([^<]*)/, grupos) { print grupos[1] ";" grupos[2] ";" grupos[5] grupos[4] grupos[3] ";" grupos[3] "/" grupos[4] "/" grupos[5] ";" grupos[6] ";EUR"}' > $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp 
fi

# Leemos el fichero temporal descargado
while read linea_dat_tmp; do
	mstar_id=${linea_dat_tmp%%;*}
	
	# Leemos el ISIN del fichero o de MStar si no lo tenemos
	isin_dat=$(grep "$mstar_id=" "$CARPETA_OUT/mstar_isin_$PORTFOLIO_ID.dat")
	if [ $? -eq 0 ]; then
		# Nos quedamos con la parte derecha de la linea del fichero de configuracion
		isin=${isin_dat#*=} 
		if [ -z "$isin" ]; then
          echo "Error al obtener el ISIN '$isin' del fichero '$CARPETA_OUT/mstar_isin_$PORTFOLIO_ID.dat', abortando" 1>&2
		  exit 1
		fi
	else
		isin=$(wget -O- http://www.morningstar.es/es/funds/snapshot/snapshot.aspx?id=$mstar_id | sed -n -e 's/.*heading\">ISIN<\/td>.*text">\([^<]*\).*Patrimonio (.*/\1/p')
		if [ ! $? -eq 0 ] || [ -z "$isin" ]; then
		  echo "Error al obtener el ISIN '$isin' de 'http://www.morningstar.es/es/funds/snapshot/snapshot.aspx?id=$mstar_id', abortando" 1>&2
          exit 1
		fi
		echo "$mstar_id=$isin" >> $CARPETA_OUT/mstar_isin_$PORTFOLIO_ID.dat
	fi
	
	# Miramos la moneda del VL (nos quedamos con lo que esta a la derecha del ultimo ;)
    moneda=${linea_dat_tmp##*\;}
	# Quitamos la moneda y obtenemos el ultimo valor, el VL en esa Moneda
	linea_dat_tmp=${linea_dat_tmp%\;*}
	vlMoneda=${linea_dat_tmp##*\;}
	# Quitamos el punto de separador de miles, y cambiamos la coma decimal por punto
	vlMonedaPunto=${vlMoneda//./}
    vlMonedaPunto=${vlMonedaPunto//,/.}
	# Quitamos el VL y obtenemos la fecha, y cambiamos las / por -
	linea_dat_tmp=${linea_dat_tmp%\;*}
	fechaVL=${linea_dat_tmp##*\;}
	fechaVLGuion=${fechaVL//\//-}
	
	if [[ "$moneda" = "EUR" ]]; then 
      # Como ya esta en euros, el cambio es 1
	  cambioVL="1"
	elif [[ "$moneda" = "USD" ]]; then
	  # Descargamos el cambio euro-dolar del dia del vl
	  wget --output-document=$CARPETA_OUT/mstar_euro_dolar.htm.tmp "http://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.USD.EUR.SP00.A&start=${fechaVLGuion}&end=${fechaVLGuion}&ubmitOptions.x=55&submitOptions.y=4&trans=N"
      if [ $? -ne 0 ]; then
        echo "Error al descargar la informacion de 'http://sdw.ecb.europa.eu/quickview.do?SERIES_KEY=120.EXR.D.USD.EUR.SP00.A&start=${fechaVLGuion}$end=${fechaVLGuion}&ubmitOptions.x=55&submitOptions.y=4&trans=N', abortando"
		rm $CARPETA_OUT/mstar_euro_dolar.htm.tmp
        exit $?
      fi
	  # Leemos el fichero descargado y lo obtenemos el valor
      # Elimina las lineas anteriores a "tablestats"
      # Elimina las posteriores a /table
      # Elimina las que no tengan 8%
      # Extrae el valor (#.####)
      # Elimina las lineas que no han podido ser formateada y aun tienen el 8%
	  cambioVL=$(cat $CARPETA_OUT/mstar_euro_dolar.htm.tmp | sed -e '1,/table class=\"tablestats\">/d' -e '/\/table/,$ d' -e '/8%/ !d' -e 's/.*8%[^>]*>[0-9]*-[0-9]*-[0-9]*<\/td\>.*right\;\">\([0-9]*\)\.\([0-9]*\).*/\1.\2/' -e '/8%/ d')
	  rm $CARPETA_OUT/mstar_euro_dolar.htm.tmp
	else
      # No sabemos que moneda es
	  cambioVL="ERROR"
	fi
	
    # Hacemos el cambio y escribimos de nuevo los campos
	if [[ "$cambioVL" = "ERROR" ]]; then 
      vlEurosComa=0
	  cambioVLComa=0
	else
      vlEuros=$(gawk "BEGIN {printf  \"%f\",($vlMonedaPunto/$cambioVL)}")
	  vlEurosComa=${vlEuros//./,}
	  cambioVLComa=${cambioVL//./,}
	fi
	
    linea_dat_tmp=${linea_dat_tmp}";$vlMoneda;$moneda;$cambioVLComa;$vlEurosComa"
	echo ${linea_dat_tmp//$mstar_id/$isin} 
	
	# Guardamos la linea modificada en el fichero
done <$CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp > $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp.2; mv $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp{.2,}

# Juntamos el fichero temporal con el dat, ordenando alfabeticamente (asc) y por fecha (desc)
cat $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp | sort -u -t\; -k3,3r -k2,2 -o $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat

# Si ya existe el CSV, hacemos el backup si asi se ha indicado 
if [[ -f "${CARPETA_OUT}/mstar_portfolio_$PORTFOLIO_ID.csv" ]]; then
  if [ ! -z "$CARPETA_BACKUP" ]; then
    backupFichero "$CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.csv"
  fi
fi

# Copiamos el fichero dat como csv y eliminamos el nombre y fechas AAAAMMDD que solo necesitabamos para ordenar
cut -d\; -f1,4- $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat > $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.csv

# Borramos los ficheros temporales generados
rm $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.htm
rm $CARPETA_OUT/mstar_portfolio_$PORTFOLIO_ID.dat.tmp

exit 0
