#!/bin/bash
GD=$(which google-drive-ocamlfuse)
CONTROL=".linkat-drive"
CONFIGURACIO="$HOME"/$CONTROL
GDFUSE_DIR=.gdfuse
PROFILE=linkat-default
if [ ! -d "$HOME/$GDFUSE_DIR" ] || [ -z "$(ls -A "$HOME/$GDFUSE_DIR")" ] || [ ! -e "$CONFIGURACIO" ]; then
	zenity --width=300 --info --text "No teniu el client de <b>Google Drive</b> configurat."
	exit 0
fi
if [ -e "$CONFIGURACIO" ]; then
	CARPETA_CLOUD="$(cat "$CONFIGURACIO")"
	if [ -d "$CARPETA_CLOUD" ]; then
		if [ -n "$( mount |grep "$CARPETA_CLOUD")" ] ; then
			fusermount -u "$CARPETA_CLOUD"
			zenity --width=300 --info --text "S'ha desconnectat la carpeta <b>$CARPETA_CLOUD</b> del vostre compte de <b>Google Drive</b>."
			exit 0
		fi
		if [ -n "$(ls -A "$CARPETA_CLOUD")" ]; then
			zenity --width=300 --info --text "La carpeta <b>$CARPETA_CLOUD</b> no està buida i no es pot utilitzar."
			exit 0
		fi
	fi
	$GD -cc -label $PROFILE "$CARPETA_CLOUD"
	zenity --width=300 --info --text "Heu connectat la carpeta <b>$CARPETA_CLOUD</b> amb el vostre compte de <b>Google Drive</b>."
fi
exit 0
