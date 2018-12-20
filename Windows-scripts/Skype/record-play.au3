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
Global $winTitle = "Audacity"
;Local $audio_len = 5000;in ms
Global $loss = $CmdLine[1] ;"model1-16-ref"
Global $hApp =""
Global $app = "Skype"
Global $ref_audio = "loss-model1-16-ref.wav" ; audio file to use as refernce for PESQ calculation
Global $audio_file = "u_am1s03.wav" ;audio file to feed to SKype
Global $audio_len = 6500 ;8500 ;6500;in s


start_record()
play_audio()
stop_record()
parse($loss)
;If Number($loss) > 0 or $loss == "0-5" Then
	;parse results and compute PESQ
;	parse($loss)
;EndIf

;close audio file
WinClose("Windows Media Player")

Func start_record()
	ShellExecute($appName)
	$hApp = WinWaitActive($winTitle)
	Sleep(2000)
	;start recording
	Send("+R") ; Shift(+) and R to start recording in audacity
EndFunc

Func play_audio()
	Local $appName  = "C:\Users\fha6np\Desktop\" & $audio_file
	Local $winTitle = "Windows Media Player"

	ShellExecute($appName)
	$hApp = WinWaitActive($winTitle)
	Sleep($audio_len)
	return $hApp
EndFunc


Func stop_record()
   ;activate app window first
	WinActivate($winTitle)
	;Sleep(1000)
	Send("{SPACE}") ; stop recording
	Sleep(600)
	;export to WAV
	Send("^+E"); CTRL SHIFT E
	Sleep(600)
	Send("loss-" & $loss)
	Sleep(1000)
	Send("{ENTER}")
	Send("{ENTER}")
	Send("{ENTER}")
	Send("{ENTER}")
	Sleep(2000)
	WinClose($winTitle)
	Send("{TAB}")
	Send("{Enter}")
EndFunc

Func parse($loss)
	OpenTerminal()
	Sleep(600)
	$cmd = "C:\cygwin64\home\fha6np\ITU-T_pesq\bin\itu-t-pesq2005.exe  C:\Users\fha6np\Desktop\" & $ref_audio & "  C:\Users\fha6np\Desktop\loss-" & $loss &".wav {+}16000"
	Send($cmd)
	Send("{ENTER}")
	Sleep(2500) ;2500)
	While WinClose("cmd")
	WEnd

	;delete files
	;FileDelete("C:\Users\fha6np\Desktop\loss-" & $loss &".wav")
	;FileDelete("C:\Users\fha6np\Desktop\loss-0.wav")
EndFunc

Func OpenTerminal()
   MouseClick("left",25,1030,1)
   Sleep(500)
   Send("cmd")
   Send("{ENTER}")
   Sleep(500)
EndFunc


