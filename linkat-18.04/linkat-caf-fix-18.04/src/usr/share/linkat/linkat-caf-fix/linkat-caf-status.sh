#!/bin/bash
ZENITY=$(which zenity)

if [[ $(id -u) -ne 0 ]]; then
	$ZENITY --width=400 --info --text="No sou usuari <b>root</b> de l'ordinador."
	exit 0
fi

if [[ -f /etc/profile.CA ]] && [[ -d /opt/CA ]]; then
	$ZENITY --width=400 --question --text="Aquest programa permet veure l'estat de l'agent de CA. \n \r \
Tingueu en compte que la informació de l'agent de CA <b>pot trigar uns segons</b> en mostrar-se. \n \r \
Voleu continuar? \n \r \
Responeu <b>No</b> si no n'esteu segurs?"
	if [ "$?" != "1" ]; then
		. /etc/profile.CA all
		PIDOF_CAF=$(pidof caf)
		if [ -n "$PIDOF_CAF" ]; then
			CAF_OUT=$(caf setserveraddress 2>&1)
			if [ -n "$(grep "running ok" <<< $CAF_OUT)" ]; then
				zenity --width=400 --info --text="<b>L'agent de CA funciona correctament. \n\r \
La informació que proporciona l'agent de CA és la següent:</b> \n\r \
$(grep running\ ok <<< $CAF_OUT)"
			else
				zenity --width=600 --info --text="<b>L'agent de CA funciona tot i que sembla que hi hagi \
algun problema amb la configuració per accedir al servidor de CA. \n \r \
La sortida que proporciona l'agent de CA és la següent:</b> \n \r \
$CAF_OUT"
			fi
		else
			CAF_MESSAGE=$(caf status)
			zenity --width=400 --info --text="<b>L'agent de CA està aturat.\n\r \
El missatge de sortida de l'agent de CA és el següent:</b> \n\r \
$CAF_MESSAGE"
		fi
	else
		zenity --width=300 --info --text="Heu tancat el programa."
	fi
else
	zenity --width=300 --info --text="<b>L'agent de CA no està configurat.</b>"
fi
exit 0
