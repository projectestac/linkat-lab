#!/bin/bash
#
# Control de l'aplicatiu CONKY - MAQUETA CORPORATIVA LINKAT
# AUTOR: Joan de Gracia
# Àrea de CULTURA DIGITAL
# DEPARTAMENT D'EDUCACIÓ
# 2022/07/19
# LLICÈNCIA GPL 3.0 O SUPERIOR
# VERSIÓ 1.0
#
CONKY_CONTROL="$HOME"/.conky_control
CONKY_CONF=/etc/conky/linkat-conky-corporatiu.conf
CONKY=$(which conky)
if [ ! -e "$CONKY_CONTROL" ]; then
	xdpyinfo |grep dimensions > "$CONKY_CONTROL"
fi
PID_CONKY_SHELL=$$
renice -n 19 $PID_CONKY_SHELL
PID_CONKY_BIN="$(pidof $CONKY)"
if [ -z "$PID_CONKY_BIN" ]; then
	nice -n 19 $CONKY -c $CONKY_CONF >/dev/null 2>&1 &
else
	renice -n 19 -p $PID_CONKY_BIN
fi
sleep 5
while true
do
	CONKY_RESOLUTION="$(xdpyinfo |grep dimensions)"
	if [ -z "$(grep "$CONKY_RESOLUTION" $CONKY_CONTROL)" ]; then
		kill $(pidof conky)
		echo "$CONKY_RESOLUTION" > $CONKY_CONTROL
		nice -n 19 $CONKY -c $CONKY_CONF >/dev/null 2>&1 &
	fi
	sleep 1m
done
exit 0

