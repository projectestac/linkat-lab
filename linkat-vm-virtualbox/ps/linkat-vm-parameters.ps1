<#
Nom del script: linkat-vm-parameters.bat
Versió: 1.0
Autor: Joan de Gracia
       Projecte Linkat
       Àrea de Cultura Digital - Departament d'Educació
Data: 2020/09/18
Llicència: GPL 3.0
====================================
Traducció a Powershell: Alex Mocholi
====================================
Versió 1.1
Autor del canvi: Javier Rodriguez
Actualització: 2022/11/15
Canvi: Llegeix directament de la partició L: el fitxer vdi i posa el nom de la MV amb el nom del fitxer.
#>
$NOM_VDI = (Get-ChildItem -Path L:\* -Include *.vdi).Name
$NOM_MV = (Get-ChildItem -Path L:\* -Include *.vdi).BaseName
New-ItemProperty -Name VM_DISK -PropertyType String -Value "L:\$NOM_VDI" -Path HKCU:\Environment
New-ItemProperty -Name VM_NAME -PropertyType String -Value "$NOM_MV" -Path HKCU:\Environment
New-ItemProperty -Name VM_SNAPSHOT -PropertyType String -Value "$($NOM_MV)_FACTORY" -Path HKCU:\Environment
New-ItemProperty -Name VM_SHARED_FOLDER -PropertyType String -Value "$env:USERPROFILE\Documents" -Path HKCU:\Environment