
#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Fatma Alali
 Script Function:
In this script the caller and recording scripts are executed in one PC, so one RDP seesion is created tos tart recording, play the audio, stop recording, and parse results
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

#RequireAdmin ; this required for clumsy to work properlys

Opt("WinTitleMatchMode",-2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase ;used for WInWaitActive title matching

; ============================ Parameters initialization ====================
; QoS
Local $aRTT[1] = [0];,50,100];1,2,5,10,50,100] ;,50, 150]
Local $aLoss[5] = [0,0.5,3,5,10] ;,3,5];,3,5];,3] ;,0.05,1] ;packet loss rate, unit is %
Global $app = "Skype"
Local $logDir = "C:\Users\Harlem5\SEEC\Windows-scripts"

Local $clinetIPAddress = "172.28.30.13" ;.9 for Wyse 5030 and 22 for Chromebook, .13 LG ZC
Global $udpPort = 60000
Global $runNo = "1-model4"
Local $no_of_runs = 20

Global $appName  = "C:\Users\Harlem5\Desktop\RemoteDesktop.lnk"
Global $winTitle = "Remote Desktop"

Global $no_tasks =  1



;================= Start actual test =============================
;setup clumsy basic param to prepare for network configuration
Local $hClumsy = Clumsy("", "open", $clinetIPAddress)


;maximizing the window is not working, so I'm doing it manually
;WinMove($hApp,"",0,0,@DesktopWidth, @DesktopHeight)

$hRec = RDP()
WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)
Sleep(2000)


For $n = 1 To $no_of_runs
   For $i = 0 To UBound($aRTT) - 1
	  For $j = 0 To UBound($aLoss) - 1
		 ;configure clumsy
		 Clumsy($hClumsy, "configure","",$aRTT[$i], $aloss[$j])
		 Clumsy($hClumsy, "start")

		 $loss = $aloss[$j]
		 If $loss == 0.5 Then
			$loss = "0-5" ;because when parsing the file name should not have . in it, the code would be confused thinking this is the file extension
		 EndIf

		 ;==========run recording script at recording PC
		 ;open command prompt in Caller PC
		 OpenTerminal()
		 Sleep(1000)
		 ;run recording script
		 $cmd = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype\record-play.au3 " & $loss
		 Send($cmd)
		 Send("{ENTER}")
		 Sleep(22000)

		 Clumsy($hClumsy, "stop")

	  Next
   Next
Next

WinClose($hRec)
WinClose($hClumsy)


Func RDP()
   ;open the app
   ShellExecute($appName,"", @SW_MAXIMIZE)
   ;Sleep(600)
   $hApp = WinWaitActive($winTitle)
   WinMove($App,"",0,0,@DesktopWidth, @DesktopHeight)
   Sleep(500)

   ;connect to the remote desktop
  ; MouseClick("left",151,207)
   MouseClick("left",121,188)
   $hRDP = WinWaitActive("caller")

   ;exit full screen
   ;MouseMove(1602,0)
   ;Sleep(500)
  ; MouseClick("left",1602,0,1) ;only 1 click

   WinClose($hApp)

   Return  $hRDP
EndFunc

Func OpenTerminal()
   MouseClick("left",36,970,1)
   Sleep(500)
   Send("cmd")
   Send("{ENTER}")
   Sleep(500)
EndFunc

Func Clumsy($hWnd, $cmd, $clinetIPAddress="0.0.0.0", $RTT=0, $loss=0)

   If $cmd = "open" Then
	  ShellExecute("C:\Users\Harlem5\Downloads\clumsy-0.2-win64\clumsy.exe")
	  $hWnd = WinWaitActive("clumsy 0.2")
	  ;basic setup
	  ; clear the filter text filed
	  Local $filter = "outbound and ip.DstAddr==" & $clinetIPAddress & " and udp.DstPort != "& $udpPort
	  ControlSetText($hWnd,"", "Edit1", $filter)

	  ; set check box for lag (delay)
	  ControlClick($hWnd, "","Button4", "left", 1,8,8) ;1 click 8,8 coordinate

	  ;set check box for drop
	  ControlClick($hWnd, "","Button7", "left", 1,8,8)
	  Return $hWnd

   ElseIf $cmd = "configure" Then
	  ;make sure it is active
	  WinActivate($hWnd)

	  ;set delay
	  ControlSetText($hWnd,"", "Edit2", $RTT)

	  ;add packet drop
	  ControlSetText($hWnd,"", "Edit3", $loss)

   ElseIf $cmd = "start" Then
	  ;click the start button
	  ControlClick($hWnd, "","Button2", "left", 1,8,8)

   ElseIf $cmd = "stop" Then
	  ;click the start button
	  ControlClick($hWnd, "","Button2", "left", 1,8,8)

   EndIf
EndFunc


