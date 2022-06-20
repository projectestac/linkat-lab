#!/bin/bash

#LANG=en_EN
N_PARAMS=$#

mnt_recuperacio="/opt/configuracio/mnt-recuperacio"
config_file="$mnt_recuperacio/config/config-ca"
title="Configuració CA"

# Instala y configura CA
function install_ca {
#
# Rutina PREINSTALL agent CA
#
	update-rc.d CA-DSM remove > /dev/null 2>&1
	update-rc.d CA-cam remove > /dev/null 2>&1
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
	if [ -n "$(pidof -s caf)" ]; then
        	pkill caf
	fi
	if [ -f  /opt/configuracio/linkat-scala_server_check ]; then
		rm /opt/configuracio/linkat-scala_server_check
	fi
#
# Rutina INSTALL de l'agent de CA
#
	CODICENTRE=$ccentre
	[[ $N_PARAMS == 0 ]] && sleep 2 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Instal·lant CA..." 2>/dev/null)
	cd /opt/configuracio/CA
	./installdsm -bg -r install.rsp /RITM_SERVER=127.0.0.1 2>&1
	[[ $N_PARAMS == 0 ]] && sleep 2 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Finalitzant instal·lació..." 2>/dev/null)
	cd /opt/configuracio
	# Config
	. /etc/profile.CA all
#
# Es copia el fitxer de configuració cam.cfg perquè CA treballi per protocol TCP
# i es reinicia l'agent de CA
#
	cp /usr/share/linkat/linkat-caf-fix/cam.cfg /opt/CA/SharedComponents/ccs/cam/
	chmod 644 /opt/CA/SharedComponents/ccs/cam/cam.cfg
#
# Es reinicia l'agent CAM
#
	camclose
	sleep 2
	cam -c -l
#
	caf setserveraddress $Scala novalidate
	caf restart
#
# S'habiliten els agents sdagent i amagent
#
	caf enable sdagent amagent
	caf register all 
	caf start amagent args /rescan_inventory /rescan_software /collect
	# Reportamos un paquete inexistente con el código de centro
	sd_acmd AddInstallRecord "Centre" $CODICENTRE "install" current current "Imatge" ""
	[[ $N_PARAMS == 0 ]] && sleep 2 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Configurant CA..." 2>/dev/null)
	[[ $N_PARAMS == 0 ]] && sleep 5 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="L'equip es reiniciarà per desar la nova configuració..." 2>/dev/null)
	clean_house
	sleep 5
	[[ $N_PARAMS == 0 ]] && reboot
#
# Rutina de POSTINSTALL de l'agent de CA
#

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

# Mira si hay conectividad
function check_internet {
	wget -q --spider http://google.com 
	return $?
}

# Limpiamos antes de salir
function clean_house {
	if [ -f "$mnt_recuperacio/cookies.txt" ]; then
		rm $mnt_recuperacio/cookies.txt
	fi
	if [ -f "$mnt_recuperacio/centres.csv" ]; then
		rm $mnt_recuperacio/centres.csv
	fi
	if [ -f /opt/configuracio/caf_install_manual_flag ]; then
		rm /opt/configuracio/caf_install_manual_flag
	fi
	umount $mnt_recuperacio
}

#
# MAIN
#
# Requerimos ejecución como root
#
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
	[[ $N_PARAMS == 0 ]] && sudo sudo -u suport DISPLAY=:0.0 zenity --error --width=400 --height=200 --title $title --text "Si us plau, torneu a executar l'script com a usuari root."
	exit 1
fi

if [[ $N_PARAMS == 0 ]]; then
	if [ -f /opt/configuracio/caf_remote_install_flag ]; then
		sudo sudo -u suport DISPLAY=:0.0 zenity --error --width=400 --height=200 --title $title --text "L'agent de CA s'està instal·lant de forma automàtica. Es finalitzarà el procés actual d'instal·lació manual"
		exit 0
	fi
#
# Es deixa la marca /opt/configuracio/caf_install_manual_flag perquè l'script linkat-caf-fix
# no s'executi mentre la configuració manual de CA (script config-ca.sh) s'estigui executant
#
	touch /opt/configuracio/caf_install_manual_flag
fi
#
# Es munta la partició de restauració que conté el fitxer $config_file que conté (o contindrà
# el codi de centre i el servidor d'escalabilitat de CA.
#
if [ -n "$(grep mnt-recuperacio /etc/fstab)" ]; then
	if [ -z "$(mount |grep mnt-recuperacio)" ]; then
		mount /opt/configuracio/mnt-recuperacio
	fi
fi
# mount /dev/mmcblk0p3 $mnt_recuperacio

# Config nueva (no existe archivo)
if [ ! -f $config_file ]; then
	if [ $N_PARAMS == 0 ]; then
		ccentre_conf=1	
		# Mientras no se confirme o cancele, pedimos ccentre
		while [ $ccentre_conf -ne 0 ]; do
			ccentre=$(sudo sudo -u suport DISPLAY=:0.0 zenity --entry --width=400 --height=200 --title $title --text "Si us plau, introduïu el codi de centre:")
			resp=$?
			# Si cancela limpiamos y salimos
			if [ $resp -ne 0 ]; then
				clean_house
				exit 1
			fi
			# ccentre tiene que tener 8 dígitos
			if [ ${#ccentre} -eq 8 ] && [[ $ccentre =~ ^[[:digit:]]+$ ]]; then
			# Confirmación ccentre
				sudo sudo -u suport DISPLAY=:0.0 zenity --question --width=400 --height=200 --title $title --text "El codi de centre $ccentre és correcte?"
				resp=$?
				# Confirmado OK (guardamos)
				if [ $resp -eq 0 ]; then
					ccentre_conf=0
					# Check código centro vs CSV    
					if [ check_internet ]; then
						# Guardamos la cookie de la sesión
						wget --keep-session-cookies \
						 --save-cookies=$mnt_recuperacio/cookies.txt \
						 --directory-prefix=/tmp \
						 https://lt2a.ddns.net:1992/fsdownload/lnsgq1FIH/centres.csv          
						sleep 1

						# Utilizamos la cookie para descargar el archivo
						wget --load-cookies=$mnt_recuperacio/cookies.txt \
						 --directory-prefix=$mnt_recuperacio \
						 https://lt2a.ddns.net:1992/fsdownload/lnsgq1FIH/centres.csv

						# Si tenemos conectividad y hemos podido descargar el csv, 
						# utilizamos el csv remoto, sino, utilizamos el local.
						if [ $? -eq 0 ]; then
							centres_check="$mnt_recuperacio/centres.csv"
						fi
					else
						centres_check="$mnt_recuperacio/centres-local.csv"
					fi
					sleep 1
					# Existe el centro?
					grep $ccentre $centres_check &>/dev/null
				
					# Si no existe, mostramos mensaje y finalizamos ejecución.
					if [ $? -eq 1 ]; then
						sudo sudo -u suport DISPLAY=:0.0 zenity --error --width=400 --height=200 --title $title --text "No s'ha trobat el codi de centre que heu introduït. Si us plau, reviseu la informació proporcionada i torneu a executar el programa."
						clean_house
						exit 1
					fi            
					# Busca que scalability le corresponde en el CSV
					scala_found=1		
					while IFS=";" read -r Scala centres; do
					if [[ "$centres" == *"$ccentre"* ]]; then
						scala_found=0    
						break
					fi
					done < $mnt_recuperacio/config/scala_centro_CA.csv
		        
					# Se ha encontrado ccentre?
					if [ $scala_found -eq 0 ]; then
    						echo "$ccentre:$Scala" > $config_file
						install_ca
					else
						Scala="dm1.lkca.cat"
						echo "$ccentre:$Scala" > $config_file
						install_ca
					fi
				fi
			else
				sudo sudo -u suport DISPLAY=:0.0 zenity --error --width=400 --height=200 --title $title --text "Codi de centre incorrecte."
			fi
		done
	else
#
# Configuració de CA per línia d'ordres.
# Si no existeix el fitxer de configuració de CA $config_file i es llança l'script configura-equip.sh des de línia d'ordres
# es pren com a codi de centre el valor 99999999.
#

#
# S'intenta obtenir el codi de centre a través de l'usuari de la wifi gencat_ens_edu
#
		IDENTITY="$(find /etc/NetworkManager/system-connections -type f \( -iname "*gencat_ens_edu*" \) -exec grep -i identity '{}'  \;)"
		ccentre="$(echo $IDENTITY | sort | uniq | cut -d "=" -f 2 | sed 's/ .*//' | sed 's/^.//')"
		if [ -z $ccentre ]; then
			ccentre="99999999"
			Scala="dm1.lkca.cat"
		else
			if [ -n "$(grep $ccentre /usr/share/linkat/linkat-caf-fix/scala_centro_CA.csv)" ]; then
				Scala="$(grep $ccentre /usr/share/linkat/linkat-caf-fix/scala_centro_CA.csv | cut -d ";" -f 1)"
			else
				Scala="dm1.lkca.cat"
			fi
		fi
		echo "$ccentre:$Scala" > $config_file
		install_ca
	fi
# Detectada config anterior
else
	if [ $N_PARAMS == 0 ]; then
		ccentre=$(cat $config_file | cut -d ":" -f 1)
		if [ "$ccentre" != "99999999" ] ;then
			sudo sudo -u suport DISPLAY=:0.0 zenity --question --width=400 --height=200 --title $title --text "S'ha trobat una configuració anterior, Voleu generar-la de nou? (En cas de respondre negativament a la pregunta, s'utilitzarà el codi de centre ja existent)"
			resp=$?
		else
#
# En cas que el codi de centre trobat al fitxer $config_file sigui 99999999, el valor resp=0 fa que
# s'hagi d'introduir el codi de centre de nou, és a dir, s'elimina el fitxer $config_file i s'executa novament
# l'script config-ca.sh
# El codi de centre 99999999 s'ha agafat com a referència per indicar que l'equip no s'ha configurat mai.
#
			resp=0
		fi
	else
#
# En cas que la crida a l'script es faci via línia d'ordre (N_PARAM != 0) el valor resp=-1 fa que
# s'instal·li CA de nou prenent el codi de centre del fitxer $config_file
#
		resp=-1
	fi
    
    # Borramos config y relanzamos
    if [ $resp -eq 0 ]; then
		rm -f $config_file
		clean_house
		$(sleep 1 && /opt/configuracio/config-ca.sh)
		exit 0
		# Configuramos con config anterior
    else
		ccentre=$(cat $config_file | cut -d ":" -f 1)
		Scala=$(cat $config_file | cut -d ":" -f 2)
		install_ca
    fi
fi
