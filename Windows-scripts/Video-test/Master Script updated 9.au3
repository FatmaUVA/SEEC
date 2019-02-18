

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

Local $aLoss[5] = [0,0.5,5,3,10] ;packet loss rate, unit is %

Global $app = "Video"

Local $videoDir = "C:\Users\SEECH\Desktop\SEEC_Trials\" ;TODO

Local $vdieoName= "zootopia-cut-1080p-36-sec.mkv" ;TODO

Local $vidLength = 37000 ;video length in ms





GLobal $routerIP = "10.129.36.183" ; the ip address of the server acting as router and running packet capture

Global $routerIF = "ens160" ; the router interface where the clinet is connected


GLobal $routerUsr = "seec" ;TODO

Global $routerPsw = "HarlemNY" ;TODO

Local $timeInterval = 20000

Local $clinetIPAddress = "10.129.36.203" ;"172.28.30.9" .9:Wyse5030, .22:chromebook TODO

Global $udpPort = 60000



Global $no_tasks = 6

Global $runNo = "36sec-model4"

Local $no_of_runs = 5







;================= Start test =============================

;setup clumsy basic param to prepare for network configuration

Local $hClumsy = Clumsy("", "open", $clinetIPAddress)

Run("notepad.exe")
Local $hNot = WinWaitActive("Untitled - Notepad")



;connect to the recording PC via RDP

$hRec = RDP()

;maximizing the window is not working, so I'm doing it manually

;WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)
WinSetState($hRec, "", @SW_MINIMIZE)
Sleep(2000)


Local $hRout= router_command("","start_putty")
;Sleep(2000)

;loop based on teh loss and RTT values

For $j = 0 To 4

	  WinActivate($hNot)

	 ControlSend($hNot,"","","packet loss rate = " & $aLoss[$j] & @LF )

	  WinSetState($hNot, "", @SW_MINIMIZE)


	  ;configure clumsy

	  Clumsy($hClumsy, "configure","",$aRTT[0], $aLoss[$j])

	  Clumsy($hClumsy, "start")



	  ;repeat of n number of times

	  For $n = 1 To $no_of_runs:
		 WinActivate($hNot)

		 ControlSend($hNot,"","","Run number = " & $n & @LF )
		 WinSetState($hNot, "", @SW_MINIMIZE)
		 ;#comments-start

		 ; start packet capture


		 router_command($hRout,"start_capture")
		 WinActivate($hNot)
		 ControlSend($hNot,"","","Start Time = " & _NowTime()  & @LF )
		 WinSetState($hNot, "", @SW_MINIMIZE)


		 ;==========run recording script at recording PC=========

		 ;open command prompt in Caller PC
		 WinActivate($hRec)
		 WinSetState($hRec, "", @SW_MAXIMIZE)

		 OpenTerminal()

		 Sleep(1000)

		 ;run recording script

		 $cmd = "C:\Users\Tasha\Desktop\SEEC\record-play.au3 " & $aLoss[$j] ;TODO: change it to the recording script you created at PC1

		 Send($cmd)
		 Sleep(3000)
		 Send("{ENTER}")
		 Sleep(1000)
		 ;Send("exit")
		 ;Sleep(1000)
		 ;Send("{ENTER}")
		 ;Sleep(1000)
		 WinSetState($hRec, "", @SW_MINIMIZE)
		 ;Sleep(22000)

		 ;#comments-end






		 ;==============play the video====================

		 $hVideo = play_video()

		 Sleep($vidLength)



		 ;#comments-start

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

		 ;Send("{ENTER}")

		 ;Sleep(36000)

		 ;stop video
		 ;MouseClick("left",1894,15)

		 ;stop capture
		 WinActivate($hNot)
		 ControlSend($hNot,"","","Stop Time = " & _NowTime() & @LF  )
		 WinSetState($hNot, "", @SW_MINIMIZE)
		 router_command($hRout,"stop_capture")



		 ;analyze results

		 router_command($hRout,"analyze_results","",$aRTT[0], $aLoss[$j],$n) ;$n is the count within one run

		 ;#comments-end

	  Next



	  Clumsy($hClumsy, "stop")

	  ;close the video

	  WinClose($hVideo)




Next



 WinClose($hClumsy)

 WinClose($hRec)





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

	  $hShell = WinWaitActive("seec@seec-virtual-machine: ~") ;TODO, change to match machine putty name
	  WinSetState($hShell, "", @SW_MINIMIZE)
	  Return $hShell
   EndIf



   If $cmd = "start_capture" Then
	  ;WinWaitActive($hShell)
	 ; WinSetState($hShell, "", @SW_MAXIMIZE)

	  ;run the capture /home/fatma/SEEC/Windows-scripts

	  Local $command = "sudo sh /home/seec/Desktop/SEEC9/Windows-scripts/start-tcpdump.sh " & $routerIF & " " & $videoSpeed ; TODO: cahnge the directory

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
	  $command = "sudo sh /home/seec/Desktop/SEEC9/Windows-scripts/analyze.sh " & $slow_time & " " & $reg_time & " " & $rtt & " " & $loss

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

	  $command = "sh SEEC9/Windows-scripts/compute-thru.sh  capture-1-slow.pcap "  & $clinetIPAddress & " " & $rtt & " " & $loss

	  ;Send($command)
	  ControlSend($hShell, "", "", $command)

	  ;Send("{ENTER}")
	  ControlSend($hShell, "", "", "{ENTER}")

	  ;WinSetState($hShell, "", @SW_MINIMIZE)


   ElseIf $cmd = "analyze_results" Then
	  ;WinWaitActive($hShell)
	  ;WinSetState($hShell, "", @SW_MAXIMIZE)

	  $command = "sudo sh /home/seec/Desktop/SEEC9/Windows-scripts/find_total_bytes.sh " & $clinetIPAddress & " " & $rtt & " " & $loss & " " & $no_tasks & " " & $app & " " & $runNo  & " " & $n ; TODO: cahnge the directory and the script, this script will not work for you

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

	  ShellExecute("C:\Users\SEECH\Desktop\clumsy\clumsy.exe")

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



;Tasha TODO: you need to change the mouse clicks here to make sure it's working with your display

Func RDP()

Local $winTitle = "Remote Desktop Connection"

   Local $appName  = "C:\Users\SEECH\Desktop\RemoteDesktop.lnk" ;Tasha TODO: change directory



   ;open the app

   ShellExecute($appName)

   ;Sleep(600)
   $hApp = WinWaitActive($winTitle)

   Sleep(500)


   ;connect to the remote desktop

  ; MouseClick("left",151,207)

   MouseClick("left",1039,433)
   ;ControlClick($hApp, "","Edit1", "D")
   ;ControlClick($hApp, "","Button5", "left", 1,8,8)

   $hRDP = WinWaitActive("10.129.37.23 - Remote Desktop Connection") ;TODO: I nemed my connection caller, based on what you name your connection in RDP, use that name

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