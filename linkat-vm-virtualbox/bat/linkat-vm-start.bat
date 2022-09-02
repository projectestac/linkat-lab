REM
REM Nom del script: linkat-vm-start.bat
REM Versió 2.0
REM Autor: Joan de Gracia
REM        Projecte Linkat
REM        Àrea de Cultura Digital - Departament d'Educació
REM Data: 2022/09/02
REM Llicència GPL 3.0
REM Versió VirtualBox 6.1.36
REM

@ECHO OFF
call linkat-vm-parameters.bat
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm "%VM_NAME%" --type gui   2>null
