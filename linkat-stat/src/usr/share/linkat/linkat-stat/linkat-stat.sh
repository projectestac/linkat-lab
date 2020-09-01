#!/bin/bash
#
# Nom del script: linkat-stat.sh
# Versió 1.0
# Autor: Joan de Gracia
#        Projecte Linkat
#        Àrea de Cultura Digital - Departament d'Educació
# Data: 2020/08/31
# Llicència GPL 3.0
# Dependències: nmap, dbus, dmidecode, virt-what
#
WAIT_TIME="5m"
if [ ! -f /etc/lk-machine-id ]; then
   dbus-uuidgen --ensure=/etc/lk-machine-id 
   /usr/sbin/dmidecode -s system-uuid >> /etc/lk-machine-id
fi
if [ -z "$(tail -n 1 /etc/lk-machine-id  | grep $(/usr/sbin/dmidecode -s system-uuid))" ]; then
   rm /etc/lk-machine-id
   dbus-uuidgen --ensure=/etc/lk-machine-id 
   /usr/sbin/dmidecode -s system-uuid >> /etc/lk-machine-id
fi
ID_MACHINE="$(sha1sum /etc/lk-machine-id  |cut -d " " -f 1)"
VERSION="$(lsb_release -r| sed -e 's/\t//g' |cut -d ":" -f 2)"
ARCH="$(uname -m)"
if [ $ARCH == "x86_64" ]; then
   ARCH="x86-64"
else
   ARCH="i386"
fi
VIRTUALIZATION="$(virt-what |head -n1)"
if [ -z "$VIRTUALIZATION" ]; then
   VIRTUALIZATION="physical"
fi
URL="download-linkat.xtec.cat"
CADENA="STAT-LK"
UBUNTU_DESKTOP="$(apt list *ubuntu-desktop 2>/dev/null |grep -i instal |cut -d "/" -f 1)"
case $UBUNTU_DESKTOP in
ubuntu-desktop)
   LINKAT_DESKTOP="gnome"
;;
lubuntu-desktop)
   LINKAT_DESKTOP="lxde"
;;
esac
#
# Checking Network Connectivity
#
OD=$(which od)
ESPERA=$($OD -A n -N 2 -t u2 /dev/urandom )
let 'ESPERA %= 32' # mòdul -> residu: 0-31
let 'ESPERA += 53'
# sleep 1s -> 1 segon / sleep 1m -> 1 minut
sleep $ESPERA
FLAG=0
TEST_IPS="educaciodigital.cat ubuntu.com wikipedia.org"
TARGET=($(echo $TEST_IPS))
N_TARGET=${#TARGET[@]}
let 'N_TARGET -=1'
TEST_PORT=443
CURRENT_TEST_IP=0
while [ $FLAG -eq 0 ];
do
   TESTIP=${TARGET[$CURRENT_TEST_IP]}
   if [ -z "$(nmap  -p $TEST_PORT $TESTIP  2>/dev/null |grep open)" ]; then
      if [ $CURRENT_TEST_IP -lt $N_TARGET ]; then   
   	   let 'CURRENT_TEST_IP +=1'
   	else
   	   CURRENT_TEST_IP=0
         sleep $WAIT_TIME
      fi
   else
      FLAG=1
   fi
done
#
# CHECK EXTERNAL IP ADDRESS
#
EXTERNAL_IP=""
FLAG=0 
CHECK_IP="https://diagnostic.opendns.com/myip https://checkip.amazonaws.com"
TARGET=($(echo $CHECK_IP))
N_TARGET=${#TARGET[@]}
let 'N_TARGET -=1'
CURRENT_CHECK=0
while [ $FLAG -eq 0 ];
do
   CHECKIP=${TARGET[$CURRENT_CHECK]}
   EXTERNAL_IP="$(curl -s $CHECKIP)"
   if [ -z "$EXTERNAL_IP" ]; then
      if [ $CURRENT_CHECK -lt $N_TARGET ]; then   
   	   let 'CURRENT_CHECK +=1'
   	else
   	   CURRENT_CHECK=0
         sleep $WAIT_TIME
      fi
   else
      FLAG=1
   fi
done  
curl -s $URL/${CADENA}_${ID_MACHINE}_${EXTERNAL_IP}_${VERSION}_${LINKAT_DESKTOP}_${ARCH}_${VIRTUALIZATION} -o /dev/null
exit 0
