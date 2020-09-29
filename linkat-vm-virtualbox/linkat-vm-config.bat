REM
REM Nom del script: linkat-vm-config.bat
REM Versió 1.0
REM Autor: Joan de Gracia
REM        Projecte Linkat
REM        Àrea de Cultura Digital - Departament d'Educació
REM Data: 2020/09/29
REM Llicència GPL 3.0
REM Versió VirtualBox 6.1.14
REM

@ECHO OFF

if exist linkat-vm-flag (
    exit
) else (
   type nul >linkat-vm-flag
   call linkat-vm-parameters.bat
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createvm --name "%VM_NAME%" --ostype Ubuntu_64 --default --register
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm "%VM_NAME%" --ostype "Ubuntu_64" --memory 4096 --paravirtprovider kvm --cpus 2 --graphicscontroller vmsvga --vram 128 --ioapic on --biosapic apic --nic1 nat --nictype1 virtio --cableconnected1 on --macaddress1 auto --boot1  disk --boot2 none --boot3 none --boot4 none --pae on --nestedpaging on --nested-hw-virt off
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl "%VM_NAME%" --name SATA --hostiocache on
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"  storageattach "%VM_NAME%" --storagectl SATA --port 0 --type hdd --medium %VM_DISK%  --mtype normal
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "%VM_NAME%" --storagectl SATA --port 0 --type hdd --type hdd --medium none
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach "%VM_NAME%" --storagectl SATA --port 0 --type hdd --type hdd --medium %VM_DISK% --mtype multiattach
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" snapshot "%VM_NAME%" take %VM_SNAPSHOOT%
   "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" sharedfolder add "%VM_NAME%" --name="HOST_FOLDER" --hostpath="%VM_SHARED_FOLDER%" --automount
)
exit

