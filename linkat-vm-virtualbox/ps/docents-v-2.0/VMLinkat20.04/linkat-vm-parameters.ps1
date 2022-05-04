<#
Nom del script: linkat-vm-parameters.bat
Versió: 1.0
Autor: Joan de Gracia
       Projecte Linkat
       Àrea de Cultura Digital - Departament d'Educació
Data: 2020/09/18
Llicència: GPL 3.0

Traducció a Powershell: Alex Mocholi
#20210325-03 - Es modifica ruta del Directori: "LinkatVM" - Damian Caviglia
#>

New-ItemProperty -Name VM_DISK -PropertyType String -Value "L:\Linkat-20.04.vdi" -Path HKCU:\Environment
New-ItemProperty -Name VM_NAME -PropertyType String -Value "lk2004" -Path HKCU:\Environment
$VM_NAME = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_NAME
New-ItemProperty -Name VM_SNAPSHOT -PropertyType String -Value "$($VM_NAME)_FACTORY" -Path HKCU:\Environment
New-ItemProperty -Name VM_SHARED_FOLDER -PropertyType String -Value "$env:USERPROFILE\Documents" -Path HKCU:\Environment