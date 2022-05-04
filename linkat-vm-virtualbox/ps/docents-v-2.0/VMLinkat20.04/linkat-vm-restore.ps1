<#
Nom del script: linkat-vm-restore.bat
Versió: 1.0
Autor: Joan de Gracia
       Projecte Linkat
       Àrea de Cultura Digital - Departament d'Educació
Data: 2020/09/18
Llicència: GPL 3.0

Traducció a Powershell: Alex Mocholi
#20210325-03 - Es modifica ruta del Directori: "LinkatVM" - Damian Caviglia
#>

$workingDirectory = "C:\ProgramData\LinkatVM\"

$UserResponse = [System.Windows.Forms.MessageBox]::Show("Voleu restaurar la imatge de la Linkat?", "Linkat VM", 4)

if ($UserResponse -eq "YES") {
    Start-Process -FilePath $workingDirectory"linkat-vm-parameters.exe" -WindowStyle Hidden -Wait

    $VM_NAME = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_NAME
    $VM_SNAPSHOT = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_SNAPSHOT

    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "snapshot","$VM_NAME","restore","$VM_SNAPSHOT" -Wait
    Start-Process -FilePath $workingDirectory"linkat-vm-parameters-unset.exe" -WindowStyle Hidden -Wait
    [System.Windows.Forms.MessageBox]::Show("S'ha restaurat la imatge de la Linkat correctament.", "Linkat VM", 0)
} else {
    $p = [char]46
    $o = [char]243
    [System.Windows.Forms.MessageBox]::Show("S'ha cancel"+ $p +"lat la restauraci"+ $o +" de la Linkat.", "Linkat VM", 0)
}