#!/bin/bash

# Colores obtenidos del repositorio de Raul Calvo Laorden
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`
OK="echo [ ${GREEN}OK${NC} ]"
ERROR="echo [ ${RED}ERROR${NC} ]"

# Fecha para los errores
FECHA=$(date '+%Y-%m-%d %H:%M:%S')
# Fichero donde se almacenarán los errores.
AR_ERRORES='erroresInstaller'

# Argumentos validos
ARG_HELP_1="-h"
ARG_HELP_2="--help"
ARG_VERB_1="-v"
ARG_VERB_2="--verbose"

# Usabilidad del instalador
usage()
{
        echo -e "\n

Instalador portable para Linux

        $ARG_HELP_1 | $ARG_HELP_2               Ayuda sobre como llamar al instalador
        $ARG_VERB_1 | $ARG_VERB_2               Muestra detalladamente las operaciones que esta realizando.\n\n"
        return 0
}

# Indica si se mostrara en verbose
VERB=false

# Comprobamos los argumentos que se le pasan
while [ -n "$1" ] ; do
        case "$1" in
                "$ARG_VERB_1" | "$ARG_VERB_2")
                        VERB=true
                        ;;
                "$ARG_HELP_1" | "$ARG_HELP_2")
                        usage
                        exit 0
                        ;;
        esac
        shift
done


# Funciones:

# Pone la fecha al archivo de errores, para poder seguir la traza.
comprueba_fecha()
{
        if [ -f "$AR_ERRORES" ] ; then
                if grep -e "$FECHA" "$AR_ERRORES" >/dev/null ; then
                        return 0
                fi
                echo "$FECHA" >> "$AR_ERRORES"
                return 0
        else
                touch "$AR_ERRORES"
                return 0
        fi
        return 1
}


# Muestra una advertencia. Necesita: $1 - Mensje de error.
warning()
{
        if [ -n "$1" ] ; then
                echo "${RED} ** $1 ** ${NC}" 1>"$AR_ERRORES"
        fi
        return 1
}

# Ejecuta una orden. Necesita:  $1 - Prompt a mostrar
#                               $2 - Comando a realizar
ejecutar()
{
        echo -e -n "$1"
        if [ -n "$2" ] ; then
                if $VERB ; then
                        echo ""
                        $2
                        echo -e -n "$1"
                        if [ $? -eq 0 ] ; then
                                $OK
                                return 0
                        else
                                $ERROR
                                return 1
                        fi
                else
                        $2 >/dev/null 2>>"$AR_ERRORES" && $OK && return 0 || $ERROR
                        return 1
                fi
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
comprueba_fecha
if ejecutar " * Actualizando el equipo (updating): " 'sudo apt-get update -y' ; then
        ejecutar " \t* Actualizando el equipo (upgrading): " 'sudo apt-get upgrade -y'
fi
if ejecutar " * Instalando python-pip: " 'sudo apt-get install python-pip -y' ; then
        ejecutar " \t* Instalando xkcd pass: " 'pip install xkcdpass'
fi
echo -e "\nConfiguracion del equipo finalizada.\nPuede revisar los errores de la instalacion en el fichero \"$AR_ERRORES\"\n"

# Fin de la configuracion del equipo

exit 0
