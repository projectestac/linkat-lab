#!/bin/bash
if [ "$(id -u)" != 0 ]; then
	exit 0
fi
if [ -z "$(grep "VERSIOMQ\|LK-EDC" /etc/environment)" ]; then
        exit 0
fi
#
# Si existeix la wifi educaendigital, es canvia l'atribut del fitxer i s'elimina
#
if [ -e /etc/NetworkManager/system-connections/educaendigital ]; then
	chattr -i /etc/NetworkManager/system-connections/educaendigital
	rm /etc/NetworkManager/system-connections/educaendigital
fi
#
# S'eliminen totes les xarxes que no siguin GENCAT/DOCENT
# 
find /etc/NetworkManager/system-connections -type f \( ! -iname "*gencat*" ! -iname "*docent*" \) -exec rm -rf '{}' \;
#
# Es modifica la configuració de les xarxes GENCAT/DOCENT per compartir les wifis entre els usuaris de l'ordinador.
#
find /etc/NetworkManager/system-connections -type f \( -iname "*gencat*" -or -iname "*docent*" \) -exec sed -i '/permissions/c\permissions=' '{}' \;
#
if [ $# -eq 0 ]; then
	WIFI="0"
else
	WIFI="$1"
fi
if [ -e /etc/NetworkManager/NetworkManager.conf ]; then
	if [[ $WIFI == 1 ]]; then
		if [ -z "$(grep auth-polkit\=false /etc/NetworkManager/NetworkManager.conf)" ]; then
			sed -i '/main/a auth-polkit=false' /etc/NetworkManager/NetworkManager.conf
		fi
	else
			sed -i '/auth-polkit/d' /etc/NetworkManager/NetworkManager.conf
	fi
fi
systemctl reload NetworkManager >/dev/null 2>&1
U_ALTA=u-alta
G_ALTA=users
if [ -n "$(id -un $U_ALTA 2>/dev/null)" ]; then
	/usr/sbin/userdel -r "$U_ALTA" > /dev/null 2>&1
	sleep 1
fi
/usr/sbin/useradd -m -N -g users -r -s /bin/bash $U_ALTA  > /dev/null 2>&1       
PASSWD_U_ALTA="$(date +%s | sha256sum | base64 | head -c 32)"
HOME_U_ALTA=$(getent passwd "$U_ALTA" |cut -d ":" -f 6)
echo -e "$PASSWD_U_ALTA\n$PASSWD_U_ALTA" | passwd "$U_ALTA" > /dev/null 2>&1
chage -I -1 -m 0 -M 99999 -E -1 "$U_ALTA" > /dev/null 2>&1
tar -zxf /usr/share/linkat/linkat-reassigna-equips-edc/u-alta.tar.gz --directory="$HOME_U_ALTA" > /dev/null 2>&1
chown -R $U_ALTA:$G_ALTA "$HOME_U_ALTA"
chmod 700 "$HOME_U_ALTA"
sleep 1
/usr/share/linkat/linkat-reassigna-equips-edc/linkat-lightdm-autologin.sh
for id_usuari in $(getent passwd |cut -d ":" -f 3)
do
	if [ "$id_usuari" -gt 1000 ] && [ "$id_usuari" -le 40000 ]; then
		USUARI="$(id -un "$id_usuari")"
		/usr/sbin/userdel -r "$USUARI" > /dev/null 2>&1
	fi
done
#
# S'eliminen els fitxers d'usuari del directori /etc/sudoers.d
#
find /etc/sudoers.d -type f -iname "99-linkat-a*" -exec rm -rf {} \;
exit 0
