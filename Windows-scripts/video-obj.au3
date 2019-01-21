
#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author: Tasha Adams and Fatma Alali
 Script Function:
	The master script running on the remote desktop
	connect to two other Pcs: (i) Linux VM to collect packet traces
							  (ii) Windows PC (PC1): to record the video output of the zero client

   It does the following: 	configure the network
						    connect to linux VM to start packet capture via Putty
						    connect to PC1 to start video recording script via RDP
							start the video
							sleep fro the video lenght
							stop the recording script at PC1 and export results
							Repeat the above steps for n times for 5 packet loss rate values
   For this script to run: You should have putty installed in the remote desktop
						   RDP in the remote desktop
						   Clumsy in the remote desktop
						   Allow RDP connctions on PC1
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
Local $videoDir = "C:\Users\Harlem5\Desktop\SEEC_Trials\" ;TODO
Local $vdieoName= "zootopia-cut-1080p-36-sec.mkv" ;TODO
Local $vidLength = 10000 ;video length in ms


GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected
GLobal $routerUsr = "harlem1" ;TODO
Global $routerPsw = "harlem" ;TODO
Local $timeInterval = 20000
Local $clinetIPAddress = "172.28.30.9" ;"172.28.30.9" .9:Wyse5030, .22:chromebook
Global $udpPort = 60000

Global $no_tasks = 6
Global $runNo = "10sec-model4"
Local $no_of_runs = 1



;================= Start test =============================
;setup clumsy basic param to prepare for network configuration
Local $hClumsy = Clumsy("", "open", $clinetIPAddress)


;connect to the recording PC via RDP
$hRec = RDP()
;maximizing the window is not working, so I'm doing it manually
WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)
Sleep(2000)

;loop based on teh loss and RTT values
For $j = 0 To UBound($aLoss) - 1
   For $i = 0 To UBound($aRTT) - 1
	  ;configure clumsy
	  Clumsy($hClumsy, "configure","",$aRTT[$i], $aloss[$j])
	  Clumsy($hClumsy, "start")

	  ;repeat of n number of times
	  For $n = 1 To $no_of_runs:
		 ;#comments-start
		 ; start packet capture
		 router_command("start_capture")

		 ;==========run recording script at recording PC=========
		 ;open command prompt in Caller PC
		 OpenTerminal()
		 Sleep(1000)
		 ;run recording script
		 $cmd = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype\record-play.au3 " & $loss ;TASHA: TODO: change it to the recording script you created at PC1
		 Send($cmd)
		 Send("{ENTER}")
		 Sleep(22000)
		 ;#comments-end

		 ;==============play the video====================
		 $hVideo = play_video()
		 Sleep($vidLength)

		 ;#comments-start
		 ;==============stop recording at the recording PC and export result file=============
		 ;Tasha: or change the script to make it sleep for xx sec (based on the video length), then byitself it will stop recording and export results
		 ;open command prompt in Caller PC
		 OpenTerminal()
		 Sleep(1000)
		 ;run recording script
		 $cmd = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype\record-play.au3 " & $loss ;TASHA: TODO: change it to the recording script you created at PC1
		 Send($cmd)
		 Send("{ENTER}")
		 Sleep(22000)

		 ;stop capture
		 router_command("stop_capture")

		 ;analyze results
		 router_command("analyze_results","",$aRTT[$i], $aLoss[$j],$n) ;$n is the count within one run
		 ;#comments-end
	  Next

	  Clumsy($hClumsy, "stop")
	  ;close the video
	  WinClose($hVideo)

   Next
Next

 WinClose($hClumsy)
 WinClose($hRec)


Func play_video()
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