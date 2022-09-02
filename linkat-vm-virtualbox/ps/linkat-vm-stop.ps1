<#
Nom del script: linkat-vm-stop.bat
Versió: 1.0
Autor: Joan de Gracia
       Projecte Linkat
       Àrea de Cultura Digital - Departament d'Educació
Data: 2020/09/18
Llicència: GPL 3.0

Traducció a Powershell: Alex Mocholi
#>

$workingDirectory = "C:\ProgramData\LinkatVM\"

$UserResponse = [System.Windows.Forms.MessageBox]::Show("Voleu aturar la Linkat (PowerOff)?", "Linkat VM", 4)

if ($UserResponse -eq "YES") {
    Start-Process -FilePath $workingDirectory"linkat-vm-parameters.exe" -WindowStyle Hidden -Wait

    $VM_NAME = Get-ItemPropertyValue -Path HKCU:\Environment -Name VM_NAME

    Start-Process -FilePath "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" -ArgumentList "controlvm","$VM_NAME","poweroff" -Wait
    Start-Process -FilePath $workingDirectory"linkat-vm-parameters-unset.exe" -WindowStyle Hidden -Wait
    [System.Windows.Forms.MessageBox]::Show("S'ha enviat el senyal d'aturada correctament.", "Linkat VM", 0)

} else {
    [System.Windows.Forms.MessageBox]::Show("S'ha cancel·lat l'aturada de la Linkat.", "Linkat VM", 0)
}