#!/bin/bash
USUARI="$1"
echo "$USUARI" > /opt/configuracio/linkat-reassigna-equip-usuari-principal.log
touch /opt/configuracio/linkat-reassigna-equip-usuari-principal-flag
