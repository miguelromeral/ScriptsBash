#!/bin/bash

PIDS=($*)

if [ -z $PIDS ] ; then
	echo "usage: $0 PID(S)"
	exit 1
else
	PIDS_ERRORES=()
	SALIDA=$(ps aux)
	CABECERA=$(echo "$SALIDA" | head -n 1)
	PIDS_BIEN=()
	until [ -z $1 ]
	do
		PID=$1
		if echo "$SALIDA" | awk '{print $2}' | grep -E "\\<$PID\\>" >/dev/null ; then
			LINEA=$(echo "$SALIDA" | awk '{print $2}' | grep -n -E "\\<$PID\\>" | cut -f1 -d:)
			NUEVA=$(echo "$SALIDA" | sed -n ${LINEA}p)
			PIDS_BIEN=("${PIDS_BIEN[@]}" "$NUEVA")
		else
			PIDS_ERRORES=("${PIDS_ERRORES[@]}" "$PID")
		fi
		shift
	done
fi

if [ ! -z "${PIDS_BIEN[0]}" ] ; then
	echo -e "==============================================\nPID(S) que estan en uso actualmente: "
	echo "$CABECERA"
	for VAR in "${PIDS_BIEN[@]}"
	do
		echo "$VAR"
	done
fi

if [ ! -z "${PIDS_ERRORES[0]}" ] ; then
	echo "=============================================="
	echo "No hay ningun proceso con los siguientes PIDs: ${PIDS_ERRORES[*]}"
fi

exit 0
