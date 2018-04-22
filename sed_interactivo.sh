#!/bin/bash

# Necesita: $1 Archivo


# Comprobamos los argumentos

if [ $# -lt 1 ] ; then
       echo "usage: $0 ARCHIVO"
       exit 1
fi

# Comprobamos si el archivo existe

if [ ! -f $1 ] ; then
	echo "$1 no es un archivo valido."
	exit 1
fi

# Obtenemos la direccion

echo "Direcciones (numero, \$, dejar en blanco para salir):"

read DIR

if [ "$DIR" != "" ] ; then
	if [ "$DIR" = "\$" ] ; then
		DIR=$(wc -l $1 | cut -f1 -d' ')
	fi

	read DIR2

	if [ "$DIR2" = "\$" ] ; then
		DIR2=$(wc -l $1 | cut -f1 -d' ')
	fi
	
	if [ "$DIR" != "$DIR2" ] ; then

		DIR="${DIR},${DIR2}"
	fi
fi


# Obtenemos la accion

read -p "Accion a realizar ('p', 'd', 's', 'y'): " ACC

if [ "$ACC" != "p" ] && [ "$ACC" != "d" ] && [ "$ACC" != "s" ] && [ "$ACC" != "y" ] ; then
	echo "$ACC no es una accion valida."
	exit 1
fi

case $ACC in
	s|y)
		read -p "Patron que sera sustituido: " LISTA_ORIGEN
		read -p "Patros por el que se cambiara: " LISTA_DESTINO
	
		# Si la opcion es "y", debemos cortar la de mayor longitud	

		if [ $ACC = "y" ] ; then
			LON_1=${#LISTA_ORIGEN}
			LON_2=${#LISTA_DESTINO}
			if [ $LON_1 -lt $LON_2 ] ; then
				MIN=$LON_1
				echo " ** ADVERTENCIA: $LISTA_DESTINO ahora es ${LISTA_DESTINO:0:$MIN}"
				LISTA_DESTINO=${LISTA_DESTINO:0:$MIN}
			else
				MIN=$LON_2
				if [ $LON_2 -lt $LON_1 ] ; then
					echo " ** ADVERTENCIA: $LISTA_ORIGEN ahora es ${LISTA_ORIGEN:0:$MIN}"
				fi
				LISTA_ORIGEN=${LISTA_ORIGEN:0:$MIN}
			fi
		fi
		
		ACC="$ACC/\"$LISTA_ORIGEN\"/\"$LISTA_DESTINO\"/"	
		;;
esac

# Preguntamos si queremos que muestre las demas lineas

read -p "¿Mostrar las lineas antes de procesarlas? [Y|y|S|s]: " BARRA_N

case $BARRA_N in
	Y|y|S|s)
		BARRA_N=""
		;;
	*)
		BARRA_N="-n"
		;;
esac

echo -e "=====================================\n\$ sed ${DIR}${ACC} $BARRA_N $1\n====================================="

if sed "${DIR}${ACC}" $BARRA_N "$1" >/dev/null 2>&1 ; then
	sed "${DIR}${ACC}" $BARRA_N "$1"
else
	echo "Ha ocurrido un error al procesar el sed."
	exit 1
fi

exit 0
