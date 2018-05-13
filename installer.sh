#!/bin/bash

# Colores obtenidos del repositorio de Raul Calvo Laorden
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`
OK="echo [ ${GREEN}OK${NC} ]"
ERROR="echo [ ${RED}ERROR${NC} ]"

# Funciones:

# Muestra una advertencia. Necesita: $1 - Mensje de error.
warning()
{
	if [ -n "$1" ] ; then
		echo "${RED} ** $1 ** ${NC}" 1>&2
	fi
	return 1
}

# Ejecuta una orden. Necesita:	$1 - Prompt a mostrar
#				$2 - Comando a realizar
ejecutar()
{
	echo -n "$1"
	if [ -n "$2" ] ; then
		$2 >/dev/null 1>/dev/null && $OK || $ERROR
		return 0
	fi
	$ERROR
	warning "No se ha especificado ninguna orden"
	return 1
}

# Comprobamos que sea el usuario root quien lo este ejecutando.
comprobar_root()
{
	echo -n " * Ejecutando el script como usuario root: "
	if [ $EUID -ne 0 ] ; then
		$ERROR
		warning "Solo root puede ejecutar este script."
		exit 1
	fi
	$OK
	return 0
}


# Configuracion del propio equipo

echo -e "\nComienza la configuracion del equipo\n"
comprobar_root
ejecutar " * Actualizando el equipo * " 'sudo apt-get update && sudo apt-get upgrade' 
ejecutar " * Instalando python-pip: " 'sudo apt-get install python-pip -y'
echo -e "\nConfiguracion del equipo finalizada.\n"

# Fin de la configuracion del equipo

exit 0
