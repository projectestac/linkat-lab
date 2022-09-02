<#
Nom del script: linkat-vm-start.bat
Versió: 1.0
Autor: Joan de Gracia
       Projecte Linkat
       Àrea de Cultura Digital - Departament d'Educació
Data: 2020/09/18
Llicència: GPL 3.0

Traducció a Powershell: Alex Mocholi
#>

$workingDirectory = "C:\ProgramData\LinkatVM\"

Start-Process -FilePath $workingDirectory"linkat-vm-parameters.exe" -WindowStyle Hidden -Wait

$VM_NAME = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_NAME

Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "startvm","$VM_NAME","--type gui" -Wait
Start-Process -FilePath $workingDirectory"linkat-vm-parameters-unset.exe" -WindowStyle Hidden -Wait