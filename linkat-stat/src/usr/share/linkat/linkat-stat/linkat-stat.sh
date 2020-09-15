#!/bin/bash
#
# Nom del script: linkat-stat.sh
# Versió 1.1
# Autor: Joan de Gracia
#        Projecte Linkat
#        Àrea de Cultura Digital - Departament d'Educació
# Data: 2020/09/14
# Llicència GPL 3.0
# Dependències: nmap, dbus, dmidecode, virt-what
#
OD=$(which od)
echo "0" > /etc/lk-stat-counter
WAIT_TIME="5m"
ID_MACHINE="$(/usr/sbin/dmidecode -s system-uuid | sha1sum | cut -d " " -f 1)"
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
UBUNTU_DESKTOP="$(LANG=C apt list *ubuntu-desktop 2>/dev/null |grep -i "instal\|upgra" |cut -d "/" -f 1)"
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

ESPERA=$($OD -A n -N 2 -t u2 /dev/urandom )
let 'ESPERA %= 32' # mòdul -> residu: 0-31
let 'ESPERA += 58'
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
curl -s $URL/${CADENA}_${ID_MACHINE}_${VERSION}_${LINKAT_DESKTOP}_${ARCH}_${VIRTUALIZATION} -o /dev/null
exit 0
