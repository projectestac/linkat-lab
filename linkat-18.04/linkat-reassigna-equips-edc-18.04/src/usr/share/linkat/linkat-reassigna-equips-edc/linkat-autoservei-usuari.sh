#!/bin/bash
if [ -z "$(grep "VERSIOMQ\|LK-EDC" /etc/environment)" ]; then
        exit 0
fi
ZENITY="$(which zenity)"
source "$HOME"/.config/user-dirs.dirs
gsettings set org.gnome.settings-daemon.plugins.media-keys terminal "['']"
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['']"
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "['']"
sleep 2
if [ -d "$XDG_DESKTOP_DIR" ]; then
	rm -rf "$XDG_DESKTOP_DIR"/*
fi
$ZENITY --width=400 --info --text="Tingueu a prop el vostre <b>nom d'usuari/a (IDALU)</b> \
i <b>contrasenya</b> que el centre educatiu us ha proporcionat per donar-vos d'alta en aquest equip."
sudo /usr/share/linkat/linkat-reassigna-equips-edc/linkat-alta-usuaris-edc.sh
FLAG=0
for id_usuari in $(getent passwd |cut -d ":" -f 3)
do
	if [ "$id_usuari" -gt 1000 ] && [ "$id_usuari" -le 60000 ]; then
		USUARI="$(id -un "$id_usuari")"
		FLAG=1
	fi
done
if [ "$FLAG" == "1" ]; then
#
# Es deixa registre de l'usuari que s'ha donat d'alta a l'equip.
#
	if [ -d /opt/configuracio ]; then
		sudo /usr/share/linkat/linkat-reassigna-equips-edc/linkat-reassigna-equip-marca.sh "$USUARI"
	fi
	sudo /usr/share/linkat/linkat-reassigna-equips-edc/linkat-lightdm-autologin.sh
	zenity --width=400 --info --text "Us heu donat d'alta <b>correctament</b> en aquest equip.\n\n\
Tot seguit l'equip <b>es tancarà</b>."
else
	zenity --width=400 --info --text "Procés cancel·lat.\n\n\
Tot seguit l'equip <b>es tancarà</b> l'equip."
fi
#sudo /sbin/init 0
sudo systemctl poweroff --force
