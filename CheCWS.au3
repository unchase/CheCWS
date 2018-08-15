; #INDEX# =======================================================================================================================
; Title .........: CheCWS v1.0.2
; AutoIt Version : v3.3.14.2
; Description ...: Программа для автоматической смены фона рабочего стола по таймеру.
; Author(s) .....: Unchase
; ===============================================================================================================================
#include <GUIConstantsEx.au3>
#include <gdiplus.au3>
#include <File.au3>
#Include <Array.au3>
#include <Misc.au3>
#include <GuiConstantsEx.au3>
#include <Constants.au3>
#include <GuiComboBox.au3>
#include <Date.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <String.au3>
#include <Crypt.au3>
#include <WinAPISys.au3>



Global $key = "YOUR_KEY"
Global $sProgramName = "CheCWS"
Global $sProgramVersion = "v1.0.2"
Global $sName = 'CheCWS.exe'
Global $sRegRun = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
Global $denyRunTaskManager = $GUI_UNCHECKED
Global $serv = "seclogon"
Global $INIFILE = @ScriptDir & "\" & $sProgramName & ".ini"
Global $adminUser = IniRead($INIFILE, "CREDENTIALS", "user", "")
Global $adminPassword = ""
Global $cryptAdminPassword = ""
Global $autoRun = RegRead("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "AutoRun")
If $autoRun = "" Then
   $autoRun = $GUI_CHECKED
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "AutoRun", "REG_SZ", $autoRun)
EndIf

; запуск службы "Вторичный вход в систему"
Run(@ComSpec & " /c net start " & $serv, "", @SW_HIDE)

; пытаемся отключить UAC для Windows Vista и выше
If _WinAPI_GetVersion() >= "6.0" Then
   If RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System", "EnableLUA") = 1 Then
	  TrayTip("Запуск программы " & $sProgramName & " " & $sProgramVersion & " с UAC", "UAC включен. Отключаем...", 3, 2)
	  If RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System", "EnableLUA", "REG_DWORD", 0) Then
		 TrayTip("Запуск программы " & $sProgramName & " " & $sProgramVersion & " с UAC", "UAC отключен.", 5, 2)
	  Else
		 TrayTip("Запуск программы " & $sProgramName & " " & $sProgramVersion & " с UAC", "Не удалось отключить UAC. Завершение работы.", 3, 2)
		 Sleep(3)
		 Exit
	  EndIf
   EndIf
EndIf


If Not IsAdmin() Then
   ;~ окно ввода данных для запуска под админом
   $wRunAsAdminWindow = GUICreate("Запуск " & $sProgramName & " v 1.0", 390, 75)
   GUICtrlCreateLabel("Имя пользователя:", 10, 5)
   $iUserName = GUICtrlCreateInput($adminUser, 10, 25, 100, Default)
   GUICtrlCreateLabel("Пароль:", 120, 5)
   $iUserPassword = GUICtrlCreateInput($adminPassword, 120, 25, 100, Default, BitOR($GUI_SS_DEFAULT_INPUT, $ES_PASSWORD))
   $cbShowPassword = GUICtrlCreateCheckbox("Показать пароль", 10, 50, 105, 17)
   $lLabel = GUICtrlCreateLabel("Необходимо запускать под администратором", 120, 53)
   GUICtrlSetColor($lLabel, 0x55AA12)

   $bCreateINIFile = GUICtrlCreateButton("Создать ini-файл", 230, 3, 150, 22)
   $bRunAsUser = GUICtrlCreateButton("Запустить", 230, 25, 150, 22)

   If $autorun = 1 Then
	  If Not FileExists($INIFILE) Then
		 MsgBox(48, "Автозапуск программы " & $sProgramName & " " & $sProgramVersion, "Файл конфигурации '" & $INIFILE & "' не существует.")
	  Else
		 $passINIRead = IniRead($INIFILE, "CREDENTIALS", "password", "")
		 If $passINIRead <> "" Then
			$adminPassword = FromRC4ToPassword($passINIRead)
			If RunAs($adminUser, @ComputerName, $adminPassword, 1, @ScriptFullPath & " " & @UserName & " " & $passINIRead, @ScriptDir) = 0 Then
			   MsgBox(16, "Запуск программы " & $sProgramName & " " & $sProgramVersion, "Произошла ошибка (автоматический вход): неверно заданы имя пользователя '" & $adminUser & "' или пароль, либо не запущена служба 'seclogon' (служба вторичного входа в систему)." & @LF & "Возможно, вы пытаетесь запустить программу не под администратором." & @LF & "Проверьте, запущена ли служба 'seclogon' (служба вторичного входа в систему). Возможно, средства защиты блокируют ее запуск.")
			Else
			   Exit
			EndIf
		 EndIf
	  EndIf
   EndIf

   GUISetState(@SW_SHOW, $wRunAsAdminWindow)

   $sDefaultPassChar = GUICtrlSendMsg($iUserPassword, $EM_GETPASSWORDCHAR, 0, 0)

   While 1
	  Switch GUIGetMsg()
	  Case $GUI_EVENT_CLOSE
		 Exit
	  Case $cbShowPassword
		 If GUICtrlRead($cbShowPassword) = $GUI_CHECKED Then
			 GUICtrlSendMsg($iUserPassword, $EM_SETPASSWORDCHAR, 0, 0)
			 GUICtrlSetData($cbShowPassword, "Скрыть пароль")
		 Else
			 GUICtrlSendMsg($iUserPassword, $EM_SETPASSWORDCHAR, $sDefaultPassChar, 0)
			 GUICtrlSetData($cbShowPassword, "Показать пароль")
		 EndIf
		 GUICtrlSetState($iUserPassword, $GUI_FOCUS)
	  Case $bRunAsUser
		 $adminUser = GUICtrlRead($iUserName)
		 $adminPassword = GUICtrlRead($iUserPassword)

		 if $adminPassword = "" Then
			MsgBox(16, "Запуск программы " & $sProgramName & " " & $sProgramVersion, "Вы не можете запустить программу от имени пользователя без пароля." & @LF & "Задайте пароль указанному пользователю или запускайте программу от имени пользователя с паролем.")
		 Else
			If RunAs($adminUser, @ComputerName, $adminPassword, 1, @ScriptFullPath & " " & @UserName & " " & FromPasswordToRC4($adminPassword), @ScriptDir) = 0 Then
			   MsgBox(16, "Запуск программы " & $sProgramName & " " & $sProgramVersion, "Произошла ошибка: неверно заданы имя пользователя '" & $adminUser & "' или пароль, либо не запущена служба 'seclogon' (служба вторичного входа в систему)." & @LF & "Возможно, вы пытаетесь запустить программу не под администратором." & @LF & "Проверьте, запущена ли служба 'seclogon' (служба вторичного входа в систему). Возможно, средства защиты блокируют ее запуск.")
			Else
			   if not FileExists ($INIFILE) Then
				  Filewrite($INIFILE, "")
			   EndIf
			   IniWrite($INIFILE, "CREDENTIALS", "user", $adminUser)
			   IniWrite($INIFILE, "CREDENTIALS", "password", FromPasswordToRC4($adminPassword))
			   GUICtrlSetData($iUserPassword, "")
			   Exit
			EndIf
		 EndIf
	  Case $bCreateINIFile
		 If MsgBox(36, "Создание ini-файла", "Использовать введенные данные для создания ini-файла для автоматического входа в программу?") = 6 Then
			$adminUser = GUICtrlRead($iUserName)
			$adminPassword = GUICtrlRead($iUserPassword)
			$newINIFile = FileSaveDialog("Выберите ini-файл для сохранения", @DesktopDir, "Файлы настроек (" & $sProgramName & ".ini)", 16, "CheCWS.ini")
			If Not FileExists($newINIFile) Then
			   If Filewrite($newINIFile, "") Then
				  MsgBox(64, "Создание ini-файла", "Файл с данными для автоматического входа в програму создан по пути:" & @LF & $newINIFile)
			   Else
				  MsgBox(16, "Создание ini-файла", "Не удалось создать файл с данными для автоматического входа в програму по пути:" & @LF & $newINIFile)
			   EndIf
			EndIf
			IniWrite($newINIFile, "CREDENTIALS", "user", $adminUser)
			IniWrite($newINIFile, "CREDENTIALS", "password", FromPasswordToRC4($adminPassword))
		 EndIf
	  EndSwitch
   WEnd
EndIf


#requireadmin


Global $localUserName = ""
Global $runUnderAdminFromUser = 0
If IsAdmin() And $CmdLine[0] > 0 Then
   If $CmdLine[1] <> "" Then $runUnderAdminFromUser = 1
   If $localUserName = "" And $CmdLine[1] = $localUserName Then
	  MsgBox(16, "Запуск программы " & $sProgramName & " " & $sProgramVersion, "Пользователь пытался запустить программу от имени администратора с пустым именем.")
	  Exit
   EndIf
   $localUserName = $CmdLine[1]
   if $CmdLine[0] >= 2 And Not FileExists($INIFILE) Then
	  $cryptAdminPassword = $CmdLine[2]
	  FileWrite($INIFILE, "")
	  IniWrite($INIFILE, "CREDENTIALS", "user", @UserName)
	  IniWrite($INIFILE, "CREDENTIALS", "password", $cryptAdminPassword)
	  $adminUser = $localUserName
   EndIf
EndIf


If $autoRun = 1 Then
   If @ScriptName <> $sName Then
	  MsgBox(16, "Запуск программы " & $sProgramName & " " & $sProgramVersion, "Файл программы переименован в '" & @ScriptName & "'." & @CRLF & "Имя файла программы должно быть только" & @CRLF & $sName)
	  Exit
   EndIf

   If RegRead($sRegRun, @ScriptName) = '' Or RegRead($sRegRun, @ScriptName) <> @ScriptFullPath Then
	  RegWrite($sRegRun, @ScriptName, "REG_SZ", @ScriptFullPath)
   EndIf
ElseIf $autoRun = 4 Then
   RegDelete($sRegRun, @ScriptName)
EndIf


Func FromPasswordToRC4($pass)
   Return __StringEncrypt(1, $pass, $key)
EndFunc


Func FromRC4ToPassword($hashPass)
   Return __StringEncrypt(0, $hashPass, $key)
EndFunc


If Not @Compiled Then
   MsgBox(48, "Запуск программы " & $sProgramName & " " & $sProgramVersion, "Необходимо запустить скомпилированную программу.")
   Exit
EndIf


If Not _Singleton(@ScriptName) Then
   Exit
EndIf


Global $regPath = ""
If $localUserName = "" Then
   $regPath = "HKEY_LOCAL_MACHINE\Software\" & $sProgramName & "\" & @UserName
Else
   $regPath = "HKEY_LOCAL_MACHINE\Software\" & $sProgramName & "\" & $localUserName
EndIf


Global $prevSecond = RegRead($regPath, "Second")
If $prevSecond = "" Then
   $prevSecond = @SEC
   RegWrite($regPath, "Second", "REG_SZ", $prevSecond)
EndIf
Global $prevMinute = RegRead($regPath, "Minute")
If $prevMinute = "" Then
   $prevMinute = @MIN
   RegWrite($regPath, "Minute", "REG_SZ", $prevMinute)
EndIf
Global $prevHour = RegRead($regPath, "Hour")
If $prevHour = "" Then
   $prevHour = @HOUR
   RegWrite($regPath, "Hour", "REG_SZ", $prevHour)
EndIf
Global $prevDay = RegRead($regPath, "Day")
If $prevDay = "" Then
   $prevDay = @MDAY
   RegWrite($regPath, "Day", "REG_SZ", $prevDay)
EndIf
Global $prevMonth = RegRead($regPath, "Month")
If $prevMonth = "" Then
   $prevMonth = @MON
   RegWrite($regPath, "Month", "REG_SZ", $prevMonth)
EndIf
Global $prevYear = RegRead($regPath, "Year")
If $prevYear = "" Then
   $prevYear = @YEAR
   RegWrite($regPath, "Year", "REG_SZ", $prevYear)
EndIf


Global $imagesFolderPath = RegRead("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "ImagesFolderPath")
If $imagesFolderPath = "" Then
   $imagesFolderPath = @DocumentsCommonDir & "\Wallpapers"
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "ImagesFolderPath", "REG_SZ", $imagesFolderPath)
EndIf
Global $timeout = RegRead("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "Timeout")
If $timeout = "" Then
   $timeout = 5
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "Timeout", "REG_SZ", $timeout)
EndIf
Global $timeoutPeriod = RegRead("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "TimeoutPeriod")
If $timeoutPeriod = "" Then
   $timeoutPeriod = "Минут"
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "TimeoutPeriod", "REG_SZ", $timeoutPeriod)
EndIf
Global $stretchMode = RegRead("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "StretchMode")
If $stretchMode = "" Then
   $stretchMode = 4
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "StretchMode", "REG_SZ", $stretchMode)
EndIf


Global $currentWallpaper = RegRead('HKEY_CURRENT_USER\Control Panel\Desktop', 'Wallpaper')
Global $imageFilesList = _FileListToArrayEx($imagesFolderPath, "*.jpg|*.bmp", 8)
Global $folderTime = FileGetTime($imagesFolderPath, 0, 1)
Global $doit = 1
Global $hTimer = TimerInit()
Global $cantUserChangeWallpaper = RegRead("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop", "NoChangingWallpaper")

;~ настройки трея
opt("TrayAutoPause", 0)
Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)
TraySetClick(8)
$tCurrentWp = TrayCreateItem("Открыть каталог с изображениями", -1, -1, 0)
TrayItemSetOnEvent($tCurrentWp, "OpenWallpaperFolder")
$thalt = TrayCreateItem("Приостановить работу",-1 ,-1, 0)
If $runUnderAdminFromUser = 1 Then TrayItemSetState($thalt, $TRAY_DISABLE)
TrayItemSetOnEvent($thalt, "Halt")
$tCantUserChangeWallpaper = TrayCreateItem("Запретить пользователю менять обои",-1 ,-1, 0)
TrayItemSetOnEvent($tCantUserChangeWallpaper, "UserCanChangeWallpaper")
If $cantUserChangeWallpaper = 1 Then
   TrayItemSetState($tCantUserChangeWallpaper, 1)
Else
   TrayItemSetState($tCantUserChangeWallpaper, 4)
EndIf

$tsettings = TrayCreateItem("Настройки", -1, -1, 0)
TrayItemSetOnEvent($tsettings, "OpenSettingsGUI")
$tAbout = TrayCreateItem("О программе", -1, -1, 0)
TrayItemSetOnEvent($tAbout, "OpenAbout")
$tExit = TrayCreateItem("Выход", -1, -1, 0)
If $runUnderAdminFromUser = 1 Then TrayItemSetState($tExit, $TRAY_DISABLE)
TrayItemSetOnEvent($tExit, "ExitScript")
TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "SetRandomWallpaper")

;~ окно настроек
$window = GUICreate("Настройки " & $sProgramName & " " & $sProgramVersion, 340, 140)
$gImagesFolderPath = GUICtrlCreateInput($imagesFolderPath, 10, 5, 215, 20)
$gBrowseImagesFolder = GUICtrlCreateButton("Обзор", 230, 4, 100, 22)
GUICtrlCreateLabel("Положение обоев:", 10, 33)
$gList = GUICtrlCreateCombo("По центру", 120, 30, 100, 20, 0x0003)
GUICtrlSetData($gList, "Замостить|Растянуть|Заполнить|По размеру|По ширине")
_GUICtrlComboBox_SetCurSel($gList, $stretchMode)
$gAutoRun = GUICtrlCreateCheckbox("Автозапуск", 230, 30)
GUICtrlSetState($gAutoRun, $autoRun)

GUICtrlCreateLabel("Время смены:", 10, 58)
$gTimeout = GUICtrlCreateInput($timeout, 85, 55, 30, 20, 0x2000)
$gTimeoutPeriod = GUICtrlCreateCombo("", 120, 54, 100, 30, 0x0003)
GUICtrlSetData($gTimeoutPeriod, "Секунд|Минут|Часов|Дней|Месяцев|Лет", $timeoutPeriod)
$gSaveSettingsToREG = GUICtrlCreateButton("Сохранить", 230, 54, 100, 22)
_GUICtrlComboBox_SetCurSel($gList, $stretchMode)

$gDenyRunTaskManager = GUICtrlCreateCheckbox("Запрет запуска диспетчера задач при рабочей программе", 10, 76)
GUICtrlSetState($gDenyRunTaskManager, $denyRunTaskManager)

GUICtrlCreateLabel("Время последней смены фона рабочего стола:", 10, 98)
GetDateTimeFromREG()
$gLastChangeWallpaper = GUICtrlCreateLabel($prevHour & ":" & $prevMinute & ":" & $prevSecond & " " & $prevDay & "." & $prevMonth & "." & $prevYear & " года.", 10, 118)
GUICtrlSetColor($gLastChangeWallpaper, 0x55AA12)

$gCreateLoginINIFile = GUICtrlCreateButton("Создать ini-файл", 150, 115, 110, 22)
$gExitProgram = GUICtrlCreateButton("Выход", 260, 115, 70, 22)
If $runUnderAdminFromUser = 0 Then
   GUICtrlSetState($gExitProgram, $GUI_DISABLE)
   GUICtrlSetState($gCreateLoginINIFile, $GUI_DISABLE)
Else
   GUICtrlSetState($gExitProgram, $GUI_ENABLE)
   GUICtrlSetState($gCreateLoginINIFile, $GUI_ENABLE)
EndIf


GetDateTimeFromREG()
while 1
   ; для якобы скрытия из диспетчера задач
   If $denyRunTaskManager = $GUI_CHECKED Then
	  $taskmgrRun = ProcessExists("taskmgr.exe")
	  If $taskmgrRun Then
		 ProcessClose($taskmgrRun)
	  EndIf
   EndIf

   $folderTimeNow = FileGetTime($imagesFolderPath, 0, 1)
   if $folderTime <> $folderTimeNow Then
	  $imageFilesList = _FileListToArrayEx($imagesFolderPath, "*.jpg|*.bmp", 8)
	  $folderTime = $folderTimeNow
   EndIf
   if $doit Then
	  $timeoutFlag = CheckTimeout()
	  If $timeoutFlag = 1 Then
		 SetRandomWallpaper()
		 $timeoutFlag = 0
	  EndIf
   EndIf
   sleep (1000)
WEnd


Func GetDateTimeFromREG()
   $prevSecond = RegRead($regPath, "Second")
   $prevMinute = RegRead($regPath, "Minute")
   $prevHour = RegRead($regPath, "Hour")
   $prevDay = RegRead($regPath, "Day")
   $prevMonth = RegRead($regPath, "Month")
   $prevYear = RegRead($regPath, "Year")
EndFunc


Func CheckTimeout()
   $dateFromReg = $prevYear & "/" & $prevMonth & "/" & $prevDay & " " & $prevHour & ":" & $prevMinute & ":" & $prevSecond
   Switch $timeoutPeriod
   Case "Секунд"
	  $dateDiffType = "s"
   Case "Минут"
	  $dateDiffType = "n"
   Case "Часов"
	  $dateDiffType = "h"
   Case "Дней"
	  $dateDiffType = "D"
   Case "Месяцев"
	  $dateDiffType = "M"
   Case "Лет"
	  $dateDiffType = "Y"
   Case Else
	  $dateDiffType = "s"
   EndSwitch

   $dateDiff = _DateDiff($dateDiffType, $dateFromReg, _NowCalc())
   If $dateDiff >= $timeout Then
	  If @error Then
		 MsgBox(16, "Ошибка", "Произошла ошибка:" & @LF & @error)
		 Return 0
	  EndIf
	  Return 1
   Else
	  Return 0
   EndIf
EndFunc


Func OpenSettingsGUI()
   If $runUnderAdminFromUser = 1 Then
	  $wsPasswordWindow = GUICreate("Открыть настройки " & $sProgramName & " v 1.0", 330, 60)
	  GUICtrlCreateLabel("Введите пароль администратора:", 10, 5)
	  $isUserPassword = GUICtrlCreateInput("", 10, 30, 170, Default, $ES_PASSWORD)
	  $bsOpen = GUICtrlCreateButton("Открыть", 210, 30, 100, 22)
	  GUICtrlSetState($isUserPassword, $GUI_FOCUS)
	  GUISetState(@SW_SHOW, $wsPasswordWindow)
	  while 1
		 $msg = GUIGetMsg()
		 Select
		 Case $msg = $GUI_EVENT_CLOSE
			GUISetState(@SW_HIDE, $wsPasswordWindow)
			ExitLoop
		 Case $msg = $bsOpen
			If Not FileExists($INIFILE) Then
			   MsgBox(48, "Открыть настройки " & $sProgramName & " " & $sProgramVersion, "Файл конфигурации '" & $INIFILE & "' не существует. Невозможно открыть настройки.")
			Else
			   $cryptAdminPassword = IniRead($INIFILE, "CREDENTIALS", "password", "")
			   If $cryptAdminPassword = FromPasswordToRC4(GUICtrlRead($isUserPassword)) And $cryptAdminPassword <> "" Then
				  GUICtrlSetData($isUserPassword, "")
				  GUISetState(@SW_HIDE, $wsPasswordWindow)
				  OpenSettingsGUIRun()
				  ExitLoop
			   Else
				  TrayTip("Открыть настройки " & $sProgramName & " v 1.0", "Неверно введен пароль администратора.", 5, 2)
			   EndIf
			EndIf
		 EndSelect
	  WEnd
   Else
	  OpenSettingsGUIRun()
   EndIf
Endfunc


Func OpenSettingsGUIRun()
   GUICtrlSetData($gLastChangeWallpaper, $prevHour & ":" & $prevMinute & ":" & $prevSecond & " " & $prevDay & "." & $prevMonth & "." & $prevYear & " года.")
   GUISetState(@SW_SHOW, $window)
   $denyRunTaskManager = RegRead("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "DenyRunTaskManager")
   GUICtrlSetState($gDenyRunTaskManager, $denyRunTaskManager)
   while 1
	  $msg = GUIGetMsg()
	  Select
	  Case $msg = $GUI_EVENT_CLOSE
		 ExitLoop
	  Case $msg = $gBrowseImagesFolder
		 GUICtrlSetData($gImagesFolderPath, FileSelectFolder("Выберите каталог", "", 1, @DocumentsCommonDir & "\Wallpapers"))
	  Case $msg = $gSaveSettingsToREG
		 if SaveSettingsToREG() Then
			ExitLoop
		 EndIf
	  Case $msg = $gCreateLoginINIFile
		 If $runUnderAdminFromUser = 1 Then
			if Not FileExists($INIFILE) Then
			   Filewrite($INIFILE, "")
			   IniWrite($INIFILE, "CREDENTIALS", "user", @UserName)
			   If $cryptAdminPassword <> "" Then IniWrite($INIFILE, "CREDENTIALS", "password", $cryptAdminPassword)
			Else
			   MsgBox(48, "Cоздание ini-файла", "Файл '" & $INIFILE & "' уже существует.")
			EndIf
		 Else
			MsgBox(48, "Cоздание ini-файла", "Невозможно создать ini-файл, так как не был введен пароль администратора.")
		 EndIf
	  Case $msg = $gExitProgram
		 Exit
	  EndSelect
   WEnd
   GUISetState(@SW_HIDE, $window)
EndFunc


Func OpenAbout()
   TrayTip("О программе " & $sProgramName & " " & $sProgramVersion, "Программа предназначена для смены фона рабочего стола по таймеру." & @LF & "Смена фона рабочего стола вручную производится двойным нажатием на иконку программы в трее." & @LF & "Все права на данную программу принадлежат 'unchase'. Ноябрь 2017 г.", 10, 1)
EndFunc


Func UserCanChangeWallpaper()
   If $cantUserChangeWallpaper = 1 Then
	  If $runUnderAdminFromUser = 0 Then
		 $cantUserChangeWallpaper = 0
		 TrayItemSetState($tCantUserChangeWallpaper, 4)
		 RegWrite("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop", "NoChangingWallpaper", "REG_DWORD", $cantUserChangeWallpaper)
		 RegWrite("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System", "NoDispScrSavPage", "REG_DWORD", $cantUserChangeWallpaper)
	  Else
		 TrayTip("Изменение разрешений", "Только администратор может давать разрешение пользователям на изменение фона рабочего стола.", 5, 2)
		 TrayItemSetState($tCantUserChangeWallpaper, 1)
	  EndIf
   Else
	  $cantUserChangeWallpaper = 1
	  TrayItemSetState($tCantUserChangeWallpaper, 1)
	  RegWrite("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop", "NoChangingWallpaper", "REG_DWORD", $cantUserChangeWallpaper)
	  RegWrite("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System", "NoDispScrSavPage", "REG_DWORD", $cantUserChangeWallpaper)
   EndIf
EndFunc


Func Halt()
   If $runUnderAdminFromUser = 0 Then
	  if $doit Then
		 $doit = 0
		 TrayItemSetState($thalt, 1)
	  Else
		 $doit = 1
		 TrayItemSetState($thalt, 4)
	  EndIf
   Else
	  TrayTip("Приостановка программы " & $sProgramName & " " & $sProgramVersion, "Только администратор может приостанавливать программу.", 5, 2)
	  TrayItemSetState($thalt, 4)
   EndIf
EndFunc


Func SetRandomWallpaper()
   $hTimer = TimerInit()
   If $imageFilesList <> '' Then
	  $newImageFileNotFind = 1
	  While $newImageFileNotFind
		 $i = Random(1, UBound($imageFilesList, 1) - 1, 1)
		 If StringTrimRight($currentWallpaper, 4) <> StringTrimRight($imageFilesList[$i], 4) Then
			$newImageFileNotFind = 0
			$currentWallpaper = $imageFilesList[$i]

			$sFileExt = StringLower(StringRight($currentWallpaper, 4))
			If $sFileExt <> '.bmp' And _WinAPI_GetVersion() < 6.0 Then
			   $oldWallpaper = $currentWallpaper
			   $currentWallpaper = _ImageSaveToBMP($currentWallpaper, $imagesFolderPath, Default, False, False)
			   FileDelete($oldWallpaper)
			   If @error Then ContinueLoop
			Else
			   If _WinAPI_GetVersion() >= 6.0 And $sFileExt <> '.bmp' And $sFileExt <> '.jpg' Then
				  $oldWallpaper = $currentWallpaper
				  $currentWallpaper = _ImageSaveToBMP($currentWallpaper, $imagesFolderPath, Default, False, False)
				  FileDelete($oldWallpaper)
				  If @error Then ContinueLoop
			   Else
				  If _WinAPI_GetVersion() >= 6.0 And ($sFileExt = '.bmp' Or $sFileExt = '.jpg') Then

				  EndIf
			   EndIf
			EndIf

			If $currentWallpaper <> "" Then _ChangeDesktopWallpaper($currentWallpaper, $stretchMode)
		 EndIf
	  WEnd
   EndIf
EndFunc


Func ExitScript()
   If $runUnderAdminFromUser = 0 Then
	  Exit
   Else
	  TrayTip("Выход из программы " & $sProgramName & " " & $sProgramVersion, "Только администратор может выйти из программы.", 5, 2)
   EndIf
EndFunc

; открываем каталог с обоями, используемые для размещения на рабочем столе
Func OpenWallpaperFolder()
	run('explorer.exe /select,' & $currentWallpaper)
EndFunc

; сохраняем измененные значения (настройки) в реестр
Func SaveSettingsToREG()
   $imagesFolderPath = GUICtrlRead($gImagesFolderPath)
   $stretchMode = _GUICtrlComboBox_GetCurSel($gList)
   $timeout = GUICtrlRead($gTimeout)
   $timeoutPeriod = GUICtrlRead($gTimeoutPeriod)
   $autoRun = GUICtrlRead($gAutoRun)
   $denyRunTaskManager = GUICtrlRead($gDenyRunTaskManager)

   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "Timeout", "REG_SZ", $timeout)
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "TimeoutPeriod", "REG_SZ", $timeoutPeriod)
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "StretchMode", "REG_SZ", $stretchMode)
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "AutoRun", "REG_SZ", $autoRun)
   RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "DenyRunTaskManager", "REG_DWORD", $denyRunTaskManager)
   Select
	  Case not FileExists($imagesFolderPath)
		 If MsgBox(36, "Сохранение параметров в реестр", "Каталог с изображениями '" & $imagesFolderPath & "' не существует. Создать его?") = 6 Then
			DirCreate($imagesFolderPath)
			RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "ImagesFolderPath", "REG_SZ", $imagesFolderPath)
			$imageFilesList = _FileListToArrayEx($imagesFolderPath, "*.jpg|*.bmp", 8)
		 EndIf
		 return 0
	  case Else
		 RegWrite("HKEY_LOCAL_MACHINE\Software\" & $sProgramName, "ImagesFolderPath", "REG_SZ", $imagesFolderPath)
		 $imageFilesList = _FileListToArrayEx($imagesFolderPath, "*.jpg|*.bmp", 8)
		 Return 1
   EndSelect
EndFunc


; #FUNCTION# ====================================================================================================================
; Имя ...................: 	_ImageSaveToBMP
; Описание ..............: 	Конвертирует изображение в формат bmp
; Синтаксис .............: 	_ImageSaveToBMP($sPath[, $sDestPath = @ScriptDir[, $sName = Default[, $bOverwrite = False[, $bDelOrig = False]]]])
; Параметры .............: 	$sPath               - A string value.
;                  			$sDestPath           - The path where to save the converted image. Default is @ScriptDir.
;                  			$sName               - The name of the converted image. Default is the original photo name.
;                  			$bOverwrite          - Overwrite the converted file if already exist. Default is False.
;                  			$bDelOrig            - Delete the original file after conversion. Default is False.
; Возвращаемые значения .: 	On Success - Return the new file names
;                  			On Failure -
;                               @error = 1 The file to be converted doesn't not exist
;                               @error = 2 The image is already a bmp file
;                               @error = 3 Invalid file extension
;                               @error = 4 The destination path doesn't not exist
;                               @error = 5 Invalid file name
;                               @error = 6 The destination file already exist
;                               @error = 7 Unable to overwrite the destination file
;                               @error = 8 Unable to save the bmp file
; Автор .................: 	Nessie
; Изменен ...............:	Unchase
; Пример ................: _ImageSaveToBMP(@DesktopDir & "\nessie.jpg")
; ===============================================================================================================================
Func _ImageSaveToBMP($sPath, $sDestPath = @ScriptDir, $sName = Default, $bOverwrite = False, $bDelOrig = False)
   Local $bCheckExt = False

   If Not FileExists($sPath) Then Return SetError(1, 0, "")

   Local $sImageExt = StringLower(StringTrimLeft($sPath, StringInStr($sPath, '.', 0, -1)))

   If $sImageExt = "bmp" Then SetError(2, 0, "")

   Local $aAllowedExt[5] = ['gif', 'jpeg', 'jpg', 'png', 'tiff']

   For $i = 0 To UBound($aAllowedExt) - 1
	  If $sImageExt = $aAllowedExt[$i] Then
		 $bCheckExt = True
		 ExitLoop
	  EndIf
   Next

   If $bCheckExt = False Then Return SetError(3, 0, "")

   If Not FileExists($sDestPath) Then Return SetError(4, 0, "")

   If $sName = Default Then
	  $sName = StringTrimLeft($sPath, StringInStr($sPath, '\', 0, -1))
	  $sName = StringTrimRight($sName, 4)
   Else
	  If $sName = "" Then Return SetError(5, 0, "")
   EndIf

   If Not $bOverwrite Then
	  If FileExists($sDestPath & "\" & $sName & ".bmp") Then
		 Return $sDestPath & "\" & $sName & ".bmp"
	  EndIf
   Else
	  FileDelete($sDestPath & "\" & $sName & ".bmp")
	  If @error Then
		 Return SetError(7, 0, "")
	  EndIf
   EndIf

   _GDIPlus_Startup()

   Local $hImage = _GDIPlus_ImageLoadFromFile($sPath)
   Local $sCLSID = _GDIPlus_EncodersGetCLSID("BMP")

   _GDIPlus_ImageSaveToFileEx($hImage, $sDestPath & "\" & $sName & ".bmp", $sCLSID)

   If @error Then
	  _GDIPlus_ImageDispose($hImage)
	  _GDIPlus_Shutdown()
	  Return SetError(8, 0, "")
   EndIf

   _GDIPlus_ImageDispose($hImage)
   _GDIPlus_Shutdown()

   If $bDelOrig Then
	  FileDelete($sPath)
	  If @error Then Return SetError(8, 0, "")
   EndIf

   Return $sDestPath & "\" & $sName & ".bmp"
EndFunc   ;==>_ImageSaveToBMP

; меняем размер изображения
 Func _ImageResize($sImagePath, $sOutImage, $iW, $iH)
   Local $hWnd, $hDC, $hBMP, $hImage1, $hImage2, $hGraphic, $CLSID, $i = 0, $Ext

   ;Старт GDIPlus
   _GDIPlus_Startup()

   ;OutFile path, to use later on.
   Local $sOP = StringLeft($sOutImage, StringInStr($sOutImage, "\", 0, -1))
   ;OutFile name, to use later on.
   Local $sOF = StringMid($sOutImage, StringInStr($sOutImage, "\", 0, -1) + 1)

   $hImage2 = _GDIPlus_ImageLoadFromFile ($sImagePath) ; загружаем файл рисунка
   $iWidth = _GDIPlus_ImageGetWidth($hImage2) ; получаем его размеры
   $iHeight = _GDIPlus_ImageGetHeight($hImage2)


   If $iW = $iWidth And $iH = $iHeight And $sImagePath = $sOutImage Then
	  _GDIPlus_ImageDispose($hImage2)
	  _GDIPlus_Shutdown()
	  Return $sImagePath
   EndIf


   $aWH =_Coor($iW, $iH, $iWidth, $iHeight) ; возвращает пропорциональные координаты по наименьшему

   ; WinAPI для создания пустого bitmap с шириной и высотой, для вставки изменёного рисунка.
   $hWnd = _WinAPI_GetDesktopWindow()
   $hDC = _WinAPI_GetDC($hWnd)
   $hBMP = _WinAPI_CreateCompatibleBitmap($hDC, $iW, $iH)
   _WinAPI_ReleaseDC($hWnd, $hDC)

   ;Возвращает дескриптор пустого bitmap созданного ранее в виде изображения
   $hImage1 = _GDIPlus_BitmapCreateFromHBITMAP ($hBMP)

   ; Создаём графический контекст пустого bitmap
   $hGraphic = _GDIPlus_ImageGetGraphicsContext ($hImage1)

   ; Рисует загруженное изображение в пустом bitmap нужного размера
   _GDIPLus_GraphicsDrawImageRect($hGraphic, $hImage2, Abs($iW - $aWH[0]) / 2, Abs ($iH - $aWH[1]) / 2, $aWH[0], $aWH[1])

   ; Расширение файла, чтобы получить CLSID декодера.
   $Ext = StringUpper(StringMid($sOutImage, StringInStr($sOutImage, ".", 0, -1) + 1))
   ; Возвращает декодер, чтобы сохранить изменённое изображение в нужном формате.
   $CLSID = _GDIPlus_EncodersGetCLSID($Ext)

   ;Generate a number for out file that doesn't already exist, so you don't overwrite an existing image.
   Do
	  $i += 1
   Until (Not FileExists($sOP & $i & "_" & $sOF))

   ;Prefix the number to the begining of the output filename
   $sOutImage = $sOP & $i & "_" & $sOF

   ; Сохраняет изменённый рисунок.
   $TrOut =_GDIPlus_ImageSaveToFileEx($hImage1, $sOutImage, $CLSID)

   ; Очищает и закрывает GDIPlus.
   _GDIPlus_ImageDispose($hImage1)
   _GDIPlus_ImageDispose($hImage2)
   _GDIPlus_GraphicsDispose ($hGraphic)
   _WinAPI_DeleteObject($hBMP)
   _GDIPlus_Shutdown()
   Return $sOutImage
EndFunc


; Вычисление размера рисунка для пропорционального преобразования
Func _Coor($x1, $y1, $x2, $y2)
   Local $aXY[2] = [0,0], $kX=$x1/$x2, $kY=$y1/$y2
   If Abs($x1-$x2)<3 And Abs($y1-$y2)<3 Then ; если размер почти совпадает, то возврат родных координат, отказ от преобразования
	  $aXY[0]=$x2
	  $aXY[1]=$y2
	  Return SetError(0, 1, $aXY)
   EndIf
   If $kX>$kY Then
	  $aXY[0]=Round($x2*$kY)
	  $aXY[1]=$y1
   Else
	  $aXY[0]=$x1
	  $aXY[1]=Round($y2*$kX)
   EndIf
   Return SetError(0, 0, $aXY)
EndFunc


Func _ChangeDesktopWallpaper($sImage, $style = 0)
;===============================================================================
;
; Function Name:    _ChangeDesktopWallPaper
; Description:     	Update WallPaper Settings
; Usage:          	_ChangeDesktopWallPaper(@WindowsDir & '\' & 'zapotec.bmp',1)
; Parameter(s):  	$sImage - Full Path to image file (*.bmp or *.jpg)
;                   [$style] - 0 = Centered, 1 = Tiled, 2 = Stretched, 3 = Filled, 4 = Fit, 5 = Screen Width
; Requirement(s):   None.
; Return Value(s):  On Success - Returns 1
;                  	On Failure -   -1
; Author(s):        FlyingBoz
; Modified: 		Unchase
; Thanks:        	Larry - DllCall Example - Tested and Working under XPHome and W2K Pro
;                   Excalibur - Reawakening my interest in Getting This done.
;
;===============================================================================

   If Not FileExists($sImage) Then Return -1
   $localStyle = $style
  ;The $SPI*  values could be defined elsewhere via #include - if you conflict,
  ; remove these, or add if Not IsDeclared "SPI_SETDESKWALLPAPER" Logic
   Local $SPI_SETDESKWALLPAPER = 20
   Local $SPIF_UPDATEINIFILE = 1
   Local $SPIF_SENDCHANGE = 2
   Local $REG_DESKTOP = "HKEY_CURRENT_USER\Control Panel\Desktop"

   Local $sImageExt = StringLower(StringRight($sImage, 4))
   Local $winVersion = _WinAPI_GetVersion()
   ; если версия windows ниже vista (XP, например)
   If $winVersion < "6.0" Then
	  If $localStyle > 2 Then
		 $localStyle = 0
		 $newResizedImagePath = _ImageResize($sImage, $sImage, @DesktopWidth, @DesktopHeight)
;~ 		 If FileExists(StringTrimRight($sImage, 4) & ".jpg") Then FileDelete(StringTrimRight($sImage, 4) & ".jpg")
		 FileMove($newResizedImagePath, $sImage, 1)
	  EndIf
	  If $sImageExt <> '.bmp' Then
		 Return -1
	  EndIf
   Else
	  If $winVersion >= 6.0 And $sImageExt <> '.bmp' And $sImageExt <> '.jpg' Then
		 Return -1
	  EndIf
   EndIf

   Select
   Case $localStyle = 0
	  RegWrite($REG_DESKTOP,'TileWallpaper','REG_SZ','0')
	  RegWrite($REG_DESKTOP,'WallpaperStyle','REG_SZ','0')
   Case $localStyle = 1
	  RegWrite($REG_DESKTOP,'TileWallpaper','REG_SZ','1')
	  RegWrite($REG_DESKTOP,'WallpaperStyle','REG_SZ','0')
   Case $localStyle = 2
	  RegWrite($REG_DESKTOP,'TileWallpaper','REG_SZ','0')
	  RegWrite($REG_DESKTOP,'WallpaperStyle','REG_SZ','2')
   Case $localStyle = 3
	  RegWrite($REG_DESKTOP,'TileWallpaper','REG_SZ','0')
	  RegWrite($REG_DESKTOP,'WallpaperStyle','REG_SZ','10')
   Case $localStyle = 4
	  RegWrite($REG_DESKTOP,'TileWallpaper','REG_SZ','0')
	  RegWrite($REG_DESKTOP,'WallpaperStyle','REG_SZ','6')
   Case $localStyle = 5
	  RegWrite($REG_DESKTOP,'TileWallpaper','REG_SZ','0')
	  RegWrite($REG_DESKTOP,'WallpaperStyle','REG_SZ','4')
   Case Else

   EndSelect
   RegWrite($REG_DESKTOP, 'Wallpaper', 'REG_SZ', $sImage)

   $ret = DllCall(@SystemDir & "\user32.dll", "int", "SystemParametersInfo", _
         "int", $SPI_SETDESKWALLPAPER, _
         "int", 0, _
         "str", $sImage, _
         "int", BitOR($SPIF_UPDATEINIFILE, $SPIF_SENDCHANGE))

   If @error Then MsgBox(16, "Ошибка при вызове dll-функции", "Ошибка = ", @error)

   ; записываем в реестр необходимые параметры
   RegWrite($regPath, "Second", "REG_SZ", @SEC)
   RegWrite($regPath, "Minute", "REG_SZ", @MIN)
   RegWrite($regPath, "Hour", "REG_SZ", @HOUR)
   RegWrite($regPath, "Day", "REG_SZ", @MDAY)
   RegWrite($regPath, "Month", "REG_SZ", @MON)
   RegWrite($regPath, "Year", "REG_SZ", @YEAR)
   GetDateTimeFromREG()
   $canCheckTimePeriod = 1

   Return 1
EndFunc  ;==>_ChangeDestopWallpaper


Func CheckCredentials($userLogin, $userPassword)
   $d_LogonUser = DllStructCreate("HANDLE")
   Local Const $LOGON32_LOGON_INTERACTIVE = 2
   DllCall("advapi32.dll", "BOOLEAN", "LogonUser", "str", $userLogin, "str", @ComputerName, "str", $userPassword, "dword", $LOGON32_LOGON_INTERACTIVE, "dword", 0, "ptr", DllStructGetPtr($d_LogonUser))
   If DllStructGetData($d_LogonUser, 1) Then
	  Return 1
   Else
	  Return 0
   EndIf
EndFunc


; #FUNCTION# ========================================================================================================================
; Name...........: _FileListToArray
; Description ...: Lists files and\or folders in a specified path (Similar to using Dir with the /B Switch)
; Syntax.........: _FileListToArray($sPath[, $sFilter = "*"[, $iFlag = 0]])
; Parameters ....: $sPath   - Path to generate filelist for.
;                 $sFilter - Optional the filter to use, default is *. (Multiple filter groups such as "All "*.png|*.jpg|*.bmp") Search the Autoit3 helpfile for the word "WildCards" For details.
;                 $iFlag   - Optional: specifies whether to return files folders or both Or Full Path (add the flags together for multiple operations):
;                 |$iFlag = 0 (Default) Return both files and folders
;                 |$iFlag = 1 Return files only
;                 |$iFlag = 2 Return Folders only
;                 |$iFlag = 4 Search subdirectory
;                 |$iFlag = 8 Return Full Path
; Return values .: @Error - 1 = Path not found or invalid
;                 |2 = Invalid $sFilter
;                 |3 = Invalid $iFlag
;                 |4 = No File(s) Found
; Author ........: SolidSnake <MetalGX91 at GMail dot com>
; Modified.......: Unchase
; Remarks .......: The array returned is one-dimensional and is made up as follows:
;                               $array[0] = Number of Files\Folders returned
;                               $array[1] = 1st File\Folder
;                               $array[2] = 2nd File\Folder
;                               $array[3] = 3rd File\Folder
;                               $array[n] = nth File\Folder
; Related .......:
; Link ..........:
; Example .......: Yes
; Note ..........: Special Thanks to Helge and Layer for help with the $iFlag update speed optimization by code65536, pdaughe
;                 Update By DXRW4E
; ===================================================================================================================================
Func _FileListToArrayEx($sPath, $sFilter = "*", $iFlag = 0)
   Local $hSearch, $sFile, $sFileList, $iFlags = StringReplace(BitAND($iFlag, 1) + BitAND($iFlag, 2), "3", "0"), $sSDir = BitAND($iFlag, 4), $FPath = "", $sDelim = "|", $sSDirFTMP = $sFilter
   $sPath = StringRegExpReplace($sPath, "[\\/]+\z", "") & "\" ; ensure single trailing backslash
   If Not FileExists($sPath) Then Return SetError(1, 1, "")
   If BitAND($iFlag, 8) Then $FPath = $sPath
   If StringRegExp($sFilter, "[\\/:><]|(?s)\A\s*\z") Then Return SetError(2, 2, "")
   If Not ($iFlags = 0 Or $iFlags = 1 Or $iFlags = 2 Or $sSDir = 4 Or $FPath <> "") Then Return SetError(3, 3, "")
   $hSearch = FileFindFirstFile($sPath & "*")
   If @error Then Return SetError(4, 4, "")
   Local $hWSearch = $hSearch, $hWSTMP = $hSearch, $SearchWD, $sSDirF[3] = [0, StringReplace($sSDirFTMP, "*", ""), "(?i)(" & StringRegExpReplace(StringRegExpReplace(StringRegExpReplace(StringRegExpReplace(StringRegExpReplace(StringRegExpReplace("|" & $sSDirFTMP & "|", '\|\h*\|[\|\h]*', "\|"), '[\^\$\(\)\+\[\]\{\}\,\.\=]', "\\$0"), "\|([^\*])", "\|^$1"), "([^\*])\|", "$1\$\|"), '\*', ".*"), '^\||\|$', "") & ")"]
   While 1
	  $sFile = FileFindNextFile($hWSearch)
	  If @error Then
		 If $hWSearch = $hSearch Then ExitLoop
		 FileClose($hWSearch)
		 $hWSearch -= 1
		 $SearchWD = StringLeft($SearchWD, StringInStr(StringTrimRight($SearchWD, 1), "\", 1, -1))
	  ElseIf $sSDir Then
		 $sSDirF[0] = @extended
		 If ($iFlags + $sSDirF[0] <> 2) Then
			If $sSDirF[1] Then
			   If StringRegExp($sFile, $sSDirF[2]) Then $sFileList &= $sDelim & $FPath & $SearchWD & $sFile
			Else
			   $sFileList &= $sDelim & $FPath & $SearchWD & $sFile
			EndIf
		 EndIf
		 If Not $sSDirF[0] Then ContinueLoop
		 $hWSTMP = FileFindFirstFile($sPath & $SearchWD & $sFile & "\*")
		 If $hWSTMP = -1 Then ContinueLoop
		 $hWSearch = $hWSTMP
		 $SearchWD &= $sFile & "\"
	  Else
		 If ($iFlags + @extended = 2) Or StringRegExp($sFile, $sSDirF[2]) = 0 Then ContinueLoop
		 $sFileList &= $sDelim & $FPath & $sFile
	  EndIf
   WEnd
   FileClose($hSearch)
   If Not $sFileList Then Return SetError(4, 4, "")
   Return StringSplit(StringTrimLeft($sFileList, 1), "|")
EndFunc


;===============================================================================
;
; Function Name:    __StringEncrypt()
; Description:      RC4 Based string encryption/decryption
; Parameter(s):     $i_Encrypt - 1 to encrypt, 0 to decrypt
;                   $s_EncryptText - string to encrypt
;                   $s_EncryptPassword - string to use as an encryption password
;                   $i_EncryptLevel - integer to use as number of times to encrypt string
; Requirement(s):   None
; Return Value(s):  On Success - Returns the encrypted string
;                   On Failure - Returns a blank string and sets @error = 1
; Author(s):        (Original _StringEncrypt) Wes Wolfe-Wolvereness <Weswolf at aol dot com>
;                   (Modified __StringEncrypt) PsaltyDS at www.autoitscript.com/forum
;                   (RC4 function) SkinnyWhiteGuy at www.autoitscript.com/forum
;===============================================================================
;  1.0.0.0  |  03/08/08  |  First version posted to Example Scripts Forum
;===============================================================================
Func __StringEncrypt($i_Encrypt, $s_EncryptText, $s_EncryptPassword, $i_EncryptLevel = 1)
   Local $RET, $sRET = "", $iBinLen, $iHexWords

   ; Sanity check of parameters
   If $i_Encrypt <> 0 And $i_Encrypt <> 1 Then
	  SetError(1)
	  Return ''
   ElseIf $s_EncryptText = '' Or $s_EncryptPassword = '' Then
	  SetError(1)
	  Return ''
   EndIf
   If Number($i_EncryptLevel) <= 0 Or Int($i_EncryptLevel) <> $i_EncryptLevel Then $i_EncryptLevel = 1

   ; Encrypt/Decrypt
   If $i_Encrypt Then
	  ; Encrypt selected
	  $RET = $s_EncryptText
	  For $n = 1 To $i_EncryptLevel
		 If $n > 1 Then $RET = Binary(Random(0, 2 ^ 31 - 1, 1)) & $RET & Binary(Random(0, 2 ^ 31 - 1, 1)) ; prepend/append random 32bits
		 $RET = rc4($s_EncryptPassword, $RET) ; returns binary
	  Next

	  ; Convert to hex string
	  $iBinLen = BinaryLen($RET)
	  $iHexWords = Int($iBinLen / 4)
	  If Mod($iBinLen, 4) Then $iHexWords += 1
	  For $n = 1 To $iHexWords
		 $sRET &= Hex(BinaryMid($RET, 1 + (4 * ($n - 1)), 4))
	  Next
	  $RET = $sRET
   Else
	  ; Decrypt selected
	  ; Convert input string to primary binary
	  $RET = Binary("0x" & $s_EncryptText) ; Convert string to binary

	  ; Additional passes, if required
	  For $n = 1 To $i_EncryptLevel
		 If $n > 1 Then
			$iBinLen = BinaryLen($RET)
			$RET = BinaryMid($RET, 5, $iBinLen - 8) ; strip random 32bits from both ends
		 EndIf
		 $RET = rc4($s_EncryptPassword, $RET)
	  Next
	  $RET = BinaryToString($RET)
   EndIf

   ; Return result
   Return $RET
EndFunc   ;==>__StringEncrypt

; -------------------------------------------------------
; Function:  rc4
; Purpose:  An encryption/decryption RC4 implementation in AutoIt
; Syntax:  rc4($key, $value)
;   Where:  $key = encrypt/decrypt key
;       $value = value to be encrypted/decrypted
; On success returns encrypted/decrypted version of $value
; Author:  SkinnyWhiteGuy on the AutoIt forums at www.autoitscript.com/forum
; Notes:  The same function encrypts and decrypts $value.
; -------------------------------------------------------
Func rc4($key, $value)
   Local $S[256], $i, $j, $c, $t, $x, $y, $output
   Local $keyLength = BinaryLen($key), $valLength = BinaryLen($value)
   For $i = 0 To 255
	  $S[$i] = $i
   Next
   For $i = 0 To 255
	  $j = Mod($j + $S[$i] + Dec(StringTrimLeft(BinaryMid($key, Mod($i, $keyLength) + 1, 1), 2)), 256)
	  $t = $S[$i]
	  $S[$i] = $S[$j]
	  $S[$j] = $t
   Next
   For $i = 1 To $valLength
	  $x = Mod($x + 1, 256)
	  $y = Mod($S[$x] + $y, 256)
	  $t = $S[$x]
	  $S[$x] = $S[$y]
	  $S[$y] = $t
	  $j = Mod($S[$x] + $S[$y], 256)
	  $c = BitXOR(Dec(StringTrimLeft(BinaryMid($value, $i, 1), 2)), $S[$j])
	  $output = Binary($output) & Binary('0x' & Hex($c, 2))
   Next
   Return $output
EndFunc   ;==>rc4
