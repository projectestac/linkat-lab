#!/bin/bash


#fusermount -u /var/backup-institut

GD=$(which google-drive-ocamlfuse)
CONTROL=".linkat-drive"
GDFUSE_DIR=.gdfuse
CONFIGURACIO="$HOME/$CONTROL"
PROFILE=linkat-default

configure_gdfuse_dir ()
{
	zenity --info --width=300 --text="Seleccioneu el <b>directori</b> que voleu enllaçar amb Google Drive."
	if [ -e "$CONFIGURACIO" ]; then
		CARPETA_ANTIGA="$(cat "$CONFIGURACIO")"
		if [ -n "$( mount |grep "$CARPETA_ANTIGA")" ]; then
			fusermount -u "$CARPETA_ANTIGA"
		fi
	fi
	CARPETA_CLOUD="$(zenity --file-selection --width=300 --title "Escolliu un directori:" --directory)"
	if [ -z "$CARPETA_CLOUD" ]; then
		zenity --width=300 --info --text "Heu de seleccionar un <b>directori</b>. Torneu a executar el programa"
		exit 0
	fi
	if [ -n "$(mount |grep "$CARPETA_CLOUD")" ]; then
		fusermount -u "$CARPETA_CLOUD"
	fi
	if [ -d "$CARPETA_CLOUD" ] && [ -n "$(ls -A "$CARPETA_CLOUD")" ]; then
		zenity --width=300 --info --text "La carpeta <b>$CARPETA_CLOUD</b> no està buida. No es pot escollir aquest directori."
		exit 0
	fi
	echo "$CARPETA_CLOUD" > "$CONFIGURACIO"
}

optimize_gdfuse()
{
	if [ -e "$HOME/$GDFUSE_DIR/$PROFILE/config" ]; then
		sed -i 's/max_cache_size_mb=512/max_cache_size_mb=2048/g' "$HOME/$GDFUSE_DIR/$PROFILE/config"
		sed -i 's/metadata_cache_time=60/metadata_cache_time=180/g' "$HOME/$GDFUSE_DIR/$PROFILE/config"
		sed -i 's/write_buffers=false/write_buffers=true/g' "$HOME/$GDFUSE_DIR/$PROFILE/config"
		sed -i 's/async_upload_queue=false/async_upload_queue=true/g' "$HOME/$GDFUSE_DIR/$PROFILE/config"
		sed -i 's/metadata_memory_cache_saving_interval=30/metadata_memory_cache_saving_interval=60/g'	"$HOME/$GDFUSE_DIR/$PROFILE/config"	
		sed -i 's/background_folder_fetching=false/background_folder_fetching=true/g' "$HOME/$GDFUSE_DIR/$PROFILE/config"
#		sed -i 's/async_upload_threads=10/async_upload_threads=20/g' "$HOME/$GDFUSE_DIR/$PROFILE/config"
	fi
}

# main ()

if [ -d "$HOME/$GDFUSE_DIR" ] && [ -n "$(ls -A "$HOME/$GDFUSE_DIR")" ] && [ -e "$CONFIGURACIO" ]; then
	zenity --question --width=300 --title="Pregunta?" --text="El client de <b>Google Drive</b> ja es troba configurat.\n\r\
Voleu tornar-lo a configurar?"
   case $? in
   0)
	if [ -d "$HOME/$GDFUSE_DIR" ] && [ -n "$(ls -A "$HOME/$GDFUSE_DIR")" ]; then
		zenity --question --width=300 --title="Pregunta?" --text="Voleu canviar el compte de <b>Google Drive?</b>"
		if [ "$?" == "0" ]; then
			rm -rf "$HOME/$GDFUSE_DIR"/*
			$GD -label $PROFILE
			zenity --info --width=300 --text="Ja podeu tancar el <b>navegador web</b>."
			configure_gdfuse_dir
			optimize_gdfuse
			CARPETA_CLOUD="$(cat "$CONFIGURACIO")"
			$GD -cc -label $PROFILE "$CARPETA_CLOUD"
			zenity --width=300 --info --text "Aneu al directori <b>$CARPETA_CLOUD</b> per veure els fitxers que heu compartit al Google Drive."
		else
			configure_gdfuse_dir
			$GD -cc -label $PROFILE "$CARPETA_CLOUD"
			zenity --width=300 --info --text "Aneu al directori <b>$CARPETA_CLOUD</b> per veure els fitxers que heu compartit al Google Drive."
		fi
	fi
   ;;
   *)
	zenity --info --width=200 --text="S'ha cancel·lat la configuració."
   ;;
   esac
else
	zenity --info --width=300 --text="Configuració del client de <b>Google Drive</b>."
	$GD -label $PROFILE
	zenity --info --width=300 --text="Ja podeu tancar el <b>navegador web</b>."
	configure_gdfuse_dir
	optimize_gdfuse
	CARPETA_CLOUD="$(cat "$CONFIGURACIO")"
	$GD -cc -label $PROFILE "$CARPETA_CLOUD"
	zenity --width=300 --info --text "Aneu al directori <b>$CARPETA_CLOUD</b> per veure els fitxers que heu compartit al Google Drive."
fi
exit 0
