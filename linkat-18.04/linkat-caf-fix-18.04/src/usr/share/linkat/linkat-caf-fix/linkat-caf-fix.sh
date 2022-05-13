#!/bin/bash
#
function scala_server_check {
	if [ -n "$(grep mnt-recuperacio /etc/fstab)" ]; then
		if [ -z "$(mount |grep mnt-recuperacio)" ]; then
			mount /opt/configuracio/mnt-recuperacio
		fi
		if [ -n "$(mount |grep mnt-recuperacio)" ]; then
			if [ -f /opt/configuracio/mnt-recuperacio/config/config-ca ]; then
				SCALA=$(cat /opt/configuracio/mnt-recuperacio/config/config-ca | cut -d ":" -f 2)
			fi
		fi
		if [ -z "$(echo "$SCALA" |grep lkca)" ]; then
			SCALA="dm1.lkca.cat"
		fi
		sleep 1
		umount /opt/configuracio/mnt-recuperacio
		sleep 1
	fi
}

function check_connectivity {
        LOCAL_IP="$(hostname -I)"
        while [ "$LOCAL_IP" == "" ]; do
                sleep 30
                LOCAL_IP="$(hostname -I)"
        done
	WAIT_TIME=1m
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
}

function restart_ca {
	camclose
	sleep 5
	cam -c -l
	sleep 5
	caf restart
}

#
# main
#

#
# El fitxer /etc/linkat-caf-fix permet deshabilitar aquest script.
# De forma predeterminada, el fitxer /etc/linkat-caf-fix no existeix per la qual cosa
# l'script s'executa.
#
if [ -f /etc/linkat-caf-fix ]; then
	exit 0
fi
#
# Es comprova que CA estigui configurat.
#
if [ -f /etc/profile.CA ]; then
	IONICE="$(which ionice)"
	RENICE="$(which renice)"
#
# Es corregeix l'initscript de CA (CA-DSM) perquè tanqui ràpidament.
#
	if [ -f /etc/init.d/CA-DSM ]; then
		if [ -z "$(grep caf\ kill\ all /etc/init.d/CA-DSM)" ]; then
			cp /etc/init.d/CA-DSM /etc/init.d/CA-DSM.bak
			sed -i 's/sd_jexec\ unit/\#sd_jexec\ unit/g' /etc/init.d/CA-DSM
			sed -i '/#sd_jexec\ unit=\.\ shutdown\ >>/a\\t\t\tcaf\ kill\ all\ \>\/dev\/null 2>&1' /etc/init.d/CA-DSM 
		fi
	fi
#
# Es canvien permisos de determinats fitxers i directoris
#
	if [ "$(stat -c "%a" /opt/CA/CAlib)" != "755" ]; then
		chmod 755 /opt/CA/CAlib
	fi
	BASE_DIR_CAF=/opt/CA/SharedComponents
	for i in bin cai18n ccs lib packager;
	do
		if [ -d "$BASE_DIR_CAF/$i" ]; then
			if [ "$(stat -c "%a" "$BASE_DIR_CAF/$i")" != "755" ]; then
				chmod 755 $BASE_DIR_CAF/$i
			fi
                fi
	done
#
# Es comprova la connectivitat de l'equip
# No s'avança fins que no hi hagi connexió a Internet
#
	check_connectivity
#
# Es carrega el fitxer /etc/profile.CA com indica CA
#
	. /etc/profile.CA all
#
# CA PID check
# Si no ha arrencat correctament l'agent de CA, es força el seu reinici.
#
	if [ -z "$(pidof -s caf)" ]; then
		restart_ca
	fi
#
# Es copia el fitxer de configuració cam.cfg perquè CA treballi per protocol TCP
#
	if [ ! -f /opt/CA/SharedComponents/ccs/cam/cam.cfg ]; then
		if [ -f /usr/share/linkat/linkat-caf-fix/cam.cfg ]; then
			cp /usr/share/linkat/linkat-caf-fix/cam.cfg /opt/CA/SharedComponents/ccs/cam/
			chmod 644 /opt/CA/SharedComponents/ccs/cam/cam.cfg
			restart_ca
		fi
	else
		if [ -f /usr/share/linkat/linkat-caf-fix/cam.cfg ]; then
			if [ -n "$(diff /usr/share/linkat/linkat-caf-fix/cam.cfg /opt/CA/SharedComponents/ccs/cam/cam.cfg)" ]; then
				cp /usr/share/linkat/linkat-caf-fix/cam.cfg /opt/CA/SharedComponents/ccs/cam/
				chmod 644 /opt/CA/SharedComponents/ccs/cam/cam.cfg
				restart_ca
			fi
		fi
	fi
#
# Es redueix la prioritat dels processos:
# clamd freshclam caf cfsmsmd cfnotsrvd cfProcessManager cfFTPlugin hmagent
# amb les ordres renice (a nivell de procés) i ionice (a nivell d'Entrada i Sortida de disc).
#
	COUNTER=0
	for j in clamd freshclam caf cfsmsmd cfnotsrvd cfProcessManager cfFTPlugin hmagent
	do
		PIDOF_CAF=$(pidof -s $j)
		while [ -z "$(pidof -s $j)" ] && [ $COUNTER -le 6  ]; do
			let COUNTER+=1
			sleep 5s
		done
		if [ -n "$PIDOF_CAF" ]; then
			$RENICE -n 19 -p "$PIDOF_CAF"
			$IONICE -c2 -n7 -p "$PIDOF_CAF"
		fi
	done
#
# Habilitem els agents amagent i sdagent en cas que sigui necessari
#
	if [ -z "$(caf status amagent 2>&1 |grep -i enabled)" ]; then
		caf enable amagent
	fi

	if [ -z "$(caf status sdagent 2>&1 |grep -i enabled)" ]; then
		caf enable sdagent
	fi
#
# Comprovem el scalability server de l'equip
#
	if [ ! -f /etc/linkat-scala_server_check ]; then
		if [ -z "$(caf setserveraddress |grep lkca |grep running\ ok)" ]; then
			scala_server_check
			caf setserveraddress $SCALA
		else
			touch /etc/linkat-scala_server_check
		fi
	fi
#
# REGISTREM PAQUET FICTICI CA - REASSIGNACIO MANUAL D'EQUIP
#
	if [ -e /opt/configuracio/linkat-reassigna-equip-usuari-principal-flag ]; then
		if [ -n "$(pidof -s caf)" ]; then
			check_connectivity
			scala_server_check
			if [ -z "$(caf ping $SCALA |grep -i failed)" ]; then
				sd_acmd AddUninstallRecord "linkat-reassigna-equip-edc-local" "V1.0" "Uninstall" "" current current "" ""
				sleep 1
				sd_acmd AddInstallRecord "linkat-reassigna-equip-edc-local" "V1.0" "Install" current current "" ""
				sleep 1
				caf start amagent sdagent
				rm /opt/configuracio/linkat-reassigna-equip-usuari-principal-flag
			fi
		fi
	fi
fi
exit 0
