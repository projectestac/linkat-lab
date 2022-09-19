#!/bin/bash
DCONF=$(which dconf)
GNOME_SESSION_QUIT=$(which gnome-session-quit)
ZENITY=$(which zenity)
$ZENITY --width=400 --question --text="Esteu a punt d'iniciar l'assistent \
per restaurar el vostre escriptori.\n\r
Voleu continuar?"
if [ "$?" != "1" ]; then
$ZENITY --width=400 --question --text="Voleu restaurar la configuració del \
navegador Firefox?"
if [ "$?" != "1" ]; then
	if [ -d "$HOME"/.mozilla ]; then
		killall -s TERM firefox >/dev/null 2>&1
		rm -rf "$HOME"/.mozilla
	fi
fi
$ZENITY --width=400 --question --text="Voleu restaurar la configuració del \
navegador Chromium?"
if [ "$?" != "1" ]; then
	if [ -d "$HOME"/.config/chromium ]; then
		killall -s TERM chromium-browser >/dev/null 2>&1
		rm -rf "$HOME"/.config/chromium
	fi
fi
$ZENITY --width=400 --question --text="Voleu reiniciar les claus del gestor de claus? \n
Responeu <b>No</b> si no n'esteu segurs?"
if [ "$?" != "1" ]; then
	if [ -d "$HOME"/.local/share/keyrings ]; then
		rm -rf "$HOME"/.local/share/keyrings
	fi
fi
$ZENITY --width=400 --question --text="Voleu restaurar la configuració del \
vostre escriptori?\n\r
Us recomanem que tanqueu totes les aplicacions que teniu obertes.\n\r
Quan acabi la restauració, es tancarà \
la sessió i haureu de tornar a entrar-hi de nou.\n\r"
if [ "$?" != "1" ]; then
	$DCONF reset -f /
	$GNOME_SESSION_QUIT --logout --force --no-prompt
fi
fi
exit 0
