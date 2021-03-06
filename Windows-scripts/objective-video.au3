#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Fatma Alali
 Script Function:
	VIdeo objective test
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

; ============================ Parameters initialization ====================
; QoS
Local $aRTT[1] = [0] ;,50, 150]
Local $aLoss[1] = [0] ;,0.05,1] ;packet loss rate, unit is %
Local $videoDir = "C:\Users\Harlem1\SEEC\Windows-scripts\"
Local $vdieoName= ["Zootopia.mp4" , "Zootopia.mp4"] ;"out-1fps.mp4"]
Local $activity = "video"
GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected
GLobal $routerUsr = "harlem1"
Global $routerPsw = "harlem"

;============================= Create a file for results======================
; Create file in same folder as script
;Global $sFileName = @ScriptDir &"\" & $activity &"-objective.txt"

; Open file
;Global $hFilehandle = FileOpen($sFileName, $FO_APPEND)

; Prove it exists
;If FileExists($sFileName) Then
   ; MsgBox($MB_SYSTEMMODAL, "File", "Exists")
;Else
   ; MsgBox($MB_SYSTEMMODAL, "File", "Does not exist")
 ;EndIf


For $i = 0 To UBound($aRTT) - 1
   For $j = 0 To UBound($aLoss) - 1
		Local $videoSpeed = ["regular" , "slow"]
		For $k= 0 To  UBound($videoSpeed) - 1

		  If $videoSpeed[$k] = "regular" Then
			  $video = $vdieoName[0]
		  Else
			  $video = $vdieoName[1]
		  EndIf

		  ; start packet capture
		  router_command("start_capture", $videoSpeed[$k])


;================== start video ===========================
		  ;log time
		  Local $hTimer = TimerInit() ;begin the timer and store the handler

		  ;start the video at regular speed
		  ShellExecute($videoDir & $video)
		  ;ShellExecute($videoDir & $vdieoName)
		  Sleep(5000)
		  ;wait till the video ends, when the video ends the title of the VLC media player will change and that's what I'm using to detect ends of video
		  Local $hVLC = WinWaitActive("VLC media player")
		  Local $timeDiff = TimerDiff($hTimer) ; find the time difference from the first call of TImerInit

		  WinClose($hVLC)

		  ;MsgBox($MB_OK,"Info","Video finished and it took "& $timeDiff & " ms to finish")

		  ; stop capture
		  router_command("stop_capture")

		  ; store the time of the video based on the video speed
		  If $videoSpeed[$k] = "regular" Then
			  Global $reg_time = $timeDiff
		  Else
			  Global $slow_time = $timeDiff
		  EndIf
		Next
		;send times for analysis
		router_command("analyze", "slow", $aRTT[$i] , $aLoss[$j]) ; here the second param doesn't matter
   Next
Next



Func router_command($cmd, $videoSpeed="slow", $rtt=0, $loss=0); cmd: "start_capture", "stop_capture", "analyze"
	; open putty
	ShellExecute("C:\Program Files\PuTTY\putty")
	;ShellExecute($videoDir & $vdieoName)
	Local $hPutty = WinWaitActive("PuTTY Configuration")

	;connect to the router linux server
	Send($routerIP)
	ControlClick($hPutty, "","Button1", "left", 1,8,8)

	Local $hShell = WinWaitActive($routerIP & " - PuTTY")
	Sleep(500)
	Send($routerUsr)
	Send("{ENTER}")
	Send($routerPsw)
	Send("{ENTER}")
	Sleep(500)

	If $cmd = "start_capture" Then

	  ;run the capture /home/fatma/SEEC/Windows-scripts
	  Local $command = "sudo sh /home/harlem1/SEEC/Windows-scripts/start-tcpdump.sh " & $routerIF & " " & $videoSpeed
	  Send($command)
	  Send("{ENTER}")
	  Sleep(500)
	  Send($routerPsw)
	  Send("{ENTER}")

	ElseIf $cmd = "stop_capture" Then
	  $command = "sudo killall tcpdump"
	  Send($command)
	  Send("{ENTER}")
	  Sleep(500)
	  Send($routerPsw)
	  Send("{ENTER}")

	ElseIf $cmd = "analyze" Then
	  $command = "sudo bash SEEC/Windows-scripts/analyze.sh " & $slow_time & " " & $reg_time & " " & $rtt & " " & $loss
	  Send($command)
	  Send("{ENTER}")
	  Sleep(300)
	  Send($routerPsw)
	  Send("{ENTER}")

	EndIf

	;close putty
	Sleep(500)
	Send("exit")
	Send("{ENTER}")

EndFunc
