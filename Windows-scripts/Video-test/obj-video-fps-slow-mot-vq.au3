
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
						   pyhton installed in the remote desktop
						   numpy installed (you can install it with pip and you may need to add it to the PATH)
						   Mplayer

#ce ----------------------------------------------------------------------------


#include <EditConstants.au3>



#RequireAdmin ; this required for clumsy to work properlys

Opt("WinTitleMatchMode",-2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase ;used for WInWaitActive title matching

; ============================ Parameters initialization ====================
; QoS
Local $aRTT[1] = [0]
Local $aLoss[5] = [0,0.5,3,5,10] ;packet loss rate, unit is %
Global $app = "Video"
Local $videoDir = "C:\Users\Harlem5\SEEC\Windows-scripts\Video-test\"
Local $vide1fps = "zootopia-cut-1080p-36-sec-1fps.mkv"
Local $video24fps = "zootopia-cut-1080p-36-sec.mkv"
Local $player = "MPlayer"

GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected
GLobal $routerUsr = "harlem1" ;TODO
Global $routerPsw = "harlem" ;TODO
Local $timeInterval = 20000
Local $clinetIPAddress = "172.28.30.13" ;"172.28.30.9" .9:Wyse5030, .22:chromebook
Global $udpPort = 60000

Global $runNo = "3-model4"
Local $no_of_runs = 3








;================= Start test =============================


;setup clumsy basic param to prepare for network configuration
;Local $hClumsy = Clumsy("", "open", $clinetIPAddress)

;maximizing the window is not working, so I'm doing it manually
;WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)






;repeat of n number of times
For $n = 1 To $no_of_runs:
   ;loop based on teh loss and RTT values
   For $j = 0 To UBound($aLoss) - 1
	  For $i = 0 To UBound($aRTT) - 1

		 If $aLoss[$j] <> 0 Then
			Local $hClumsy = Clumsy("", "open", $clinetIPAddress)
			;configure clumsy
			Clumsy($hClumsy, "configure","",$aRTT[$i], $aloss[$j])
			Clumsy($hClumsy, "start")
		 EndIf


		 ; only if PLR = 0 play at 1 fps and use it as a reference
		 If $aLoss[$j] == 0 Then
			;======play video at 1 fps========
			; start packet capture
			router_command("start_capture","slow")
			;log time
			Local $hTimer1fps = TimerInit() ;begin the timer and store the handler

			If $player == "MPlayer" Then
			   ;MsgBox($MB_OK,"","I'm inside MPLAYEr if statement!")
			    play_video_MPlayer($video24fps,1)
			 Else
			   $hVideo = play_video($vide1fps)
			   MouseClick("left",737,538,2)
			   ;wait til the video finish playing by monitoring a specific pixel
			   $color = PixelGetColor(1655,916)
			   Sleep(10000)
			   While $color <> 3637692
				  ;MsgBox($MB_OK,"","The pixel color is "& $color,$hVideo)
				  $color = PixelGetColor(1655,916)
			   WEnd
			   WinClose($hVideo)
			EndIf

			Global $timeDiff1fps = TimerDiff($hTimer1fps) ; find the time difference from the first call of TImerInit

			;stop capture
			router_command("stop_capture")
		 EndIf


	     ;======play video at 24 fps========
   		 ; start packet capture
		 router_command("start_capture","regular")


		 ;Collect PCoIP logs
	     $hPCoIP = PCoIP_stats("", "open")
		 Sleep(500)

		 ;log time
		 Local $hTimer24fps = TimerInit() ;begin the timer and store the handler



		 If $player == "MPlayer" Then
			play_video_MPlayer($video24fps,24)
		 Else
			$hVideo = play_video($video24fps)
			MouseClick("left",737,538,2) ; to exist full screen

			;wait til the video finish playing by monitoring a specific pixel
			$color = PixelGetColor(1655,916)
			Sleep(10000)
			While $color <> 3637692
			   ;MsgBox($MB_OK,"","The pixel color is "& $color,$hVideo)
			   $color = PixelGetColor(1655,916)
			WEnd
			WinClose($hVideo)
		 EndIf

		 Global $timeDiff24fps = TimerDiff($hTimer24fps) ; find the time difference from the first call of TImerInit

		 ;stop capture
		 router_command("stop_capture")
		 Sleep(500)

		 ;stop and export fps data
		 PCoIP_stats("$hPCoIP", "stop")


		 ;==========analyze results=============
		 router_command("analyze_vq","",$aRTT[$i], $aLoss[$j]) ;$n is the count within one run

		 ; extract fps info by running process-fps code
		 OpenTerminal()
		 $hTerm = WinWaitActive("Command")
		 Sleep(1000)
		 Send("C:\Users\Harlem5\SEEC\Windows-scripts\Video-test\process-fps.py " & $aLoss[$j] & " " & $runNo )
		 Send('{ENTER}')
		 Sleep(7000)
		 WinClose($hTerm)
	  Next

	  If $aLoss[$j] <> 0 Then
		 Clumsy($hClumsy, "stop")
		 WinClose($hClumsy)
	  EndIf

   Next
Next

 ;WinClose($hClumsy)






Func PCoIP_stats($hWnd, $cmd)
   If $cmd = "open" Then
	  ShellExecute("C:\Users\Harlem5\Downloads\SSV_2.0.exe")
	  $hWnd = WinWaitActive("PCoIP Session Statistics Viewe")

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
	  Sleep(3000)
	  WinClose("PCoIP Session Statistics Viewe")

   EndIf

EndFunc

Func play_video($vdieoName)
   Local $winTitle = "Movies & TV"
   ShellExecute($videoDir & $vdieoName)
   Local $hApp = WinWaitActive($winTitle)
   return $hApp
EndFunc


;play video with mplayer
Func play_video_MPlayer($vdieoName,$fps)

   OpenTerminal()
   $hTerm = WinWaitActive("Command")
   Sleep(1000)
   If $fps == 1 Then
	  $cmd = "C:\Users\Harlem5\Downloads\mplayer-svn-38119-x86_64\mplayer.exe -fps 1 " & $videoDir & $vdieoName
   Else
	  $cmd = "C:\Users\Harlem5\Downloads\mplayer-svn-38119-x86_64\mplayer.exe " & $videoDir & $vdieoName
   EndIf

   Send($cmd)
   Send('{ENTER}')

   $hMPlayer = WinWaitActive("MPlayer")

   ;wait till the video ends
   ;While WinExists($hMPlayer) ;exsits didn't work
   While WinActive("MPlayer")
   WEnd
   ;MsgBox($MB_OK,"","Exit while loop")
   WinClose($hTerm)
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
	Send("{ENTER}")

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

	  ElseIf $cmd = "analyze_vq" Then
	  $command = "bash SEEC/Windows-scripts/analyze_vq.sh  " & $timeDiff1fps & " " & $timeDiff24fps & " " & $loss & " " & $runNo ;Tasha TODO: cahnge the directory and the script, this script will not work for you
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
	  ;ControlClick($hWnd, "","Button4", "left", 1,8,8) ;1 click 8,8 coordinate

	  ;set check box for drop
	  ControlClick($hWnd, "","Button7", "left", 1,8,8)
	  Return $hWnd

   ElseIf $cmd = "configure" Then
	  ;make sure it is active
	  WinActivate($hWnd)

	  ;set delay
	  ;ControlSetText($hWnd,"", "Edit2", $RTT)

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


Func OpenTerminal()
    ;click on the search bar in the lower left corner on windows
   MouseClick("left",21,1030,1) ;TODO: change the x y coord
   Sleep(500)
   Send("cmd")
   Send("{ENTER}")
   Sleep(500)
   Send("{ENTER}")
EndFunc