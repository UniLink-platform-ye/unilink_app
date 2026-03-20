@echo off
chcp 65001 >nul
echo ========================================
echo  إضافة قاعدة جدار الحماية لـ Apache (المنفذ 80)
echo  للسماح بالوصول من الشبكة المحلية (LAN) فقط
echo ========================================
echo.

:: التحقق من صلاحيات المسؤول
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] يرجى تشغيل هذا الملف كمسؤول (Run as administrator)
    echo     انقر بزر الماوس الأيمن على الملف واختر "تشغيل كمسؤول"
    pause
    exit /b 1
)

:: حذف القاعدة القديمة إن وُجدت (لتجنب التكرار)
netsh advfirewall firewall delete rule name="XAMPP Apache HTTP 80 (LAN)" >nul 2>&1

:: إضافة قاعدة جديدة: السماح بالاتصالات الواردة على المنفذ 80 من الشبكة المحلية فقط
netsh advfirewall firewall add rule name="XAMPP Apache HTTP 80 (LAN)" dir=in action=allow protocol=TCP localport=80 remoteip=localsubnet

if %errorLevel% equ 0 (
    echo [OK] تمت إضافة القاعدة بنجاح.
    echo      السيرفر متاح الآن من الأجهزة على نفس الشبكة مع بقاء الجدار الناري مفعّلاً.
) else (
    echo [خطأ] فشل إضافة القاعدة. تحقق من صلاحيات المسؤول.
)

echo.
pause
