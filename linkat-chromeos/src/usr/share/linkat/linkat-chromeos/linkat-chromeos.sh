#!/bin/bash
#
# Instal·lador d'aplicacions Linkat en ChomeOS
# 30/07/2020
# Joan de Gracia
# Àrea de Cultura Digital
# Departament d'Educació
# Llicència GPL3
#
export GDK_BACKEND=x11
function configrepo {
   TMPFOL=$(mktemp -d)
   cd $TMPFOL
  (wget http://download-linkat.xtec.cat/distribution/linkat-edu-"$LK_RELEASE"/linkat-repo-"$LK_RELEASE".list > /dev/null 2>&1
   wget http://download-linkat.xtec.cat/distribution/linkat-edu-"$LK_RELEASE"/pubkey-linkat.gpg > /dev/null 2>&1
   sudo apt-key add pubkey-linkat.gpg > /dev/null 2>&1
   sudo mv linkat-repo-"$LK_RELEASE".list /etc/apt/sources.list.d/
   rm -rf $TMPFOL
   sudo apt update > /dev/null 2>&1 ) | zenity --progress --pulsate --auto-close --auto-kill --text="Afegint els repositoris Linkat."
}

#
# DEFINICIÓ VARIABLES
# DEBIAN BUSTER compatible amb UBUNTU 18.04
#

URL_LINKAT=http://linkat.eu/lk-chros-18.04.txt
DISTRIBUTION=$(lsb_release -c | cut -d ":" -f2 | tr -d "\t")
LK_RELEASE=""
LIMIT_DISC_SPACE=90

case $DISTRIBUTION in
	buster)
	   LK_RELEASE="18.04"
	;;

	bullseye)
	   LK_RELEASE="20.04"
	;;

	*)
	   exit 0
	;;
esac
# Servidor de test. Caldrà canviar-lo per download-linkat.xtec.cat
URL_LINKAT=http://linkat.eu/lk-chros-$LK_RELEASE.txt

ARCH=""

case "$(uname -m)" in
   x86_64)
      ARCH="amd64"
   ;;
   i686)
      ARCH="i386"
   ;;
   aarch64)
      ARCH="arm64"
   ;;
   *)
   ARCH=""
   ;;
esac  

declare -a 'packages_array'

zenity --info --width=300 --text="Aquest programa permet instal·lar <b>aplicacions GNU/Linux educatives</b> al vostre <b>ChromeOS</b>"
grep -i linkat-edu-$LK_RELEASE /etc/apt/sources.list.d/*.list > /dev/null 2>&1
if [ $? -gt 0 ] ; then
   configrepo
fi
TOPMARGIN=27
RIGHTMARGIN=10
SCREEN_WIDTH=$(xwininfo -root | awk '$1=="Width:" {print $2}')
SCREEN_HEIGHT=$(xwininfo -root | awk '$1=="Height:" {print $2}')
W=$(( $SCREEN_WIDTH / 2 - $RIGHTMARGIN ))
H=$(( $SCREEN_HEIGHT - 2 * $TOPMARGIN ))

#
# Descàrrega de l'índex d'aplicacions per instal·lar en CHROMEOS
#

TMP_FILE0=$(mktemp)

curl --fail --silent $URL_LINKAT -o $TMP_FILE0

if [ ! -s $TMP_FILE0 ]; then
   zenity --info --width=400 --text "No es pot descarregat l'índex d'aplicacions. Se surt del programa."
   rm $TMP_FILE0 
   exit 0
fi

INSTALL_PACKAGES=""
while [ "$INSTALL_PACKAGES" = "" ]; do
   INSTALL_PACKAGES="$(zenity --list --radiolist --title "Gestor de paquets Linkat-ChromeOS" --width=400 --height=200 --text "Gestor de paquets Linkat-ChromeOS" --column "" --column "Acció" True "Instal·lar paquets" False "Desinstal·lar paquets" False "Actualitzar paquets")"  
   if [ "$?" = "1" ]; then
      zenity --info --width=400 --text "Heu sortit del programa"
      rm $TMP_FILE0
      exit 0
   fi
   
done

LLISTA_CHROMEOS=$TMP_FILE0

(sudo apt update 2>/dev/null) | zenity --progress --pulsate --auto-close --auto-kill --text="Actualitzant repositoris."

TMP_FILE1=$(mktemp)
TMP_FILE2=$(mktemp)
TMP_FILE3=$(mktemp)

#
# LLISTA_CHROMEOS -> Fitxer amb la relació de paquets candidats. Es descarrega de download-linkat.xtec.cat
#
case $INSTALL_PACKAGES in

   "Desinstal·lar paquets")
      (
         while IF= read -r CHROME_PACKAGE
         do
            apt list $CHROME_PACKAGE 2>/dev/null |grep -i "$ARCH\|all" |grep -i instal |cut -d "/" -f1 >> $TMP_FILE1    
         done < $LLISTA_CHROMEOS
      ) | zenity --progress --pulsate --auto-close --auto-kill --text="Cercant paquets ..."
      FLAG_TEXT="desinstal·lar"
   ;;
   "Instal·lar paquets")
      FREE_DISC_SPACE=$(df -t btrfs | grep -v kvm | grep -i "dev" | tr -s " " | cut -d " " -f 5| tr -d "%")
      if [ $FREE_DISC_SPACE -ge $LIMIT_DISC_SPACE ]; then
         zenity --warning --width=300 --text="No podeu instal·lar més aplicacions. El disc es troba al $FREE_DISC_SPACE % de la seva capacitat."
         zenity --warning --width=300 --text "Es tancarà el programa."
         exit 0
      fi
      (
         while IF= read -r CHROME_PACKAGE
         do
            apt list $CHROME_PACKAGE 2>/dev/null |grep -i "$ARCH\|all" | grep -v instal |cut -d "/" -f1 >> $TMP_FILE1
          done < $LLISTA_CHROMEOS   
      ) | zenity --progress --pulsate --auto-close --auto-kill --text="Cercant paquets ..."
      FLAG_TEXT="instal·lar"
   ;;
   "Actualitzar paquets") 
      zenity --question --width=400 --text="Voleu actualitzar <b>tots</b> els paquets de la distribució GNU/Linux?"
      if [ "$?" = "1" ]; then
         zenity --info --width=400 --text "Heu sortit el programa"
      else
         (sudo apt upgrade -y  2>/dev/null ) | zenity --progress --pulsate --auto-close --auto-kill --text="Actualitzant tots els paquets..."
      fi  
      rm $TMP_FILE0 $TMP_FILE1 $TMP_FILE2 $TMP_FILE3
      zenity --info --width=400 --text "Els paquets s'han actualitzat correctament."
      exit 0  
   ;;
esac

if [[ ! -s $TMP_FILE1 ]]; then
   zenity --info --width=400 --text "No hi ha cap paquet per $FLAG_TEXT" 
   zenity --info --width=400 --text "Es tancarà el programa."
   rm $TMP_FILE0 $TMP_FILE1 $TMP_FILE2 $TMP_FILE3
   exit 0
fi


(for paquets in $(cat $TMP_FILE1)
do
   VERSION="$(apt-cache policy $paquets |grep -i candidate | cut -d ":" -f2 | tr -d '[:blank:]')"
   DESCRIPTION="$(apt-cache show $paquets=$VERSION |grep -i description | grep -v md5  | cut -d ":" -f 2)" 
   echo "false|$paquets|$DESCRIPTION" >> $TMP_FILE2
done) | zenity --progress --pulsate --auto-close --auto-kill --text="Processant informació..."

while [[ ! -s $TMP_FILE3 ]]; do

(while IFS= read -r infopkg
do
BOOLEAN=$(echo $infopkg |cut -d "|" -f 1)
PACKAGE=$(echo $infopkg | cut -d "|" -f 2)
DESCRIPTION="$(echo $infopkg | cut -d "|" -f 3)"
echo $BOOLEAN
echo "$PACKAGE"
echo "$DESCRIPTION"
done < "$TMP_FILE2") | zenity --width=$W --height=$H --list --checklist --text="Seleccioneu paquets per $FLAG_TEXT" \
   --add-entry="Fitxer"\
   --column="Marca" \
   --column="Nom del paquet"\
   --column="Descripció" > $TMP_FILE3

if [ "$?" = "1" ]; then
   zenity --info --width=400 --text "Heu sortit del programa"
   rm $TMP_FILE0 $TMP_FILE1 $TMP_FILE2 $TMP_FILE3
   exit 0
fi     
done     

zenity --question --width=400 --text="Voleu $FLAG_TEXT el(s) paquet(s) que heu marcat?"
if [ "$?" = "1" ]; then
   zenity --info --width=400 --text "Heu sortit el programa"
   rm $TMP_FILE0 $TMP_FILE1 $TMP_FILE2 $TMP_FILE3
   exit 0
fi 
readarray -t -d '|' packages_array < $TMP_FILE3
for i in $(seq 0 $((${#packages_array[@]}-1)))
do
   case $FLAG_TEXT in
      "instal·lar")
         FREE_DISC_SPACE=$(df -t btrfs | grep -v kvm | grep -i "dev" | tr -s " " | cut -d " " -f 5| tr -d "%")
         if [ $FREE_DISC_SPACE -ge $LIMIT_DISC_SPACE ]; then
            zenity --warning --width=300 --text="No podeu instal·lar més aplicacions. El disc es troba al $FREE_DISC_SPACE % de la seva capacitat."
            zenity --warning --width=300 --text "Es tancarà el programa."
            rm $TMP_FILE0 $TMP_FILE1 $TMP_FILE2 $TMP_FILE3
            exit 0
         fi
         (sudo apt install -y ${packages_array[$i]} 2>/dev/null ) | zenity --progress --pulsate --auto-close --auto-kill --text="Instal·lant el(s) paquet(s) seleccionat(s)..."
      ;;
      "desinstal·lar")
         (sudo apt remove -y ${packages_array[$i]} 2>/dev/null ) | zenity --progress --pulsate --auto-close --auto-kill --text="Desinstal·lant el(s) paquet(s) seleccionat(s)..."
      ;;
   esac
done
zenity --info --width=400 --text "El(s) paquet(s) s'ha(n) $(echo $FLAG_TEXT | sed -e 's/r/t/g' ) correctament."
rm $TMP_FILE0 $TMP_FILE1 $TMP_FILE2 $TMP_FILE3
exit 0
