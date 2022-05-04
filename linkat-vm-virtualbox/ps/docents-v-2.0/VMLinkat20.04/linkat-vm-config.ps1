<#
Nom del script: linkat-vm-config.bat
Versió: 1.0
Autor: Joan de Gracia
       Projecte Linkat
       Àrea de Cultura Digital - Departament d'Educació
Data: 2020/09/29
Llicència: GPL 3.0
Versió VirtualBox 6.1.14

Traducció a Powershell: Alex Mocholi
#20210325-03 - Es modifica ruta del Directori: "LinkatVM" - Damian Caviglia 
#>

$workingDirectory = "C:\ProgramData\LinkatVM\"
$controlFile = "$Env:appdata\linkat-vm-flag"
$VMpath = "$Env:appdata\VirtualBox"

if (Test-Path $controlFile -PathType Leaf) {
    exit
} else {
    echo $null >> $controlFile
    Start-Process -FilePath $workingDirectory"linkat-vm-parameters.exe" -WindowStyle Hidden -Wait

    $VM_NAME = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_NAME
    $VM_DISK = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_DISK
    $VM_SNAPSHOT = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_SNAPSHOT
    $VM_SHARED_FOLDER = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_SHARED_FOLDER

    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "createvm","--name $VM_NAME","--basefolder $VMpath","--ostype Ubuntu_64","--default","--register" -WindowStyle Hidden -Wait
    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "modifyvm $VM_NAME","--ostype Ubuntu_64","--memory 4096","--paravirtprovider kvm","--cpus 2","--graphicscontroller vmsvga --vram 128","--ioapic on","--biosapic apic","--nic1 nat","--nictype1 virtio","--cableconnected1 on","--macaddress1 auto","--boot1 disk","--boot2 none","--boot3 none","--boot4 none","--pae on","--nestedpaging on","--nested-hw-virt off","--clipboard-mode bidirectional" -WindowStyle Hidden -Wait
    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "storagectl $VM_NAME","--name SATA","--hostiocache on" -WindowStyle Hidden -Wait
    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "storageattach $VM_NAME","--storagectl SATA","--port 0","--type hdd","--medium `"$VM_DISK`"","--mtype normal" -WindowStyle Hidden -Wait
    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "storageattach $VM_NAME","--storagectl SATA","--port 0","--type hdd","--type hdd","--medium none" -WindowStyle Hidden -Wait
    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "storageattach $VM_NAME","--storagectl SATA","--port 0","--type hdd","--type hdd","--medium `"$VM_DISK`"","--mtype multiattach" -WindowStyle Hidden -Wait
    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "sharedfolder add $VM_NAME","--name HOST_FOLDER","--hostpath `"$VM_SHARED_FOLDER`"","--automount" -WindowStyle Hidden -Wait
    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "snapshot $VM_NAME","take $VM_SNAPSHOT" -WindowStyle Hidden -Wait
    Start-Process -FilePath $workingDirectory"linkat-vm-parameters-unset.exe" -WindowStyle Hidden -Wait
}