#!/bin/bash
if [ "$(id -u)" != 0 ]; then
	exit 0
fi
U_ALTA=u-alta
G_ALTA=users
if [ -e /etc/lightdm/lightdm.conf ]; then	
	if [ $# -eq 0 ]; then
		if [ -n "$(grep autologin /etc/lightdm/lightdm.conf)" ]; then
			sed -i '/autologin/d' /etc/lightdm/lightdm.conf
		fi
		if [ -n "$(id -un $U_ALTA 2>/dev/null)" ]; then
			/usr/sbin/userdel -r "$U_ALTA" > /dev/null 2>&1
			sleep 1
		fi
	else
		if [ -z "$(grep autologin /etc/lightdm/lightdm.conf)" ]; then
			echo "autologin-user=$U_ALTA" >> /etc/lightdm/lightdm.conf
			echo "autologin-timeout=0" >> /etc/lightdm/lightdm.conf
		fi
		if [ -z "$(id -un $U_ALTA 2>/dev/null)" ]; then
			/usr/sbin/useradd -m -N -g users -r -s /bin/bash $U_ALTA  > /dev/null 2>&1       
			PASSWD_U_ALTA="$(date +%s | sha256sum | base64 | head -c 32)"
			HOME_U_ALTA=$(getent passwd "$U_ALTA" |cut -d ":" -f 6)
			echo -e "$PASSWD_U_ALTA\n$PASSWD_U_ALTA" | passwd "$U_ALTA" > /dev/null 2>&1
			chage -I -1 -m 0 -M 99999 -E -1 "$U_ALTA" > /dev/null 2>&1
			tar -zxf /usr/share/linkat/linkat-reassigna-equips-edc/u-alta.tar.gz --directory="$HOME_U_ALTA" > /dev/null 2>&1
			chown -R $U_ALTA:$G_ALTA "$HOME_U_ALTA"
			chmod 700 "$HOME_U_ALTA"
		fi
	fi
fi
exit 0



