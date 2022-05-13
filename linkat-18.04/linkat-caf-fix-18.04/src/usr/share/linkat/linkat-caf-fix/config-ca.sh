#!/bin/bash

mnt_recuperacio="/opt/configuracio/mnt-recuperacio"
config_file="$mnt_recuperacio/config/config-ca"
title="Configuració CA"

# Instala y configura CA
function install_ca {
    # Install
    CODICENTRE=$ccentre
    sleep 2 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Instal·lant CA..." 2>/dev/null)
    cd /opt/configuracio/CA
    ./installdsm -bg -r install.rsp /RITM_SERVER=127.0.0.1 2>&1
    sleep 2 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Finalitzant instal·lació..." 2>/dev/null)
    cd /opt/configuracio
    # Config
    . /etc/profile.CA all
    caf setserveraddress $Scala novalidate
    caf restart
    caf register all 
    caf start amagent args /rescan_inventory /rescan_software /collect
    # Reportamos un paquete inexistente con el código de centro
    sd_acmd AddInstallRecord "Centre" $CODICENTRE "install" current current "Imatge" ""
    sleep 2 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Configurant CA..." 2>/dev/null)
    sleep 5 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="L'equip es reiniciarà per a desar la nova configuració..." 2>/dev/null)
    clean_house
    reboot
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

    umount $mnt_recuperacio
}


# Requerimos ejecución como root
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    sudo sudo -u suport DISPLAY=:0.0 zenity --error --width=400 --height=200 --title $title --text "Si us plau torna a executar-ho com a usuari root."
    exit 1
fi

mount /dev/mmcblk0p3 $mnt_recuperacio

# Config nueva (no existe archivo)
if [ ! -f $config_file ]; then
    ccentre_conf=1	
	
    # Mientras no se confirme o cancele, pedimos ccentre
    while [ $ccentre_conf -ne 0 ]; do
        ccentre=$(sudo sudo -u suport DISPLAY=:0.0 zenity --entry --width=400 --height=200 --title $title --text "Si us plau introdueixi el codi de centre:")
        resp=$?

	# Si cancela limpiamos y salimos
	if [ $resp -ne 0 ]; then
	    clean_house
	    exit 1
	fi

        # ccentre tiene que tener 8 dígitos
        if [ ${#ccentre} -eq 8 ] && [[ $ccentre =~ ^[[:digit:]]+$ ]]; then
            # Confirmación ccentre
	    sudo sudo -u suport DISPLAY=:0.0 zenity --question --width=400 --height=200 --title $title --text "El codi de centre $ccentre es correcte?"
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
                    sudo sudo -u suport DISPLAY=:0.0 zenity --error --width=400 --height=200 --title $title --text "No s'ha trobat el codi de centre introduït, si us plau revisa la informació i torna-ho a executar."
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

# Detectada config anterior
else
    sudo sudo -u suport DISPLAY=:0.0 zenity --question --width=400 --height=200 --title $title --text "S'ha trobat una configuració anterior, Vol generar-la de nou? (En cas negatiu es reconfigurarà utilitzant les dades anteriors)"
    resp=$?
	    
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
