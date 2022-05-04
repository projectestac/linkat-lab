#!/bin/bash

#################################################################
#       Nom del script: linkat-reassigna-equip.sh               #
#       Versió 1.0                                              #
#       Autor: Joan de Gracia                                   #
#       Projecte Linkat                                         #
#       Àrea de Cultura Digital - Departament d'Educació        #
#       Data: 2022/04/05                                        #
#       Llicència GPL 3.0                                       #
#       Dependències:                                           #
#                                                               #
#################################################################

if [ -z "$(grep "VERSIOMQ\|LK-EDC" /etc/environment)" ]; then
        exit 0
fi

if [ "$(id -u)" != 0 ]; then
	exit 0
fi
ZENITY="$(which zenity)"
$ZENITY --width=500 --question --text="Esteu a punt de començar el <b>procés de reassignació</b> d'aquest equip.\n\
\n\
Durant aquest procés es duran a terme les accions següents:\n\
\n\
- <b>S'eliminaran</b> tots els usuaris de l'equip.\n\
\n\
- <b>S'activarà el mode d'autoservei</b>.\n\n\
En aquest mode, l'alumne/a podrà donar-se d'alta de forma autònoma a l'equip.\n\n\
Caldrà que l'alumne/a disposi del seu nom d'usuari (<b>IDALU</b>) i contrasenya que s'obtenen de l'aplicació <b>IDI</b>.\n\
\n\
Voleu continuar?"
if [ "$?" != "1" ]; then
	if [ -z "$(grep autologin /etc/lightdm/lightdm.conf)" ]; then
		if [ "$(hostname -I)" == "" ]; then
			$ZENITY --width=500 --question --text="No teniu l'equip connectat a la xarxa wifi.\n\n\
Abans de continuar cal que connecteu l'equip a alguna de les xarxes wifi educatives del centre:\n\n\
<b>gencat_ENS_EDU, gencat_ENS_EDU_PORTAL, docent, GencatPEDC</b>.\n\n\
Voleu <b>cancel·lar</b> el procés de reassignació de l'equip?"
			if [ "$?" != "1" ]; then
				$ZENITY --width=300 --info --text="Procés cancel·lat"
				exit 0
			fi
		fi
		WIFI_CENTRE_CHECK="$(find /etc/NetworkManager/system-connections -type f \( -iname "*gencat*" -or -iname "*docent*" \))"
		if [ -z "$WIFI_CENTRE_CHECK" ]; then
			$ZENITY --width=500 --question --text="No heu configurat l'equip amb la xarxa wifi educativa del centre.\n\
Les wifis educatives del centre tenen algun dels identificadors (SSID) següents:\n\n\
<b>gencat_ENS_EDU\n\
gencat_ENS_EDU_PORTAL\n\
docent</b>\n\n\
Abans de continuar, <b>cal que configureu i connecteu l'equip a la xarxa wifi educativa del centre</b>.\n\n\
Voleu <b>cancel·lar</b> el procés de reassignació de l'equip?"
			if [ "$?" != "1" ]; then
				$ZENITY --width=300 --info --text="Procés cancel·lat"
				exit 0
			fi
		fi
		$ZENITY --width=500 --question --text="Voleu que l'alumne/a pugui gestionar la connexió d'aquest equip a la <b>xarxa wifi del centre</b>?\n\n\
Si responeu <b>afirmativament</b>, l'alumne/a podrà modificar la connexió wifi del seu equip i <b>veure la contrasenya</b> de la xarxa wifi del centre.\n\n\
<b>En cas contrari, l'alumne/a no veurà la contrasenya de la wifi del centre.\
Tingueu en compte que l'alumne tampoc podrà modificar la configuració de la xarxa wifi del centre.</b>"
		if [ "$?" != "1" ]; then
			WIFI="1"
		else
			WIFI="0"
		fi
		/usr/share/linkat/linkat-reassigna-equips-edc/linkat-reassigna-equip-sistema.sh "$WIFI"
#
# Si l'equip es reassigna localment, es registrarà a CA.
#
		/usr/share/linkat/linkat-reassigna-equips-edc/linkat-reassigna-equip-edc-local.sh >/dev/null 2>&1
		if [ -e /var/log/linkat-autoservei-usuari.log ]; then
			rm /var/log/linkat-autoservei-usuari.log
		fi
#
		$ZENITY --width=400 --info --text="Tot seguit, l'equip <b>s'aturarà.</b>\n\n\
Quan arrenqui de nou l'ordinador, l'alumne/a podrà donar-se d'alta en aquest equip."
#		/sbin/init 0
		systemctl poweroff --force
	else
		$ZENITY --width=400 --info --text="S'ha <b>cancel·lat</b> el procés de reassignació de l'equip.\n\n\
Si voleu <b>reassignar-lo</b> de nou, cald que torneu a executar aquest aplicatiu."
		/usr/share/linkat/linkat-reassigna-equips-edc/linkat-lightdm-autologin.sh
	fi
else
	$ZENITY --width=300 --info --text="Procés cancel·lat"
fi
exit 0
