#!/bin/bash
if [ "$(id -u)" != 0 ]; then
	exit 0
fi
if [ -e /etc/NetworkManager/NetworkManager.conf ]; then
	if [ $# -eq 0 ]; then
		if [ -n "$(grep auth-polkit\=false /etc/NetworkManager/NetworkManager.conf)" ]; then
			sed -i '/auth-polkit/d' /etc/NetworkManager/NetworkManager.conf
		fi
	else
		if [ -z "$(grep auth-polkit\=false /etc/NetworkManager/NetworkManager.conf)" ]; then
			sed -i '/main/a auth-polkit=false' /etc/NetworkManager/NetworkManager.conf
		fi
	fi
fi
exit 0
