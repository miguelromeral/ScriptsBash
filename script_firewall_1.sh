#!/bin/sh

#####################################################
#                                                   #
#           CONFIGURACIÓN DEL FIREWALL 1            #
#                                                   #
#####################################################

# Para verificar si funciona: iptables -L -n

echo "Comienzo a configurar el firewall 1."

#####################################################
#   1. Configuración de parámetros generales.

# Localizacion de iptables.

IPT="/sbin/iptables"

# Habilitación del reenvio.

REENVIO="1"

# Interfaces del firewall

DMZ_INTERFACE="eth2"
LAN_INTERFACE="eth1"
LOOPBACK_INTERFACE="lo"

# Direcciones de red

DMZ_IPADDR="192.168.0.66"
DMZ_ADDRESSES="192.168.0.64/26"
DMZ_NETWORK="192.168.0.64"
DMZ_BROADCAST="192.168.0.127"

LAN_IPADDR="192.168.0.1"
LAN_ADDRESSES="192.168.0.0/26"
LAN_NETWORK="192.168.0.0"
LAN_BROADCAST="192.168.0.63"
LAN_NETMASK="255.255.255.192"

DMZ_IPADDR_FIREWALL_2="192.168.0.65"
LOOPBACK="127.0.0.1"
BROADCAST_SRC="0.0.0.0"
BROADCAST_DEST="255.255.255.255"

WEB_SERVER="192.168.0.67"
PROXY_SERVER="192.168.0.68"     #Tambien nos sirve de DNS
SMTP_SERVER_1="40.101.51.210"
SMTP_SERVER_2="40.101.45.82"
IMAP_SERVER_1="40.101.92.178"
IMAP_SERVER_2="40.101.136.18"

# Rango de puertos

PRIVPORTS="0:1023"
UNPRIVPORTS="1024:65535"

# Puertos

PROXY="3128"
DNS="53"
HTTP="80"
HTTPS="443"
POP3="587"  #Para SMTP
IMAP="993"
SSH="22"

# Política por defecto

DEF_POL="DROP"

# Valores para mostrar avisos en el script

RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0`
OK="echo [ ${GREEN}OK${NC} ]"
ERROR="echo [ ${RED}ERROR${NC} ]"

if [[ $EUID -ne 0 ]] ; then
       echo "${RED} ** Solo root puede ejecutar este script. ** ${NC}" 1>&2
       echo "La configuracion del firewall no ha cambiado."
       exit 1
fi

#####################################################
#   2. Eliminación de reglas existentes

echo "Limpiando reglas existentes en el firewall."

# Flush de reglas, ahora por defecto estan en ACCEPT

$IPT -F
$IPT -t nat -F
$IPT -t mangle -F
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X

# Establecemos las politicas por defecto aceptar, por si se quisiera restablecer todo

$IPT --policy INPUT   ACCEPT
$IPT --policy OUTPUT  ACCEPT
$IPT --policy FORWARD ACCEPT
$IPT -t nat --policy PREROUTING  ACCEPT
$IPT -t nat --policy OUTPUT ACCEPT
$IPT -t nat --policy POSTROUTING ACCEPT
$IPT -t mangle --policy PREROUTING ACCEPT
$IPT -t mangle --policy OUTPUT ACCEPT

if [ $# -gt 0 ] ; then
	echo "Las tablas vuelven a estar vacias"
	exit 0
fi

#####################################################
#   3. Indicamos la política por defecto: DENEGAR

echo "Estableciendo politica por defecto a $DEF_POL."

$IPT -P INPUT $DEF_POL
$IPT -P OUTPUT $DEF_POL
$IPT -P FORWARD $DEF_POL

#####################################################
#   4. Habilitamos todo el tráfico de la interfaz de loopback para que funcione

echo "Habilitando el trafico por la interfaz de loopback."

$IPT -A INPUT  -i $LOOPBACK_INTERFACE -j ACCEPT
$IPT -A OUTPUT -o $LOOPBACK_INTERFACE -j ACCEPT


#####################################################
#   5. (OPCIONAL) Reglas para el filtrado de escaneos

echo "Creando reglas para el filtrado de escaneos."

$IPT -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
$IPT -A FORWARD -p tcp --tcp-flags ALL NONE -j DROP

$IPT -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
$IPT -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

$IPT -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
$IPT -A FORWARD -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

$IPT -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
$IPT -A FORWARD -p tcp --tcp-flags FIN,RST FIN,RST -j DROP

$IPT -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP
$IPT -A FORWARD -p tcp --tcp-flags ACK,FIN FIN -j DROP

$IPT -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP
$IPT -A FORWARD -p tcp --tcp-flags ACK,PSH PSH -j DROP

$IPT -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP
$IPT -A FORWARD -p tcp --tcp-flags ACK,URG URG -j DROP

# Permitimos las conexiones establecidas y relacionadas
$IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#####################################################
#   6. (OPCIONAL) Optimizacion de reglas

#####################################################
#   7. (OPCIONAL) Reglas para el filtrado de direcciones fuente falsificadas

echo "Creando reglas para el filtrado de direcciones fuente falsas."

# Source Address Spoofing and Other Bad Addresses
# Refuse spoofed packets pretending to be from you

$IPT -A INPUT -s $DMZ_IPADDR -j DROP
$IPT -A INPUT -s $LAN_IPADDR -j DROP

$IPT -A FORWARD -s $DMZ_IPADDR -j DROP
$IPT -A FORWARD -s $LAN_IPADDR -j DROP

$IPT -A INPUT -i $DMZ_INTERFACE -s $LAN_ADDRESSES -j DROP
$IPT -A FORWARD -i $DMZ_INTERFACE -s $LAN_ADDRESSES -j DROP

$IPT -A FORWARD  -i $LAN_INTERFACE ! -s $LAN_ADDRESSES -j DROP

$IPT -A OUTPUT -o $DMZ_INTERFACE ! -s $DMZ_IPADDR -j DROP
$IPT -A OUTPUT -o $LAN_INTERFACE ! -s $LAN_IPADDR -j DROP

$IPT -A OUTPUT -o $LAN_INTERFACE -p udp -s $BROADCAST_SRC --sport 67 -d $BROADCAST_DEST --dport 68 -j ACCEPT

$IPT -A OUTPUT -o $LAN_INTERFACE ! -s $LAN_IPADDR -j DROP

# Refuse malformed broadcast packets
$IPT -A FORWARD -i $LAN_INTERFACE -o $DMZ_INTERFACE -d $BROADCAST_SRC  -j DROP

$IPT -A FORWARD -i $LAN_INTERFACE -o $DMZ_INTERFACE -d $BROADCAST_SRC  -j DROP

# Don.t forward directed broadcasts
$IPT -A FORWARD -i $LAN_INTERFACE -o $DMZ_INTERFACE -d $DMZ_NETWORK -j DROP
$IPT -A FORWARD -i $LAN_INTERFACE -o $DMZ_INTERFACE -d $DMZ_BROADCAST -j DROP

# Don.t forward limited broadcasts in either direction
$IPT -A FORWARD -d $BROADCAST_DEST -j DROP

#####################################################
#   8. (OPCIONAL) Filtrado de mensajes ICMP

echo "Habilitando el filtrado de mensajes ICMP."

# Log and drop initial ICMP fragments
$IPT -A INPUT --fragment -p icmp -j LOG --log-prefix "Fragmented incoming ICMP: "
$IPT -A INPUT --fragment -p icmp -j DROP

$IPT -A OUTPUT --fragment -p icmp -j LOG --log-prefix "Fragmented outgoing ICMP: "
$IPT -A OUTPUT --fragment -p icmp -j DROP

$IPT -A FORWARD --fragment -p icmp -j LOG --log-prefix "Fragmented forwarded ICMP: "
$IPT -A FORWARD --fragment -p icmp -j DROP

$IPT -A INPUT -p icmp --icmp-type source-quench -d $DMZ_IPADDR -j ACCEPT
$IPT -A OUTPUT -p icmp --icmp-type source-quench -j ACCEPT
$IPT -A FORWARD -p icmp --icmp-type source-quench -j ACCEPT

$IPT -A INPUT -p icmp --icmp-type parameter-problem -j ACCEPT
$IPT -A OUTPUT -p icmp --icmp-type parameter-problem -j ACCEPT
$IPT -A FORWARD -p icmp --icmp-type parameter-problem -j ACCEPT

$IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
$IPT -A OUTPUT -o $LAN_INTERFACE -p icmp --icmp-type destination-unreachable -d $LAN_ADDRESSES -j ACCEPT
$IPT -A FORWARD -o $LAN_INTERFACE -p icmp --icmp-type destination-unreachable -d $LAN_ADDRESSES -j ACCEPT

$IPT -A OUTPUT -p icmp --icmp-type fragmentation-needed -j ACCEPT
$IPT -A FORWARD -p icmp --icmp-type fragmentation-needed -j ACCEPT

# Don.t log dropped outgoing ICMP error messages
$IPT -A OUTPUT  -p icmp --icmp-type destination-unreachable -j DROP
$IPT -A FORWARD -o $DMZ_INTERFACE -p icmp --icmp-type destination-unreachable -j DROP

# Intermediate traceroute responses
$IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$IPT -A FORWARD -o $LAN_INTERFACE -p icmp --icmp-type time-exceeded -d $LAN_ADDRESSES -j ACCEPT

# allow outgoing pings to anywhere
$IPT -A OUTPUT -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

$IPT -A FORWARD -o $DMZ_INTERFACE -p icmp --icmp-type echo-request -s $LAN_ADDRESSES -m state --state NEW -j ACCEPT

# allow incoming pings from trusted hosts
$IPT -A INPUT  -i $DMZ_INTERFACE -p icmp -s $DMZ_ADDRESSES --icmp-type echo-request -d $DMZ_IPADDR -m state --state NEW -j ACCEPT

$IPT -A INPUT  -i $LAN_INTERFACE -p icmp -s $LAN_ADDRESSES --icmp-type echo-request -d $LAN_IPADDR -m state --state NEW -j ACCEPT

#####################################################
#   9. Habilitar DNS

echo "Habilitando DNS."

# REGLA NÚMERO 3 - Habilitamos consultas DNS de la LAN la Proxy

echo -n " - Regla #3: Consultas DNS de la LAN al Proxy por UDP: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $PROXY_SERVER -i $LAN_INTERFACE -o $DMZ_INTERFACE -p udp --sport $UNPRIVPORTS --dport $DNS -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR

echo -n " - Regla #3: Consultas DNS de la LAN al Proxy por TCP: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $PROXY_SERVER -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $DNS -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR

#####################################################
#   10. Habilitar correo electrónico 

echo "Habilitamos SMTP y IMAP."

# REGLA NÚMERO 1 - Conexion al correo de la UAH

#SMTP

echo -n " - Regla #1: Conexion al correo SMTP ($SMTP_SERVER_1) de la UAH: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $SMTP_SERVER_1 -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $POP3 -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR
echo -n " - Regla #1: Conexion al correo SMTP ($SMTP_SERVER_2) de la UAH: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $SMTP_SERVER_2 -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $POP3 -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR

# IMAP

echo -n " - Regla #1: Conexion al correo IMAP ($IMAP_SERVER_1) de la UAH: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $IMAP_SERVER_1 -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $IMAP -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR
echo -n " - Regla #1: Conexion al correo IMAP ($IMAP_SERVER_2) de la UAH: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $IMAP_SERVER_2 -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $IMAP -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR


#####################################################
#   11. Habilitar SSH 

echo "Habilitamos SSH."

# REGLA NÚMERO 5 - Habilitamos uso remoto desde la LAN hasta el Web Server

echo -n " - Regla #5: Uso remoto desde la LAN hasta el Web Server: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $WEB_SERVER -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $SSH -j ACCEPT) >/dev/null 2>&1  && $OK || $ERROR

# REGLA NÚMERO 7 - Habilitamos uso remoto desde la LAN hasta el Firewall 2

echo -n " - Regla #7: Uso remoto desde la LAN hasta el firewall 2: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $DMZ_IPADDR_FIREWALL_2 -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $SSH -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR

# REGLA NÚMERO 6 - Configuración del firewall desde la LAN

echo -n " - Regla #6: Configuracion del firewall desde la LAN (Entrada): "
($IPT -A INPUT -s $LAN_ADDRESSES -d $LAN_IPADDR -i $LAN_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $SSH -j ACCEPT) >/dev/null 2>&1&& $OK || $ERROR
echo -n " - Regla #6: Configuracion del firewall desde la LAN (Salida): "
($IPT -A OUTPUT -s $LAN_IPADDR -d $LAN_ADDRESSES -o $LAN_INTERFACE -p tcp --sport $SSH --dport $UNPRIVPORTS -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR

#####################################################
#   12. Habilitar Web 

echo "Habilitando al Web Server ($WEB_SERVER)."

# REGLA NÚMERO 2 - Permitimos conexiones de la LAN hasta el Proxy

echo -n " - Regla #2: Permitiendo conexiones de la LAN hasta el Proxy: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $PROXY_SERVER -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $PROXY -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR

# REGLA NÚMERO 4 - Permitimos conexiones de la LAN hasta el Web Server

# Conexion HTTP
echo -n " - Regla #4: Permitiendo conexiones HTTP de la LAN hasta el Web Server: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $WEB_SERVER -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $HTTP -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR
# Conexion HTTPS
echo -n " - Regla #4: Permitiendo conexiones HTTPS de la LAN hasta el Web Server: "
($IPT -A FORWARD -s $LAN_ADDRESSES -d $WEB_SERVER -i $LAN_INTERFACE -o $DMZ_INTERFACE -p tcp --sport $UNPRIVPORTS --dport $HTTPS -j ACCEPT) >/dev/null 2>&1 && $OK || $ERROR


#####################################################
# Habilitamos el reenvio de los paquetes desde el firewall

echo "Habilitando el reenvio."

echo $REENVIO > /proc/sys/net/ipv4/ip_forward


#####################################################
# Indicamos que todos los paquetes descartados queden registrados

echo "Permitiendo el registro de paquetes descartados."

$IPT -A INPUT  -i $LAN_INTERFACE -j LOG
$IPT -A OUTPUT -o $LAN_INTERFACE -j LOG
$IPT -A FORWARD  -i $LAN_INTERFACE -o $DMZ_INTERFACE -j LOG
$IPT -A FORWARD  -i $DMZ_INTERFACE -o $LAN_INTERFACE -j LOG

echo "Fin de la configuracion."

exit 0
