#!/bin/bash
if [ -z "$(grep "VERSIOMQ\|LK-EDC" /etc/environment)" ]; then
        exit 0
fi
if [ "$(id -u)" != 0 ]; then
	exit 0
fi
if [ ! -e /etc/linkat-reassigna-equip-edc ]; then
	U_ALTA=u-alta
	if [ -e /etc/lightdm/lightdm.conf ]; then
		if [ -z "$(grep autologin /etc/lightdm/lightdm.conf)" ] && [ -n "$(id -un $U_ALTA 2>/dev/null)" ]; then
			/usr/sbin/userdel -r "$U_ALTA" > /dev/null 2>&1
		fi
	fi
fi
exit 0
