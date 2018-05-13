# Atajos para comprimir y extraer
comprimir(){
	if [ $# -ne 2 ] ; then
		echo "uso: $0 archivo directorio"
		return 1
	fi
	if [ ! -d $2 ] ; then
		echo "$2 no es un directorio."
		return 1
	fi
	tar -zcvf "$(echo "$1")".tgz $2
	return 0
}

extraer(){
	if [ $# -ne 1 ] ; then
		echo "uso: $0 archivo"
		return 1
	fi
	if [ ! -f $1 ] ; then
		echo "$1 no es un archivo valido."
		return 1
	fi
	tar -zxvf "$1"
}
 
# Medimos la temperatura de la raspberry
alias temperatura='/opt/vc/bin/vcgencmd measure_temp'

# Muestra la memoria en CPU y GPU en raspberry
alias memoria='/opt/vc/bin/vcgencmd get_mem arm && /opt/vc/bin/vcgencmd get_mem gpu'

# Actualizamos el sistema
alias actualizar='sudo apt-get update && sudo apt-get upgrade' 

# Abrimos la configuracion de raspberry
alias config='sudo raspi-config'

# Apagar
alias apagar='shutdown -h now'

# Mostramos las redes disponibles:
alias escanear='iwlist wlan0 scan'
alias escanear_nombres='escanear | grep ESSID'

# Muestra información en el disco:
alias disco='df -h'
alias libre='du -hs /* 2>/dev/null'
