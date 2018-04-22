#!/bin/bash

# Si solo tiene un argumento o menos
if [ $# -le 1 ] ; then
	echo "usage ./mascara ip(A.B.C.D) mascara(E.F.G.H)"
	exit 1
fi

IP=$1
MASK=$2

IP_SEPARADA=($(echo $IP | tr "." " "))
MASK_SEPARADA=($(echo $MASK | tr "." " "))

# En memoria de nuestra inutilidad: 21.3.2018
#
#echo IP_SEPARADA ${IP_SEPARADA[@]}
#echo "IP_SEPARADA: ${IP_SEPARADA[0]}"
#echo "IP_SEPARADA: ${IP_SEPARADA[1]}"
#echo "IP_SEPARADA: ${IP_SEPARADA[2]}"
#echo "IP_SEPARADA: ${IP_SEPARADA[3]}"

# Posibles mascaras de red validas
POSIBLES_MASCARAS=(0 128 192 224 240 248 252 254 255)

FIN_MASCARA=false

# Realizaremos 4 vueltas, una por cada byte
typeset -i i=0
while [ $i -lt 4 ]
do
	#Comprobamos que los bytes de la IP no son superiores a 255.
	if [ ${IP_SEPARADA[i]} -gt 255 ] && [ ${IP_SEPARADA[i]} -lt 0 ] ; then
		echo "No puede poner una direccion con un byte mayor que 255. ($(expr $i + 1)º byte)"
		exit 2
	fi

	M=${MASK_SEPARADA[i]}

	#Comprobamos que la mascara solo tiene los valores adecuados	
	if [ $M -eq 0 ] ||
		[ $M -eq 128 ] ||
	       	[ $M -eq 192 ] ||
	        [ $M -eq 224 ] ||
		[ $M -eq 240 ] ||
		[ $M -eq 248 ] ||
		[ $M -eq 252 ] ||
		[ $M -eq 254 ] ||
		[ $M -eq 255 ] 	; then
		#Si coincide con alguno, comprobamos que si es diferente de 255
		#por lo que tendriamos que comprobar si finaliza
		if [ $M -ne 255 ] ; then
			#Si ya se indicó que los 1s han finalizado pero el
			#byte es diferente de 0, salta un error.
			if $FIN_MASCARA ; then
				if [ $M -ne 0 ] ; then
					echo "Mascara no valida: No puede tener 1s intercalados entre 0s."
					exit 4
				fi
				# Si es 0, no pasaria nada
			else
				# Ya no se permiten mas 1s a partir de ahora.
				FIN_MASCARA=true
			fi
		fi
	else
		#Si no se encuentra entre esos valores, no es una mascara valida.
		echo "No existe una mascara con un byte a $M ($(expr $i + 1)º byte)"
		exit 3
	fi

	# Calculamos el byte de red:
	# Si es todo 1, se mantiene la de la IP.
	if [ $M == 255 ] ; then
		DIRECCION[i]=${IP_SEPARADA[i]}
	else
		# Si es todo 0, se pone a 0.
		if [ $M == 0 ] ; then
			DIRECCION[i]=0
		else
			# Sino, calculamos el byte
			DIF=$(expr 256 - $M)
			COC=$(expr ${IP_SEPARADA[i]} / $DIF)
			DIRECCION[i]=$(expr $COC \* $DIF)

			# Ejemplo de calculo. Si el byte es 150 y la mascara es 192:
			#      
			# 192: 11000000 --> /26 (solo nos importan 2 los dos bits de delante)
			# 150: 10010110 --> 10XXXXXX
			# 
			# Comprobamos que cantidad (DIF) significa cada bit. En este caso 256 - 192 = 64.
			# Cada bit de los que nos importan valdra 64.
			# 
			# Observamos cual es el numero en binario es 150 de los bits que nos importan:
			# 192(10) --> 10(2) --> 2(10)  ==  Numero(Base)
			# Por tanto, 2 es el cociente (Es igual que calcular 150 / 64 = 2)
			#
			# Pero como la cuenta comienza por 64, ese cociente hay que multiplicarlo por la diferencia.
			#     11000000
			# AND 10XXXXXX
			#     --------
			#     10000000(2) = 128(10), esto es igual a (COC * DIF) = 64 * 2 = 128
			# Asi, el byte de la mascara es 128.
		fi
	fi
	# Aumentamos el bucle
	let "i=i + 1"
done

# Finalmente mostramos la direccion calculada (transformando el array por una direccion de red poniendo ".")
echo -n "Net Address : "
echo $(echo ${DIRECCION[@]} | tr " " ".")

exit 0
