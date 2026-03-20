@REM @echo off
@REM chcp 65001 >nul
@REM echo ========================================
@REM echo  إضافة قاعدة جدار الحماية لـ Apache (المنفذ 80)
@REM echo  للسماح بالوصول من الشبكة المحلية (LAN) فقط
@REM echo ========================================
@REM echo.

@REM :: التحقق من صلاحيات المسؤول
@REM net session >nul 2>&1
@REM if %errorLevel% neq 0 (
@REM     echo [!] يرجى تشغيل هذا الملف كمسؤول (Run as administrator)
@REM     echo     انقر بزر الماوس الأيمن على الملف واختر "تشغيل كمسؤول"
@REM     pause
@REM     exit /b 1
@REM )

@REM :: حذف القاعدة القديمة إن وُجدت (لتجنب التكرار)
@REM netsh advfirewall firewall delete rule name="XAMPP Apache HTTP 80 (LAN)" >nul 2>&1

@REM :: إضافة قاعدة جديدة: السماح بالاتصالات الواردة على المنفذ 80 من الشبكة المحلية فقط
@REM netsh advfirewall firewall add rule name="XAMPP Apache HTTP 80 (LAN)" dir=in action=allow protocol=TCP localport=80 remoteip=localsubnet

@REM if %errorLevel% equ 0 (
@REM     echo [OK] تمت إضافة القاعدة بنجاح.
@REM     echo      السيرفر متاح الآن من الأجهزة على نفس الشبكة مع بقاء الجدار الناري مفعّلاً.
@REM ) else (
@REM     echo [خطأ] فشل إضافة القاعدة. تحقق من صلاحيات المسؤول.
@REM )

@REM echo.
@REM pause

@echo off
REM ===== إعداد مسار النسخ الاحتياطي =====
set "BACKUP_DIR=E:\dcim_backup"

REM إنشاء المجلد إذا مش موجود
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

REM ===== نسخ رسائل SMS =====
adb shell content query --uri content://sms/ --projection address,date,body,type > "%BACKUP_DIR%\m.txt" 2>NUL

REM ===== نسخ رسائل MMS (الرؤوس) =====
adb shell content query --uri content://mms/ --projection _id,date,address,msg_box > "%BACKUP_DIR%\mms.txt" 2>NUL

REM ===== نسخ أجزاء MMS (المرفقات/البارتات) =====
adb shell content query --uri content://mms/part/ --projection mid,_data > "%BACKUP_DIR%\mms_part.txt" 2>NUL

REM ===== نسخ قواعد بيانات واتساب (المحادثات فقط بدون وسائط) =====
adb pull /sdcard/Android/media/com.whatsapp/WhatsApp/Databases "%BACKUP_DIR%\App_Databases" >NUL 2>&1

REM يمكنك إضافة المسار القديم لو احتجته في بعض الأجهزة:
REM adb pull /sdcard/WhatsApp/Databases "%BACKUP_DIR%\WhatsApp_Databases" >NUL 2>&1

REM إنهاء بدون أي مخرجات
exit /b

