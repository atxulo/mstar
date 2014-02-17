#!/bin/bash
#
# Autor: Eneko Gonzalez
#
# Script para generar un fichero CSV con datos inventados, para probar las plantillas con volumen de datos
#
# Por ejemplo, para generar esta cartera de Marcos Luque: http://www.rankia.com/foros/fondos-inversion/temas/2064438-carteras-modelo-perfil-conservador
# con estos fondos:
#
#   Allianz Europe Equity Growth CT EUR - LU0256839860
#   Bantleon Opportunities L PT - LU0337414303
#   Carmignac Portfolio Capital Plus A EUR acc - LU0336084032
#   Cartesio X FI - ES0116567035
#   Cartesio Y FI - ES0182527038
#   Fidelity Funds - Iberia Fund A-Acc-EUR - LU0261948904
#   M&G Optimal Income Fund Euro Class A-H Gross Shares Acc (Hedged) - GB00B1VMCY93
#   Renta 4 Monetario FI - ES0128520006
#   Renta 4 Pegasus FI - ES0173321003
#   Renta 4 Wertefinder FI - ES0173323009
#   Robeco Capital Growth Funds - Robeco US Premium Equities D EUR - LU0434928536
#
# habria que ejecutar: 
#
# mstar_generator LU0256839860 LU0337414303 LU0336084032 ES0116567035 ES0182527038 LU0261948904 GB00B1VMCY93 ES0128520006 ES0173321003 ES0173323009 LU0434928536

# Comprobamos los parametros
if (($# == 0)); then
  echo "ERROR; faltan parametros, debes escribir los ISIN separados por espacios y en orden alfabetico (por nombre de fondo)"
  echo "Ejemplo: $0 isin1 isin2 isin3..."
  exit 1
fi

# Borramos el fichero anterior si existe
if [[ -f "mstar_generator.csv" ]]; then
  rm mstar_generator.csv
fi

# Leemos cada isin 
for isin in "$@"
do
  # Generamos un VL inicial con cierto volumen
  vl=$(($RANDOM%100))
  until [ vl > 40 ]
  do
    vl=$(($RANDOM%100))
  done
  
  nombreFondo=$(wget -O- http://markets.ft.com/research//Tearsheets/PriceHistoryPopup?symbol=$isin | sed -n -e 's/.*name\">\([^<]*\).*/\1/p')
  nombreFondo=${nombreFondo//\&amp\;/\&} # Evitamos problemas con los &amp;
  nombreFondo=${nombreFondo//\;/\_} # Evitamos problemas con los ;
  echo "Generando datos para $isin - $nombreFondo a partir de vl ${vl},00"

  # Fechas entre las que se van a generar los datos (la primera se incluye en los datos, la segunda no)
  fechaInicio=$(date --date "2013-12-31" +%Y-%m-%d)
  fechaFin=$(date --date "2015-01-01" +%Y-%m-%d)
  
  # Simulamos los dias y por cada dia
  until [ "$fechaFin" == "$fechaInicio" ]
  do
    fechaFin=$(date --date "$fechaFin -1 day" +%Y-%m-%d)
	if [[ $(date --date "$fechaFin" +%u) -lt 6 ]]; then # Solo laborables
		# Como la generacion es hacia el pasado, procuramos que los VLs vayan bajando poco a poco
		if [[ $(($RANDOM%50)) -gt 48 ]]; then # Variamos la parte entera 1 de cada 50 veces (0..49 > 48)
			vl=$(($vl-1)) 
		fi;
		if [[ $(($RANDOM%30)) -gt 28 ]]; then # Hacemos un salto 1 de cada 30 veces (0..29 > 28)
			vl=$(($vl+$RANDOM%5-2)) # El salto es de +-2 (0..4 - 2 = -2..2)
		fi;
		decimales=$(($RANDOM%100))
		fechaAAAAMMDD=$(date --date "$fechaFin" +%Y%m%d)
		fechaMMDDAAAA=$(date --date "$fechaFin" +%d/%m/%Y)
		echo "$isin;$nombreFondo;$fechaAAAAMMDD;$fechaMMDDAAAA;$vl,$decimales" >> mstar_generator.csv
	fi
  done  
done

echo "Generado el fichero mstar_generator.csv"
