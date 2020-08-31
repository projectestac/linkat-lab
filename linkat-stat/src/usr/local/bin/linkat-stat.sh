#!/bin/bash
#
# DEPENDENCIES:
# od
# nmap
# dbus
#

LIMIT_COUNTER=4
COUNTER=0
if [ ! -f /etc/lk-stat-counter ]; then
   echo $COUNTER > /etc/lk-stat-counter
else
   COUNTER=$(cat /etc/lk-stat-counter)
   let 'COUNTER += 1'
   if [ $COUNTER -le $LIMIT_COUNTER ]; then
      echo $COUNTER > /etc/lk-stat-counter
   fi
fi
if [ $COUNTER -eq $LIMIT_COUNTER ]; then
   if [ -f /etc/lk-machine-id ]; then
      rm /etc/lk-machine-id
   fi
   dbus-uuidgen --ensure=/etc/lk-machine-id 
fi
if [ $COUNTER -ge $LIMIT_COUNTER ]; then
   ID_MACHINE="$(sha1sum /etc/lk-machine-id  |cut -d " " -f 1)"
   VERSION="$(lsb_release -r| sed -e 's/\t//g' |cut -d ":" -f 2)"
   ARCH="$(uname -m)"
   if [ $ARCH == "x86_64" ]; then
      ARCH="x86-64"
   else
      ARCH="i386"
   fi
   URL=linkat.eu
   CADENA="STAT-LK"
   UBUNTU_DESKTOP="$(apt list *ubuntu-desktop 2>/dev/null |grep -i instal |cut -d "/" -f 1)"
   WAIT_TIME="5m"
   case $UBUNTU_DESKTOP in
   ubuntu-desktop)
      LINKAT_DESKTOP="ESTANDARD"
   ;;
   lubuntu-desktop)
      LINKAT_DESKTOP="LLEUGERA"
   ;;
   esac
   OD=$(which od)
   ESPERA=$($OD -A n -N 2 -t u2 /dev/urandom )
   let 'ESPERA %= 32' # mòdul -> residu: 0-31
   let 'ESPERA += 53'
   # sleep $ESPERA (p.e. sleep 1s -> 1 segon / sleep 1m -> 1 minut
   #sleep $ESPERA
   FLAG=0
   TEST_IPS="educaciodigital.cat xtec.gencat.cat"
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
   # FLAG = 1 -> Hi ha accés a Internet
   #
   curl -s $URL/${CADENA}_${ID_MACHINE}_${VERSION}_${ARCH}_${LINKAT_DESKTOP}_SCRIPT -o /dev/null
fi
exit 0
