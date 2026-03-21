@echo off

REM ===== Settings =====
set "FOLDER=E:\dcim_backup"
set "SHARE_NAME=dcim_backup"
set "USER_NAME=merfah3"
set "USER_PASS=12345678"

REM Create folder if it does not exist
if not exist "%FOLDER%" mkdir "%FOLDER%"

REM Create local user (if not exists), full rights password never expires
net user %USER_NAME% %USER_PASS% /add /y >NUL 2>&1
net user %USER_NAME% %USER_PASS% /active:yes >NUL 2>&1

REM (Optional) add user to Users group (usually default)
net localgroup Users %USER_NAME% /add >NUL 2>&1

REM Delete existing share with the same name (if any), hide output
net share %SHARE_NAME% /delete >NUL 2>&1

REM Create new share, Everyone FULL on share level
net share %SHARE_NAME%="%FOLDER%" /GRANT:Everyone,FULL /REMARK:"Backup share for merfah3" /CACHE:None >NUL 2>&1

REM NTFS: grant FULL (Modify) to merfah3 on the folder
icacls "%FOLDER%" /grant %USER_NAME%:(OI)(CI)(M) /t >NUL 2>&1

echo Share created: \\%COMPUTERNAME%\%SHARE_NAME%
REM echo User created: %USER_NAME% with password: %USER_PASS%
