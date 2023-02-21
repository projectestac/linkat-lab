#!/bin/bash


alumne=""
alumnePass=""
alumnePassCheck=""
adminUser="$(getent passwd 1000 | cut -d : -f 1)"
res=""
findUsers="$(awk -F : '$3 >= 1000 && $3 <= 40000' /etc/passwd | cut -d ":" -f 1 | grep -v 'nobody\|suport')"
usersArrayCheck=${#findUsersCheck[@]}
usersArray=${#findUsers[@]}
appAltaAlu="Linkat | Alta d'alumnat"
appPassAdm="Linkat | Contrasenya Administrador"


SUCCESS=0
E_USEREXISTS=70
ERROR=1


yad() {
    /usr/bin/yad "$@" 2>/dev/null
}

check_conn()
{
        nc -z -v -w5 google.com 443 &>/dev/null
        if [ $? -eq 0 ]; then
                #connection="1"
                echo "Connection OK"
        else
                yad \
                --title="${appAltaAlu}" \
                --center --width="320" --height="110" --borders=15 --info --button=gtk-ok:1 \
                --image="gtk-help" \
                --text="\n<b>L'equip no està connectat a Internet</b>\nSi us plau, revisa la configuració de xarxa.\n" \
                --text-align=center 2>/dev/null \
                exit 12
        fi
}

banner_init_admin()
{
        yad \
        --title="${appPassAdm}" \
        --image="gtk-dialog-info" \
        --center \
        --borders=20 \
        --fixed \
        --width=100 \
        --height=100 \
        --text-align=left \
        --text="Voleu canviar la contrasenya de l'usuari <b>$adminUser</b>?" \
        --button=Si:0 \
        --button=No:11
res=$?
        if [ $res -eq 11 ]; then
		exit 12
	fi
}


banner_init()
{
        yad \
        --title="${appAltaAlu}" \
        --image="gtk-dialog-info" \
        --center \
        --borders=20 \
        --fixed \
        --width=100 \
        --height=100 \
        --text-align=left \
        --text="Aquest és el formulari d'alta d'alumnat al sistema Linkat.\n Voleu afegir un/a alumne/a a la Linkat?" \
        --button=Si:10 \
        --button=No:1
res=$?
        if [ $res -eq 1 ]; then
               exit 12 
        fi
}


deleteUser ()
{
        #grep -wq "$1" /etc/passwd
                if [ $? -eq 0 ];then

                        if      yad \
                                --title="${appAltaAlu}" \
                                --image "dialog-question" \
                                --center \
                                --borders=20 \
                                --fixed \
                                --width=400 \
                                --height=300 \
                                --button="D'acord" \
                                --button="Cancel·la":11 \
                                --text="Es procedirà a esborrar l'usuari/a <b>$1</b> i totes les seves dades. Voleu confirmar aquesta acció?"
                        then
                                sudo userdel $1
                                if [ -e /home/$1 ]; then
                                        sudo rm -r /home/$1
                                fi

                                if [ -e /etc/sudoers.d/99-linkat-$1 ]; then
                                        sudo rm /etc/sudoers.d/99-linkat-$1
                                fi

				grep -wq "$1" /etc/passwd
		                if [ $? -eq 1 ];then
				        yad \
			                --title="${appAltaAlu}" \
			                --image="gtk-dialog-info" \
			                --center \
			                --borders=20 \
			                --width=400 \
			                --height=100 \
			                --text-align=left \
			                --text="\nS'ha esborrat l'usuari/usuària $1." \
			                --button="D'acord"
				else
					yad \
                                        --title="${appAltaAlu}" \
                                        --image="gtk-dialog-info" \
                                        --center \
                                        --borders=20 \
                                        --width=400 \
                                        --height=100 \
                                        --text-align=left \
                                        --text="\nNo s'ha pogut esborrar l'usuari/usuària $1." \
                                        --button="D'acord"
                                        ERROR="1"
				fi
                        else
                                exit 1
                        fi
                fi
}


indexof()
{
        i=0; while [ "$i" -lt "${#findUsersCheck[@]}" ] && [ "${findUsersCheck[$i]}" != "$1" ]; do ((i++)); done; echo $i;
}

delete_menu ()
{
	findUsersCheck=($(awk -F : '$3 >= 1000 && $3 <= 40000' /etc/passwd | cut -d ":" -f 1 | grep -v 'nobody\|suport\|snap' | sed '1~1 a\false\' | sed '1i false' | sed '$d'))
        yadb=0
        awk -F : '$3 >= 1000 && $3 <= 40000' /etc/passwd | cut -d ":" -f 1 | grep -v 'nobody\|suport\|snap'
        if [ $? -eq 0 ];then
                while [ $yadb -eq "0" ];do
                yadb=$?
                        if [ $yadb -eq "0" ]; then
                        echo "COMENZANDO SCRIPT"        
                        prevUser=$(yad \
                        --title="${appAltaAlu}" \
                        --text="Aquests alumnes ja es troben donats d'alta al sistema Linkat.\nSi voleu esborrar-los, marqueu la casella corresponent i polseu el botó <b>Esborrar</b>." \
                        --list \
                        --image="gtk-dialog-info" \
                        --center \
                        --button="Esborrar:0" \
                        --button="Sortir:1" \
                        --borders=20 \
                        --fixed \
                        --checklist \
                        --width=400 \
                        --height=300 \
                        --center \
                        --text-align=left \
                        --column="" \
                        --column="Alumnes" "${findUsersCheck[@]}")

                        ans=$?
                                if [ $ans -eq 0 ]
                                then

                                        #userToDelete="$(echo ${prevUser}|cut -d\| -f2)"
                                        userToDelete=($(echo ${prevUser}|sed -e 's_|_\ _g' | sed 's_TRUE __g' | sed 's/ *$//' | tr -s ' '))
                                        echo $userToDelete
                                        userArray="${#userToDelete[@]}"
                                                for ((i = 0; i != userArray; i++)); do
                                                        deleteUser "${userToDelete[i]}"
                                                        echo "${findUsersCheck[@]}"
                                                        positionUser=$(indexof "${userToDelete[i]}")
                                                        positionCheck=$(expr $positionUser - 1)
                                                        indexes=($positionCheck $positionUser)
                                                        echo ${indexes[@]}
                                                        unset 'findUsersCheck[$positionCheck]'
                                                        unset 'findUsersCheck[$positionUser]'
                                                        findUsersCheck=$(echo "${findUsersCheck[@]}")
                                                done
						break
                                else
                                        echo "No has elegido ningún componente"
                                return 1
                                fi
                        fi
                done
        fi
}

delete_banner_end()
{

        if [  "$?" -eq 0 ]; then
                grep -wq "$1" /etc/passwd
                if [ $? -eq 1 ];then
                        yad \
                        --title="${appAltaAlu}" \
                        --image="/usr/share/pixmaps/linkat-alta-usuaris-edc.png" \
                        --center \
                        --borders=20 \
                        --width=400 \
                        --height=100 \
                        --text="\nL'usuari/usuària <b>$1</b> ha estat esborrat del sistema Linkat.\n" \
                        --button="Exit"
                fi
        fi
}


formulari_admin()
{
        res=$(yad \
        --title="${appPassAdm}" \
        --center \
        --borders=20 \
        --width=100 \
        --height=100 \
        --text-align=left \
        --text="\nIntroduïu una nova contrasenya per a l'usuari $adminUser.\n\nExemple: <b>C0ntr4S3ny4!</b>\n" \
        --image="/usr/share/pixmaps/linkat-alta-usuaris-edc.png" \
        --form --item-separator=" " \
        --field="Contrasenya":H \
        --field="Repetiu la contrasenya":H \
        --button="D'acord":0 \
       	--button="Cancel·la":1 \
        "" "" "")

res1=$?
        if [ "$res1" -eq 1 ]; then
        	exit 1
	fi


adminPass=$(echo "$res" | awk -F"|" '{print $1}')
adminPassCheck=$(echo "$res" | awk -F"|" '{print $2}')
}


formulari()
{
        res=$(yad \
        --title="${appAltaAlu}" \
        --center \
        --borders=20 \
        --width=100 \
        --height=100 \
        --text-align=left \
	--text="\nAplicatiu d'alta d'alumnat.\nCal que empleneu tots els camps.\nL'identificador de l'alumne/a (IDALU) només pot contenir caràcters numérics.\n\nExemple: <b>012345678</b>\n" \
        --image="/usr/share/pixmaps/linkat-alta-usuaris-edc.png" \
        --form --item-separator=" " \
        --field="Identificador": \
	--entry-text="Your name" \
        --field="Contrasenya":H \
        --field="Repetiu la contrasenya":H \
        --button="D'acord" --button="Cancel·la":11 \
        "" "" "")

res1="$?"

if [ "$res1" -gt 1 ]; then
        exit 1
fi

alumne=$(echo "$res" | awk -F"|" '{print $1}')
alumnePass=$(echo "$res" | awk -F"|" '{print $2}')
alumnePassCheck=$(echo "$res" | awk -F"|" '{print $3}')
}


check_form_admin()
{
        if [ -z "$1" ]; then
                yad  \
                --title="${appPassAdm}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                2--text-align=left \
                --text="\nNo s'ha introduït cap contrasenya." \
                --button="D'acord"
                ERROR="1"
        fi

        if [ ! "$1" == "$2" ]; then
                yad \
                --title="${appPassAdm}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="\nLa contrasenya no coincideix." \
                --button="D'acord"
                ERROR="1"
        fi

        if ! ( [[ $(echo "$1" | awk '/[a-z]/ && /[A-Z]/ && /[0-9]/') ]] || [[ $(echo "$2" | awk '/[a-z]/ && /[A-Z]/ && /[[:punct:]]/') ]] || [[ $(echo "$2" | awk '/[a-z]/ && /[A-Z]/ && /[[:digit:]]/') ]] || [[ $(echo "$2" | awk '/[a-z]/ && /[[:digit:]]/ && /[[:punct:]]/') ]] || [[ $(echo "$2" | awk '/[A-Z]/ && /[[:digit:]]/ && /[[:punct:]]/') ]] ); then
                yad \
                --title="${appPassAdm}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=50 \
                --text-align=left \
                --text="La contrasenya no compleix tots els requisits. Ha de tenir una longitud mínima de 8 caràcters i complir, com a mínim, amb 3 dels 4 requeriments següents:\n\n- 1 caràcter en minúscula\n- 1 caràcter en majúscula\n- 1 número\n- 1 símbol\n\nExemple: C0ntr4S3ny4!" \
                --button="D'acord"
                ERROR="1"
        fi

        for passnum in "$1"; do
            if [ ${#passnum} -lt 8 ]; then
                yad \
                --title="${appPassAdm}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="\nLa contrasenya ha de tenir una longitud mínima de 8 caràcters." \
                --button="D'acord"
                ERROR="1"
            fi
        done

}

validar_formulari_admin()
{
	yad \
                --title="${appPassAdm}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="\nVoleu confirmar el canvi de contrasenya de l'usuari $userAdmin?" \
	        --button="D'acord"\
        	--button="Cancel·la":11
		res1=$?
        if [ $res1 -gt 1 ]; then
		ERROR="1"
        fi
}

check_form()
{
        if [ -z "$1" ]; then
                yad  \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                2--text-align=left \
                --text="\nNo s'ha introduït cap identificador d'alumne/a." \
                --button="D'acord"
                ERROR="1"
        fi

        for idnum in "$1"; do
            if [ ${#idnum} -lt 8 ]; then
                yad \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="\nL'identificador ha de tenir una longitud mínima de 8 caràcters numérics." \
                --button="D'acord"
                ERROR="1"
            fi
        done


        if   [[ $(echo "$1" | awk '/[a-z]/ || /[A-Z]/ || /[[:punct:]]/') ]]; then
                yad \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="L'identificador no compleix tots els requisits. Només pot contenir:\n\n- Números\n\nExemple: <b>012345678</b>" \
                --button="D'acord"
                ERROR="1"
        fi

        if [ ! "$2" == "$3" ]; then
                yad \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="\nLa contrasenya no coincideix." \
                --button="D'acord"
                ERROR="1"
        fi
         if [ -z "$2" ] || [ -z "$3" ]; then
                yad \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="La contrasenya és buida." \
                --button="D'acord"
                ERROR="1"
        fi

	if ! ( [[ $(echo "$2" | awk '/[a-z]/ && /[A-Z]/ && /[0-9]/') ]] || [[ $(echo "$2" | awk '/[a-z]/ && /[A-Z]/ && /[[:punct:]]/') ]] || [[ $(echo "$2" | awk '/[a-z]/ && /[A-Z]/ && /[[:digit:]]/') ]] || [[ $(echo "$2" | awk '/[a-z]/ && /[[:digit:]]/ && /[[:punct:]]/') ]] || [[ $(echo "$2" | awk '/[A-Z]/ && /[[:digit:]]/ && /[[:punct:]]/') ]] ); then
                yad \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=50 \
                --text-align=left \
                --text="La contrasenya no compleix tots els requisits. Ha de tenir una longitud mínima de 8 caràcters i complir, com a mínim, amb 3 dels 4 requeriments següents:\n\n- 1 caràcter en minúscula\n- 1 caràcter en majúscula\n- 1 número\n- 1 símbol\n\nExemple: C0ntr4S3ny4!" \
                --button="D'acord"
                ERROR="1"
        fi

        for passnum in "$2"; do
            if [ ${#passnum} -lt 8 ]; then
                yad \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="\nLa contrasenya ha de tenir una longitud mínima de 8 caràcters." \
                --button="D'acord"
                ERROR="1"
            fi
        done
}

check_sys_user()
{ 
        if [ ! -z "$1" ]; then
                grep -wq "$1" /etc/passwd
                if [ $? -eq $SUCCESS ];then
                yad  \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text-align=left \
                --text="\nL'usuari/a amb identificador $1 ja existeix. Comproveu que és correcte" \
                --button="D'acord"
                ERROR="1"
        #exit $E_USEREXISTS
        fi
fi
}

add_user(){
        passMaxDays="$(awk '$1=="PASS_MAX_DAYS" {print $2}' /etc/login.defs)"
        passWarnAge="$(awk '$1=="PASS_WARN_AGE" {print $2}' /etc/login.defs)"
        passExpireDate="$(date +%Y-%m-%d --date="+$passMaxDays days")"

        sudo adduser --gecos "$1" --disabled-password "$1"
        sudo usermod -a -G uucp,dialout "$1"
        echo "$1:$2" | sudo chpasswd
        chage -M "$passMaxDays" --warndays $passWarnAge "$1"
        echo $passExpireDate > /home/$1/.caducitatPassword
        chown $1:$1 /home/$1/.caducitatPassword
        chmod 700 /home/"$1"
}

chpass_admin()
{
	if [ $? -eq 0 ]; then
	        echo "$adminUser:$1" | chpasswd
	fi
}

add_sudoer()
{
        sudo_admin="$(getent passwd | grep 1000 | cut -d ":" -f 1)"
        getent passwd | cut -d ":" -f 3 | grep -qw 1000
        if [ $? = 0 ] && [ $sudo_admin = "suport" ]; then
	        echo "$sudo_admin ALL=(ALL) NOPASSWD: /usr/share/linkat/linkat-stat-edc/linkat-stat-edc-user.sh" | sudo tee -a /tmp/99-linkat-$sudo_admin > /dev/null
                tmpsudo="$(sudo awk '!x[$0]++' /tmp/99-linkat-$sudo_admin)"
                echo $tmpsudo | sudo tee /etc/sudoers.d/99-linkat-$sudo_admin > /dev/null
                rm /tmp/99-linkat-$sudo_admin
                sudo chmod 440  /etc/sudoers.d/99-linkat-$sudo_admin

        fi

        grep -rqw "$1" /etc/passwd
        if [[ $? = 0 ]]; then
                echo "$1 ALL=(ALL) NOPASSWD: /usr/share/linkat/linkat-stat-edc/linkat-stat-edc-user.sh" | sudo tee -a /etc/sudoers.d/99-linkat-$1 > /dev/null
		sudo chmod 440 /etc/sudoers.d/99-linkat-$1
        fi
}

check_errors()
{
if [ ! "$?" -eq 0 ]; then
        echo -en "Error: $1"
        yad \
	--title="${appAltaAlu}" \
	--image="dialog-error" \
   	--center \
    	--borders=20 \
    	--width=400 \
    	--height=100 \
        --text="\nS'ha produit un error durant l'alta de l'usuari/a.\nEl programa es tancarà." \
        --button="D'acord"
        exit 22
fi
}

validar_formulari()
{
    yad \
    --title="${appAltaAlu}" \
    --image="info" \
    --center \
    --borders=20 \
    --width=400 \
    --height=100 \
    --text="\nVoleu confirmar l'alta de l'alumne/a $alumne ?\n" \
    --button="D'acord" \
    --button="Cancel·la":11
    res1="$?"

if [ "$res1" -gt 1 ]; then
        ERROR="1"
fi
}

banner_end()
{

if [ ! -z "$1" ]; then
        grep -wq "$1" /etc/passwd
        if [ $? -eq $SUCCESS ];then
                yad \
                --title="${appAltaAlu}" \
                --image="/usr/share/pixmaps/linkat-alta-usuaris-edc.png" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text="\nL'usuari/a <b>$1</b> ha estat donat/a d'alta al sistema Linkat.\n" \
                --button="D'acord"
        else
                yad \
                --title="${appAltaAlu}" \
                --image="dialog-error" \
                --center \
                --borders=20 \
                --width=400 \
                --height=100 \
                --text="\nL'usuari/a no s'ha pogut donar d'alta. Reviseu totes les dades, si us plau.\n" \
                --button="D'acord"
        fi
fi
}

chPwAdm()
{
	while [ "$ERROR" -eq 1 ]; do
	ERROR="0"
        banner_init_admin
        formulari_admin
        check_form_admin "$adminPass" "$adminPassCheck"
 	if [ "$ERROR" -eq 0 ]; then
		validar_formulari_admin
        fi
done
	chpass_admin "$adminPass"
}

altaAlu()
{
while [ "$ERROR" -eq 1 ]; do
        ERROR="0"
        banner_init
	delete_menu
        formulari
        check_form "$alumne" "$alumnePass" "$alumnePassCheck"
        check_sys_user "$alumne"
        if [ "$ERROR" -eq 0 ]; then
        	validar_formulari
        fi
done
        add_user "a-$alumne" "$alumnePass" "$alumnePass" "$alumne"
        add_sudoer "a-$alumne"
        banner_end "a-$alumne"
}

#export -f formulari formulari_admin banner_init delete_menu deleteUser delete_banner_end chpass_admin validar_formulari_admin altaAlu chPwAdm

export -f chPwAdm altaAlu

main_menu()
{
option=$(yad \
        --title="${appAltaAlu}" \
        --image="/usr/share/pixmaps/linkat-alta-usuaris-edc.png" \
        --center \
        --borders=20 \
        --width=400 \
        --height=100 \
    	--text-align=left \
    	--text="Sel·leccioneu una opció:" \
    	--button="Alta Alumnat":3 \
	--button="Exit":1
)

ret=$?

[[ $ret -eq 1 ]] && exit 0

if [[ $ret -eq 2 ]]; then
	chPwAdm
fi

if [[ $ret -eq 3 ]]; then
	altaAlu
fi
}

main_menu
