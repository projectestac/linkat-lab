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
				if [ -n "$(grep "s1.lkca.cat" <<< $SCALA)" ]; then
		                        SCALA="s1.lkca.cat"
		                fi
			else
				SCALA="dm1.lkca.cat"
			fi
		fi
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
	RESPOSTA_CAF="?"
	COUNTER_CAF=0
        while [ -n "$RESPOSTA_CAF" ] && [ $COUNTER_CAF -le 5  ]; do
        	camclose
                sleep 1
                cam -c -l
                sleep 1
                RESPOSTA_CAF="$(caf restart 2>&1 | grep -i retrying)"
		if [ -n "$RESPOSTA_CAF" ]; then
                        let COUNTER_CAF+=1
	                sleep 10s
		else
			RESPOSTA_CAF=""
		fi
        done
#
# Es reinstal·la l'agent de CA cas que aquest doni un error a l'arrencar.
#
	if [ -z "$(pidof -s caf)" ]; then
		caf > /dev/null 2>&1
		CAF_OUTPUT=$?
		if [[ CAF_OUTPUT -ne 0 ]] || [[ -f /opt/configuracio/caf_reinstall_flag ]] || [[ -f /opt/configuracio/caf_remote_install_flag ]]; then
			install_ca
		fi
	fi
}

function install_ca {
	update-rc.d CA-DSM remove > /dev/null 2>&1
	update-rc.d CA-cam remove > /dev/null 2>&1
	if [ -d /opt/configuracio/ ]; then
		touch /opt/configuracio/caf_reinstall_flag
	fi
	if [ -f /etc/profile.CA ]; then
		rm /etc/profile.CA
	fi
	if [ -f /etc/init.d/CA-cam ]; then
		rm /etc/init.d/CA-cam
	fi
	if [ -f /etc/init.d/CA-DSM ]; then
		rm /etc/init.d/CA-DSM
	fi
	if [ -f /etc/init.d/CA-DSM.bak ]; then
		rm /etc/init.d/CA-DSM.bak
	fi
	if [ -d /opt/CA ]; then
		rm -rf /opt/CA
	fi
	if [ -f /opt/configuracio/caf_remote_install_flag ]; then
		rm /opt/configuracio/caf_remote_install_flag
	fi
	if [ -f /opt/configuracio/linkat-scala_server_check ]; then
		rm /opt/configuracio/linkat-scala_server_check
	fi	
	if [ -d /opt/configuracio ]; then
		/opt/configuracio/configura-equip-cli.sh CLI >/dev/null 2>&1
		check_ca_files
		rm /opt/configuracio/caf_reinstall_flag
	fi
}

function check_ca_files {
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
	if [  -d /opt/CA ];then
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
	fi
}

#
# MAIN
#

#
# El fitxer /opt/configuracio/linkat-caf-fix permet deshabilitar aquest script.
# De forma predeterminada, el fitxer /opt/configuracio/linkat-caf-fix no existeix per la qual cosa
# l'script s'executa.
#
if [ -f /opt/configuracio/linkat-caf-fix ]; then
	exit 0
fi
#
# Es comprova que l'equip no s'estigui configurant manualment
#
if [ -f /opt/configuracio/caf_install_manual_flag ]; then
	exit 0
fi
#
# Es comprova que CA estigui configurat.
#
if [[ -f /etc/profile.CA ]] && [[ -d /opt/CA ]]; then
#
	IONICE="$(which ionice)"
	RENICE="$(which renice)"
#
# Es comproven els permisos dels fitxers i es corregeix l'initscript /etc/init.d/CA-DSM
#
	check_ca_files
#
# Es comprova la connectivitat de l'equip.
# No s'avança fins que no hi hagi connexió a Internet.
#
	check_connectivity
#
# Es carrega el fitxer /etc/profile.CA:
#
	. /etc/profile.CA all
#
# Es copia el fitxer de configuració cam.cfg perquè CA treballi per protocol TCP
#
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
# CA PID check
# Si no ha arrencat correctament l'agent de CA, es força el seu reinici.
#
	if [ -z "$(pidof -s caf)" ]; then
		restart_ca
	fi
#

#
# Es redueix la prioritat dels processos:
# CLAMAV (clamd freshclam), CA(caf cfsmsmd cfnotsrvd cfProcessManager cfFTPlugin hmagent)
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
# S'habiliten els agents amagent i sdagent en cas que sigui necessari
#
	if [ -z "$(caf status amagent 2>&1 |grep -i enabled)" ]; then
		caf enable amagent
	fi

	if [ -z "$(caf status sdagent 2>&1 |grep -i enabled)" ]; then
		caf enable sdagent
	fi
#
# Es comprova l'scalability server de l'equip
#
	if [ ! -f /opt/configuracio/linkat-scala_server_check ]; then
		if [ -z "$(caf setserveraddress |grep lkca |grep running\ ok)" ]; then
			SCALA=""
			scala_server_check
			sleep 5
			caf setserveraddress $SCALA novalidate
		else
			touch /opt/configuracio/linkat-scala_server_check
		fi
	fi
#
# ES REGISTRA EL PAQUET FICTICI CA - REASSIGNACIO MANUAL D'EQUIP
#
	if [ -f /opt/configuracio/linkat-reassigna-equip-usuari-principal-flag ]; then
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
else
	if [ -d /opt/configuracio ]; then
		sleep 5m 	# 5 minuts de marge per poder configurar automàticament CA
		check_connectivity
		touch /opt/configuracio/caf_remote_install_flag
                /opt/configuracio/configura-equip-cli.sh CLI >/dev/null 2>&1
                check_ca_files
		if [ -f /opt/configuracio/caf_remote_install_flag ]; then
			rm /opt/configuracio/caf_remote_install_flag
		fi
		if [ -f /opt/configuracio/linkat-scala_server_check ]; then
			rm /opt/configuracio/linkat-scala_server_check
		fi
		if [ -f /opt/configuracio/caf_reinstall_flag ]; then
			rm /opt/configuracio/caf_reinstall_flag
		fi
	fi
fi
exit 0
