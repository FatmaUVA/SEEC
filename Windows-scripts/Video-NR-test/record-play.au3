#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here


#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <ButtonConstants.au3>
#include <FontConstants.au3>
#include <AutoItConstants.au3>
#include <ScreenCapture.au3>

Opt("WinTitleMatchMode", -2)
$vidLength = 37000

;close command prompt
WinActivate("Command Prompt","")
WinClose("Command Prompt","")

;Focus OBS studion
$hOBS = WinWait("OBS","obs64")
WinActivate($hOBS)
ControlFocus($hOBS,"obs64","Qt5QWindowIcon9")

;Start recoding and wait
;WinActivate($hOBS)
;ControlFocus($hOBS,"obs64","Qt5QWindowIcon9")
ControlSend($hOBS, "obs64","Qt5QWindowIcon9","{RALT}")
;MsgBox(0,"Start","start",1)
;ControlClick($hOBS, "obs64","Qt5QWindowIcon1", "left", 1,194,59)

Sleep($vidLength)

;Stop Recoding
;WinActivate($hOBS)
;ControlFocus($hOBS,"obs64","Qt5QWindowIcon9")

ControlSend($hOBS, "obs64","Qt5QWindowIcon9","{RCTRL}")
;MsgBox(0,"Stop","stop",1)
;ControlClick($hOBS, "obs64","Qt5QWindowIcon1", "left", 1,194,59)
;Sleep(1000)


