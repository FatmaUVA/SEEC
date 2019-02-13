
#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author: Fatma Alali
 Script Function:
	This script runs on the remote desktop
	connect to : (i) Linux VM to collect packet traces

   It does the following: 	configure the network
						    connect to linux VM to start packet capture via Putty
							start the video with 1fps
							sleep for the video lenght
							stop packet capture

   						    connect to linux VM to start packet capture via Putty
							start PCoIP SSV tool to capture fps info
							start the video with original fps
							sleep for the video lenght
							stop packet capture
							Anlalyze data to get slow-mot VQ and total bytes at regular speed

							Repeat the above steps for n times for 5 packet loss rate values

   For this script to run: You should have putty installed in the remote desktop
						   Clumsy in the remote desktop

#ce ----------------------------------------------------------------------------


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
Local $aRTT[1] = [0]
Local $aLoss[5] = [0,0.5,5,3,10] ;packet loss rate, unit is %
Global $app = "Video"
Local $videoDir = "C:\Users\Harlem5\SEEC\Windows-scripts\Video-test\"
Local $vide1fps = "1fps-zootopia-cut-1080p-36-sec"
Local $video24fps = "zootopia-cut-1080p-36-sec"

Local $vidLength1fps = 864000 ;video length in ms (14:24 min)
Local $vidLength24fps = 36000 ;video length in ms (36 sec)


GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected
GLobal $routerUsr = "harlem1" ;TODO
Global $routerPsw = "harlem" ;TODO
Local $timeInterval = 20000
Local $clinetIPAddress = "172.28.30.13" ;"172.28.30.9" .9:Wyse5030, .22:chromebook
Global $udpPort = 60000

Global $no_tasks = 6
Global $runNo = "1-model4"
Local $no_of_runs = 1


 $hPCoIP = PCoIP_stats("", "open")
 Sleep(10000)
 PCoIP_stats("$hPCoIP", "stop")

 #comments-start

;================= Start test =============================
;setup clumsy basic param to prepare for network configuration
Local $hClumsy = Clumsy("", "open", $clinetIPAddress)

;maximizing the window is not working, so I'm doing it manually
;WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)


;loop based on teh loss and RTT values
For $j = 0 To UBound($aLoss) - 1
   For $i = 0 To UBound($aRTT) - 1
	  ;configure clumsy
	  Clumsy($hClumsy, "configure","",$aRTT[$i], $aloss[$j])
	  Clumsy($hClumsy, "start")

	  ;repeat of n number of times
	  For $n = 1 To $no_of_runs:

		 ;======play video at 1 fps========
		 ; start packet capture
		 router_command("start_capture")
		 $hVideo = play_video($vide1fps)
		 Sleep($vidLength1fps)
		 WinClose($hVideo)

		 ;stop capture
		 router_command("stop_capture")

	     ;======play video at 24 fps========
   		 ; start packet capture
		 router_command("start_capture")

		 ;Collect PCoIP logs
	     $hPCoIP = PCoIP_stats("", "open")

		 $hVideo = play_video($vide24fps)
		 Sleep($vidLength24fps)
		 WinClose($hVideo)

		 ;stop capture
		 router_command("stop_capture")

		 ;stop and export fps data
		 PCoIP_stats("$hPCoIP", "stop")


		 ;==========nalyze results=============
		 router_command("analyze_results","",$aRTT[$i], $aLoss[$j],$n) ;$n is the count within one run

	  Next

	  Clumsy($hClumsy, "stop")

   Next
Next

 WinClose($hClumsy)
 #comments-end



Func PCoIP_stats($hWnd, $cmd)
   If $cmd = "open" Then
	  ShellExecute("C:\Users\Harlem5\Downloads\SSV_2.0.exe")
	  $hWnd = WinWaitActive("PCoIP Session Statistics Viewe")
	  ;basic setup
	  ; clear the filter text filed
	  ;Local $filter = "outbound and ip.DstAddr==" & $clinetIPAddress & " and udp.DstPort != "& $udpPort
	  ;ControlSetText($hWnd,"", "Edit1", $filter)

	  ;click on configure
	  ControlClick($hWnd, "","WindowsForms10.Window.8.app.0.141b42a_r6_ad12", "left", 1,159,13) ;1 click 8,8 coordinate

	  ;click on Add VM
	  MouseClick("left",468,239,1)
	  Send('{ENTER}')
	  Return $hWnd


   ElseIf $cmd = "stop" Then

	   WinActivate($hWnd)
	   Sleep(600)
	  ;click the pause button
	  Send('{ENTER}')
	  ;ControlClick($hWnd, "","WindowsForms10.BUTTON.app.0.141b42a_r6_ad11", "left", 1,32,10)
	  Sleep(500)
	  ;click on file
	  ;ControlClick($hWnd, "","WindowsForms10.Window.8.app.0.141b42a_r6_ad12", "left", 1,22,12) ; the instance ID keeps on changing!
	  MouseClick("left",329,222,1)
	  ;click on export
	  MouseClick("left",323,243,1)
	  Sleep(500)
	  Send('{ENTER}')
	  Sleep(500)
	  Send('{ENTER}')
	  WinClose("PCoIP Session Statistics Viewe")

   EndIf

EndFunc

Func play_video($vdieoName)
   Local $winTitle = "Movies & TV"
   ShellExecute($videoDir & $vdieoName)
   Local $hApp = WinWaitActive($winTitle)
   return $hApp
EndFunc


Func router_command($cmd, $videoSpeed="slow", $rtt=0, $loss=0,$n=0); cmd: "start_capture", "stop_capture", "analyze"

	; open putty
	ShellExecute("C:\Program Files\PuTTY\putty") ;Tasha TODO: cahnge the directory to where you have putty
	;ShellExecute($videoDir & $vdieoName)
	Local $hPutty = WinWaitActive("PuTTY Configuration")

	;connect to the router linux server
	;Send($routerIP)
	ControlSend("","","",$routerIP)
	ControlClick($hPutty, "","Button1", "left", 1,8,8)

	Local $hShell = WinWaitActive($routerIP & " - PuTTY")
	Sleep(600)
	Send($routerUsr)
	Send("{ENTER}")
	Sleep(600)
	Send($routerPsw)
	Send("{ENTER}")
	Sleep(500)

	If $cmd = "start_capture" Then

	  ;run the capture /home/fatma/SEEC/Windows-scripts
	  Local $command = "sudo sh /home/harlem1/SEEC/Windows-scripts/start-tcpdump.sh " & $routerIF & " " & $videoSpeed ;Tasha TODO: cahnge the directory
	  Sleep(600)
	  Send($command)
	  Send("{ENTER}")
	  Sleep(500)
	  Send($routerPsw)
	  Send("{ENTER}")

	ElseIf $cmd = "stop_capture" Then
	  $command = "sudo killall tcpdump"
	  Sleep(600)
	  Send($command)
	  Send("{ENTER}")
	  Sleep(500)
	  Send($routerPsw)
	  Send("{ENTER}")

	ElseIf $cmd = "analyze" Then
	  $command = "sudo bash SEEC/Windows-scripts/analyze.sh " & $slow_time & " " & $reg_time & " " & $rtt & " " & $loss
	  Sleep(600)
	  Send($command)
	  Send("{ENTER}")
	  Sleep(300)
	  Send($routerPsw)
	  Send("{ENTER}")

	  ElseIf $cmd = "compute_plot" Then
	  $command = "sh SEEC/Windows-scripts/compute-thru.sh  capture-1-slow.pcap "  & $clinetIPAddress & " " & $rtt & " " & $loss
	  Send($command)
	  Send("{ENTER}")

	  ElseIf $cmd = "analyze_results" Then
	  $command = "sh SEEC/Windows-scripts/analyze_RT.sh  " & $clinetIPAddress & " " & $rtt & " " & $loss & " " & $no_tasks & " " & $app & " " & $runNo  & " " & $n ;Tasha TODO: cahnge the directory and the script, this script will not work for you
	  Sleep(1000)
	  Send($command)
	  Send("{ENTER}")


	EndIf

	;close putty
	Sleep(500)
	Send("exit")
	Send("{ENTER}")

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
	  WinActivate($hWnd)
	  ControlClick($hWnd, "","Button2", "left", 1,8,8)

   ElseIf $cmd = "stop" Then
	  ;click the start button
	  WinActivate($hWnd)
	  ControlClick($hWnd, "","Button2", "left", 1,8,8)

   EndIf
EndFunc

;Tasha TODO: you need to change the mouse clicks here to make sure it's working with your display
Func RDP()
   Local $winTitle = "Remote Desktop"
   Local $appName  = "C:\Users\Harlem5\Desktop\RemoteDesktop.lnk" ;Tasha TODO: change directory

   ;open the app
   ShellExecute($appName,"", @SW_MAXIMIZE)
   ;Sleep(600)
   $hApp = WinWaitActive($winTitle)
   WinMove($App,"",0,0,@DesktopWidth, @DesktopHeight)
   Sleep(500)

   ;connect to the remote desktop
  ; MouseClick("left",151,207)
   MouseClick("left",121,188)
   $hRDP = WinWaitActive("caller") ;TODO: I nemed my connection caller, based on what you name your connection in RDP, use that name

   WinClose($hApp)

   Return  $hRDP
EndFunc

Func OpenTerminal()
    ;click on the search bar in the lower left corner on windows
   MouseClick("left",36,970,1) ;TODO: change the x y coord
   Sleep(500)
   Send("cmd")
   Send("{ENTER}")
   Sleep(500)
EndFunc