#!/bin/bash

static=EDUA
dynamic=$(sudo dmidecode -s system-serial-number)
name=$static$dynamic
N_PARAMS=$#
sed -i s/maqueta/$name/g /etc/hosts
hostnamectl set-hostname $name
[[ $N_PARAMS == 0 ]] && sleep 3 | tee >(sudo sudo -u suport DISPLAY=:0.0 zenity --progress --pulsate --no-cancel --auto-close --text="Canviant el nom del equip..." 2>/dev/null)
