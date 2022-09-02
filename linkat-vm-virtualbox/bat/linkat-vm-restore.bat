REM
REM Nom del script: linkat-vm-restore.bat
REM Versió 2.0
REM Autor: Joan de Gracia
REM        Projecte Linkat
REM        Àrea de Cultura Digital - Departament d'Educació
REM Data: 2022/09/02
REM Llicència GPL 3.0
REM Versió VirtualBox 6.1.36
REM


@ECHO OFF

:pregunta
set /P c=Voleu resturar la imatge de la Linkat[S/N]?
if /I "%c%" == "S" goto :si
if /I "%c%" == "N" goto :no

goto :pregunta

:si
call linkat-vm-parameters.bat
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" snapshot "%VM_NAME%" restore %VM_NAME%_FACTORY
pause
exit

:no
pause
exit
