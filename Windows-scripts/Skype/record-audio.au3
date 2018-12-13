#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Fatma Alali
 Script Function:
	record audio, takes 1 input: "start" (to start recording), "stop" (to stop recording), "parse" (to parse results
	If "parse is used" one more input is required "rtt" value
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


Opt("WinTitleMatchMode",-2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase ;used for WInWaitActive title matching

Local $appName  = "C:\Program Files (x86)\Audacity\audacity.exe"
Local $winTitle = "Audacity"
Local $audio_len = 5000;in ms
;Local $task = "start" ;$CmdLine[1]
Global $loss = "00" ;$CmdLine[2]
Global $hApp =""
Global $app = "Skype"
Global $runNo = "3-model3"
Local $logDir = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype"

;============================= Create a file for results======================
; Create file in same folder as script
Global $sFileName = $logDir &"\" & $app &"_PESQ_run_"& $runNo  ;".txt"

; Open file
Global $hFilehandle = FileOpen($sFileName, $FO_APPEND)

; Prove it exists
If FileExists($sFileName) Then
    ;MsgBox($MB_SYSTEMMODAL, "File", "Exists")
Else
    MsgBox($MB_SYSTEMMODAL, "File", "Does not exist")
EndIf

;============================ start recording=====================

start_record()

If $loss <> 0 Then
	;parse results and compute PESQ
	parse()




Func start_record()
	ShellExecute($appName)
	$hApp = WinWaitActive($winTitle)
	Sleep(1000)
	;start recording
	Send("+R") ; Shift(+) and R to start recording in audacity
	Sleep($audio_len)
	Send("{SPACE}") ; stop recording
	Sleep(600)
	;export to WAV
	Send("^+E"); CTRL SHIFT E
	Sleep(600)
	;type file name
	Send("loss-" & $loss)
	Send("{ENTER}")
	Send("{ENTER}")

EndFunc

Func parse()
EndFunc


