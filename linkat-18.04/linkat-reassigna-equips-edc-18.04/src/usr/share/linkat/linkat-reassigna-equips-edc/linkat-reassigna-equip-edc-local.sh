#!/bin/bash
#
if [ -n "$(pidof -s caf)" ]; then
	. /etc/profile.CA all
	sd_acmd AddInstallRecord " linkat-reassigna-equip-edc-local " "V1.0" "install" current current "" "" >/dev/null 2>&1
	caf start amagent sdagent >/dev/null 2>&1
fi
