#!/bin/bash
#
if [ -e /etc/linkat-reassigna-equip-edc ]; then
	ANY_CONTROL="$(stat -c %y /etc/linkat-reassigna-equip-edc|cut -d "-" -f 1)"
	ANY="$(date +%Y)"
	if [[ "$ANY" != "$ANY_CONTROL" ]]; then
		rm /etc/linkat-reassigna-equip-edc
		exit 0
	fi
	MES=$(date +%m)
	MES_I="07" # JULIOL
	MES_F="09" # SETEMBRE
	if [ $MES -ge $MES_I ] && [ $MES -le $MES_F ]; then
		if [ ! -s "/etc/linkat-reassigna-equip-edc" ]; then
			WIFI="0"
		else
			WIFI="1"
		fi
		/usr/share/linkat/linkat-reassigna-equips-edc/linkat-reassigna-equip-sistema.sh "$WIFI"
		rm /etc/linkat-reassigna-equip-edc
	#	/sbin/init 0
		systemctl poweroff --force
	fi
	if [ $MES -gt $MES_F ]; then
		rm /etc/linkat-reassigna-equip-edc
	fi
fi
exit 0
