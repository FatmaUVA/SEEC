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
#include <Date.au3>

#RequireAdmin ; this required for clumsy to work properlys


Opt("WinTitleMatchMode",-2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase ;used for WInWaitActive title matching


; ============================ Parameters initialization ====================

; QoS

Local $aRTT[1] = [0]
Local $aLoss[1] = [10] ;,0.5,5,3,10] ;packet loss rate, unit is %

Global $app = "Video"
Local $videoDir = "C:\Users\Harlem5\SEEC\Windows-scripts\Video-test\"
Local $vdieoName= "zootopia-cut-1080p-36-sec.mkv" ;TODO
Local $vidLength = 37000 ;video length in ms

GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected

GLobal $routerUsr = "harlem1" ;TODO
Global $routerPsw = "harlem" ;TODO
Local $timeInterval = 20000
Local $clinetIPAddress = "172.28.30.13" ;"172.28.30.13" .9:Wyse5030, .22:chromebook TODO
Global $udpPort = 60000

Global $runNo = "36sec-model4"
Local $no_of_runs = 5
GLobal $no_tasks = 1


;================= Start test =============================

;setup clumsy basic param to prepare for network configuration

Local $hClumsy = Clumsy("", "open", $clinetIPAddress)

;Run("notepad.exe")
;Local $hNot = WinWaitActive("Untitled - Notepad")


;connect to the recording PC via RDP
$hRec = RDP()
;WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50) ;resize
WinSetState($hRec, "", @SW_MINIMIZE) ;minimiza
Sleep(2000)


Local $hRout= router_command("","start_putty")
;Sleep(2000)


;loop based on teh loss and RTT values

For $j = 0 To UBound($aLoss) - 1

	  ;WinActivate($hNot)
	 ;ControlSend($hNot,"","","packet loss rate = " & $aLoss[$j] & @LF )
	 ;WinSetState($hNot, "", @SW_MINIMIZE)


	  ;configure clumsy
	  If $aLoss[$j] <> 0 Then
		 Clumsy($hClumsy, "configure","",$aRTT[0], $aLoss[$j])
		 Clumsy($hClumsy, "start")
	  EndIf


	  ;repeat of n number of times

	  For $n = 1 To $no_of_runs:
		 ;WinActivate($hNot)
		 ;ControlSend($hNot,"","","Run number = " & $n & @LF )
		 ;WinSetState($hNot, "", @SW_MINIMIZE)

		 ; start packet capture
		 router_command($hRout,"start_capture")
		 ;WinActivate($hNot)
		 ;ControlSend($hNot,"","","Start Time = " & _NowTime()  & @LF )
		 ;WinSetState($hNot, "", @SW_MINIMIZE)


		 ;==========run recording script at recording PC=========

		 ;open command prompt in Caller PC
		 WinActivate($hRec)
		 WinSetState($hRec, "", @SW_MAXIMIZE)

		 OpenTerminal()
		 Sleep(1000)

		 ;run recording script
		 $cmd = "C:\Users\fha6np\Desktop\Video-NR-test\record-play.au3 " & $aLoss[$j] ;TODO: change it to the recording script you created at PC1

		 Send($cmd)
		 Sleep(3000)
		 Send("{ENTER}")
		 Sleep(1000)

		 WinSetState($hRec, "", @SW_MINIMIZE)


		 ;==============play the video====================

		 $hVideo = play_video()
		 Sleep($vidLength)

		 ;==============stop recording at the recording PC and export result file=============

		 ;Tasha: or change the script to make it sleep for xx sec (based on the video length), then byitself it will stop recording and export results

		 ;open command prompt in Caller PC
		 ;WinActivate($hRec)
		 ;WinSetState($hRec, "", @SW_MAXIMIZE)
		 ;Sleep(1000)
		 ;OpenTerminal()

		 ;Sleep(2000)

		 ;run recording script

		 ;$cmd = "C:\Users\Tasha\Desktop\SEEC\record-play.au3 " & $aLoss[$j] ;TASHA: TODO: change it to the recording script you created at PC1

		 ;Send($cmd)
		 ;Sleep(1000)
		 ;Send("{ENTER}")
		 ;Sleep(1000)
		 ;Send("exit")
		 ;Send("{ENTER}")
		 ;WinSetState($hRec, "", @SW_MINIMIZE)

		 WinActivate($hVideo)
		 WinClose($hVideo)


		 ;stop capture
		 ;WinActivate($hNot)
		 ;ControlSend($hNot,"","","Stop Time = " & _NowTime() & @LF  )
		 ;WinSetState($hNot, "", @SW_MINIMIZE)
		 router_command($hRout,"stop_capture")

		 ;analyze results
		 router_command($hRout,"analyze_results","",$aRTT[0], $aLoss[$j],$n) ;$n is the count within one run

	  Next

	  If $aLoss[$j] <> 0 Then
		 Clumsy($hClumsy, "stop")
	  EndIf

	  ;close the video
	  WinClose($hVideo)

Next

 WinClose($hClumsy)
 WinClose($hRec)
 WinKill($hRout)


Func play_video()

   Local $winTitle = "Movies & TV"
   ShellExecute($videoDir & $vdieoName)
   Local $hApp = WinWaitActive($winTitle)
   return $hApp

EndFunc

Func router_command($hShell,$cmd, $videoSpeed="slow", $rtt=0, $loss=0,$n=0); cmd: "start_capture", "stop_capture", "analyze"

   If $cmd = "start_putty" Then

	  ; open putty
	  ShellExecute("C:\Program Files\PuTTY\putty") ; TODO: cahnge the directory to where you have putty

	  ;ShellExecute($videoDir & $vdieoName)
	  Local $hPutty = WinWaitActive("PuTTY Configuration")



	  ;connect to the router linux server

	  ;Send($routerIP)
	  ControlSend("","","",$routerIP)
	  ControlClick($hPutty, "","Button1", "left", 1,8,8)
	  $hShell = WinWaitActive($routerIP & " - PuTTY")

	  Sleep(1000)
	  Send($routerUsr)
	  Send("{ENTER}")
	  Sleep(1000)
	  Send($routerPsw)
	  Send("{ENTER}")
	  Sleep(500)

	  $hShell = WinWaitActive("harlem1@router") ;TODO, change to match machine putty name
	  WinSetState($hShell, "", @SW_MINIMIZE)
	  Return $hShell
   EndIf



   If $cmd = "start_capture" Then
	  ;WinWaitActive($hShell)
	 ; WinSetState($hShell, "", @SW_MAXIMIZE)

	  ;run the capture /home/fatma/SEEC/Windows-scripts
	  Local $command = "sudo sh SEEC/Windows-scripts//start-tcpdump.sh " & $routerIF & " " & $videoSpeed ; TODO: cahnge the directory
	  Sleep(600)
	  ;Send($command)
	  ControlSend($hShell, "", "", $command)
	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "", "{ENTER}")
	  Sleep(500)

	  ;Send($routerPsw)
	  ControlSend($hShell, "", "",$routerPsw)
	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "","{ENTER}")
	  ;WinSetState($hShell, "", @SW_MINIMIZE)


   ElseIf $cmd = "stop_capture" Then
	  ;WinWaitActive($hShell)
	  ;WinSetState($hShell, "", @SW_MAXIMIZE)
	  $command = "sudo killall tcpdump"

	  Sleep(600)
	  ;Send($command)
	  ControlSend($hShell, "", "", $command)

	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "", "{ENTER}")

	  Sleep(500)

	  ;Send($routerPsw)
	  ControlSend($hShell, "", "",$routerPsw)
	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "","{ENTER}")

	  ;WinSetState($hShell, "", @SW_MINIMIZE)


   ElseIf $cmd = "analyze" Then
	  ;WinWaitActive($hShell)
	  ;WinSetState($hShell, "", @SW_MAXIMIZE)
	  $command = "sudo sh SEEC/Windows-scripts/analyze.sh " & $slow_time & " " & $reg_time & " " & $rtt & " " & $loss

	  Sleep(600)
	  ;Send($command)
	  ControlSend($hShell, "", "", $command)

	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "", "{ENTER}")

	  Sleep(500)


	  ;Send($routerPsw)
	  ControlSend($hShell, "", "",$routerPsw)
	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "","{ENTER}")

	  ;WinSetState($hShell, "", @SW_MINIMIZE)


   ElseIf $cmd = "compute_plot" Then
	  ;WinWaitActive($hShell)
	  ;WinSetState($hShell, "", @SW_MAXIMIZE)

	  $command = "sh SEEC/Windows-scripts/compute-thru.sh  capture-1-slow.pcap "  & $clinetIPAddress & " " & $rtt & " " & $loss

	  ;Send($command)
	  ControlSend($hShell, "", "", $command)

	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "", "{ENTER}")

	  ;WinSetState($hShell, "", @SW_MINIMIZE)


   ElseIf $cmd = "analyze_results" Then
	  ;WinWaitActive($hShell)
	  ;WinSetState($hShell, "", @SW_MAXIMIZE)

	  $command = "sudo sh SEEC/Windows-scripts/find_total_bytes.sh " & $clinetIPAddress & " " & $rtt & " " & $loss & " " & $no_tasks & " " & $app & " " & $runNo  & " " & $n ; TODO: cahnge the directory and the script, this script will not work for you

	  Sleep(1000)

	  ;Send($command)
	  ControlSend($hShell, "", "", $command)

	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "", "{ENTER}")

	 ; WinSetState($hShell, "", @SW_MINIMIZE)




   EndIf



	;close putty

	;Sleep(500)

	;Send("exit")

	;Send("{ENTER}")



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

	 $hWnd = WinWaitActive("clumsy 0.2")



	  ;set delay

	  ControlSetText($hWnd,"", "Edit2", $RTT)



	  ;add packet drop

	  ControlSetText($hWnd,"", "Edit3", $loss)



   ElseIf $cmd = "start" Then

	  ;click the start button

	  $hWnd = WinWaitActive("clumsy 0.2")

	  ControlClick($hWnd, "","Button2", "left", 1,8,8)



   ElseIf $cmd = "stop" Then

	  ;click the start button

	  $hWnd = WinWaitActive("clumsy 0.2")

	  ControlClick($hWnd, "","Button2", "left", 1,8,8)



   EndIf

EndFunc

Func RDP()

Local $winTitle = "Remote Desktop Connection"

   Local $appName  = "C:\Users\Harlem5\Desktop\Remote Desktop Connection - Shortcut.lnk" ;Tasha TODO: change directory


   ;open the app
   ShellExecute($appName)

   ;Sleep(600)
   $hApp = WinWaitActive($winTitle)

   Sleep(500)


   ;connect to the remote desktop

  ; MouseClick("left",151,207)

   ;MouseClick("left",1039,433)
   ;ControlClick($hApp, "","Edit1", "D")
   ;ControlClick($hApp, "","Button5", "left", 1,8,8)
   Send("{ENTER}")

   $hRDP = WinWaitActive(" - Remote Desktop Connection") ;TODO: I nemed my connection caller, based on what you name your connection in RDP, use that name

   ;WinMove($hRDP,"",0,0,@DesktopWidth, @DesktopHeight)


   Return  $hRDP

EndFunc

Func OpenTerminal()

    ;click on the search bar in the lower left corner on windows

   ;MouseClick("left",180,1062,1) ;TODO: change the x y coord
   MouseClick("left",185,1061,1)
   Sleep(2000)

   Send("cmd")
   Sleep(1000)
   Send("{ENTER}")

   Sleep(1000)

EndFunc