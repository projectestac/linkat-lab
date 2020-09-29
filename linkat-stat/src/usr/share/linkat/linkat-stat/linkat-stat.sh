#!/bin/bash
#
# Nom del script: linkat-stat.sh
# Versió 1.3
# Autor: Joan de Gracia
#        Projecte Linkat
#        Àrea de Cultura Digital - Departament d'Educació
# Data: 2020/09/18
# Llicència GPL 3.0
# Dependències: nmap, dmidecode, virt-what
#
if [ "$(ps aux |grep linkat-stat |grep HOURLY | wc -l )"  -gt 2 ]; then
   exit 0
fi
START=$1
OD=$(which od)
WAIT_TIME=5m
MAX_RANDOM_TIME=$2
ESPERA=$($OD -A n -N 2 -t u2 /dev/urandom )
let 'ESPERA %= MAX_RANDOM_TIME' # mòdul
let 'ESPERA += 60'
sleep $ESPERA
ID_MACHINE="$(/usr/sbin/dmidecode -s system-uuid | sha1sum | cut -d " " -f 1)"
VERSION="$(/usr/bin/lsb_release -r| sed -e 's/\t//g' |cut -d ":" -f 2)"
ARCH="$(uname -m)"
if [ $ARCH == "x86_64" ]; then
   ARCH="x86-64"
else
   ARCH="i386"
fi

if [ $VERSION == "14.04" ] || [ $VERSION == "18.04" ]; then
   COMPUTER="$(LANG=C apt list linkat-server linkat-servidor 2>/dev/null |grep -i "instal\|upgra" |cut -d "/" -f 1)"
   if [ -z $COMPUTER ]; then
      COMPUTER="workstation"
   else
      COMPUTER="server" 
   fi 
else
   COMPUTER="workstation"
fi

VIRT="$(/usr/sbin/virt-what |head -n1)"
VIRTUALIZATION="$(echo "$VIRT" | sed 's/[ ]\+/-/g')"
if [ -z "$VIRT" ]; then
   VIRTUALIZATION="physical"
fi
URL="download-linkat.xtec.cat"
URL="linkat.eu"
CADENA="STAT-LK"-"$1"
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
curl -s $URL/${CADENA}_${ID_MACHINE}_${VERSION}_${LINKAT_DESKTOP}_${ARCH}_${COMPUTER}_${VIRTUALIZATION} -o /dev/null
exit 0
