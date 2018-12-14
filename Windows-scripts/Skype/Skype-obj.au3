
#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Fatma Alali
 Script Function:
	RT objective test for 360 image view, includes 3 tasks,  move (drag and drop), zoom-n, and zoom-out, repeats the same 3 tasks for xx images
	This test use web-based application to explore the 360 images
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
Local $aLoss[1] = [33] ;,3,5];,3,5];,3] ;,0.05,1] ;packet loss rate, unit is %
Global $app = "Skype"
Local $logDir = "C:\Users\Harlem5\SEEC\Windows-scripts"

GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected
GLobal $routerUsr = "harlem1"
Global $routerPsw = "harlem"
Local $timeInterval = 20000 ;30000

Local $clinetIPAddress = "172.28.30.9" ;.9 for Wyse 5030 and .93 for Chromebook
Global $udpPort = 60000
Global $runNo = "1-model4"
Local $no_of_runs = 1

Global $appName  = "C:\Users\Harlem5\Desktop\RemoteDesktop.lnk"
Global $winTitle = "Remote Desktop"

Global $no_tasks =  1



;================= Start actual test =============================
;setup clumsy basic param to prepare for network configuration
Local $hClumsy = Clumsy("", "open", $clinetIPAddress)


;maximizing the window is not working, so I'm doing it manually
;WinMove($hApp,"",0,0,@DesktopWidth, @DesktopHeight)

For $n = 1 To $no_of_runs:
   For $j = 0 To UBound($aLoss) - 1
	  For $i = 0 To UBound($aRTT) - 1
		 ;configure clumsy
		 Clumsy($hClumsy, "configure","",$aRTT[$i], $aloss[$j])
		 Clumsy($hClumsy, "start")

		 ;==========run recording script at recording PC
		 $hRec = RDP()
		 WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)
		 ;open command prompt in Caller PC
		 Sleep(1500)
		 OpenTerminal()
		 Sleep(1000)
		 ;run recording script
		 $cmd = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype\record-audio.au3 start " & $aLoss[$j]
		 Send($cmd)
		 Send("{ENTER}")
		 Sleep(3000)
		 WinClose($hRec)

		 ;========run playing audio script at caller PC
		 $hCall = RDP()
		 WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)
		 ;open command prompt in Recorder PC
		 Sleep(1500)
		 OpenTerminal()
		 ;run recording script
		 Sleep(1000)
		 ;run audio playing script
		 $cmd = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype\play-audio.au3"
		 Send($cmd)
		 Send("{ENTER}")
		 WinClose($hCall)

		 ;==========run stop recording script at recording PC
		 $hRec = RDP()
		 WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)
		 ;open command prompt in Caller PC
		 Sleep(1500)
		 OpenTerminal()
		 Sleep(1000)
		 ;run recording script
		 $cmd = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype\record-audio.au3 stop " & $aLoss[$j]
		 Send($cmd)
		 Send("{ENTER}")
		 Sleep(10000)
		 WinClose($hRec)

		 Clumsy($hClumsy, "stop")

	  Next
   Next
Next

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


