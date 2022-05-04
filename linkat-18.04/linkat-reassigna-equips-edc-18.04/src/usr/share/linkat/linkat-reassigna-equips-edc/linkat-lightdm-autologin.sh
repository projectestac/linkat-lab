#!/bin/bash
if [ -z "$(grep "VERSIOMQ\|LK-EDC" /etc/environment)" ]; then
        exit 0
fi

if [ "$(id -u)" != 0 ]; then
	exit 0
fi
U_ALTA=u-alta
if [ -e /etc/lightdm/lightdm.conf ]; then
	if [ -z "$(grep autologin /etc/lightdm/lightdm.conf)" ]; then
		echo "autologin-user=$U_ALTA" >> /etc/lightdm/lightdm.conf
		echo "autologin-timeout=0" >> /etc/lightdm/lightdm.conf
	else
		sed -i '/autologin/d' /etc/lightdm/lightdm.conf
	fi
fi
exit 0
