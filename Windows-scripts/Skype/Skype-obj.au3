
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
		 Sleep(1000)
		 OpenTerminal()
		 Sleep(500)
		 ;run audio playing script
		 $cmd = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype\play-audio.au3"
		 Send($cmd)
		 Send("{ENTER}")
		 WinClose($hRec)

		 ;========run playing audio script at caller PC
		 $hCall = RDP()
		 WinMove($hRec,"",0,0,@DesktopWidth, @DesktopHeight-50)
		 ;open command prompt in Recorder PC
		 Sleep(1000)
		 OpenTerminal()
		 ;run recording script
		 Sleep(500)
		 $cmd = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts\Skype\record-audio.au3 " & $aLoss[$j])
		 Send($cmd)
		 Send("{ENTER}")

		 WinClose($hCall)

		 ;sleep  til the audio finish playing
		 Sleep(1000)

		 ;=======stop recording and run export script

		 ;parse results and write results to file

		 #comments-start
		 ; start packet capture
		 router_command("start_capture")

		 ;setup UDP socket
		 SetupUDP($clinetIPAddress, $udpPort)

		 Sleep($timeInterval)

		 ;loop through all images
		 For $k = 0 To UBound($imageURL) - 1

			;activate app window
			WinActivate($hApp)

			;open new tab in the web browser
			Send("^t")
			Sleep(500)

			;visit the image URL
			Send($imageURL[$k])
			Send('{ENTER}')
			WinWaitActive("rodedwards")

			;stop auto movement and sound
			MouseClick("left",835,310)
			Sleep(500)
			MouseClick("left",872,972)
			Sleep(500)
			MouseClick("left",932,972)


			;task1: click and drag
			SendPacket("start")
			MouseClickDrag($MOUSE_CLICK_LEFT, 1386, 497, 884, 497, 1) ;x1,y1,x2,y2,speed(1 fastest, 100 slowest)
			SendPacket("end")

			Sleep($timeInterval)

			;task2: zoom-in
			SendPacket("start")
			MouseWheel($MOUSE_WHEEL_UP, 20)
			SendPacket("end")

			Sleep($timeInterval)

			;task3: zoom-out
			SendPacket("start")
			MouseWheel($MOUSE_WHEEL_DOWN, 20)
			SendPacket("end")

			Sleep($timeInterval)

			;close current tab
			Send("^w")
			#comments-end
		 Clumsy($hClumsy, "stop")

	  Next
   Next
Next

WinClose($hClumsy)
WinClose($hRec)
WinClose($hCall)


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
   Sleep(5000)
EndFunc


Func SetupUDP($sIPAddress, $iPort)
	UDPStartup() ; Start the UDP service.

    ; Register OnAutoItExit to be called when the script is closed.
    OnAutoItExitRegister("OnAutoItExit")

	; Assign a Local variable the socket and connect to a listening socket with the IP Address and Port specified.
    Global $iSocket = UDPOpen($sIPAddress, $iPort,1); 1 flag indicates broadcast, because at the zero clinet we cannot run a UDP server
    Local $iError = 0

    ; If an error occurred display the error code and return False.
    If @error Then
        ; The server is probably offline/port is not opened on the server.
        $iError = @error
        MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", "Client:" & @CRLF & "Could not connect, Error code: " & $iError)
        Return False
    EndIf


    ; Close the socket.
    ;UDPCloseSocket($iSocket)
EndFunc   ;==>MyUDP_Client

Func OnAutoItExit()
    UDPShutdown() ; Close the UDP service.
EndFunc   ;==>OnAutoItExit


Func SendPacket($msg)
	    ; Send the string "toto" converted to binary to the server.
    UDPSend($iSocket, StringToBinary($msg))

    ; If an error occurred display the error code and return False.
    If @error Then
        $iError = @error
        MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", "Client:" & @CRLF & "Could not send the data, Error code: " & $iError)
        Return False
    EndIf
EndFunc


Func router_command($cmd, $videoSpeed="slow", $rtt=0, $loss=0,$n=0); cmd: "start_capture", "stop_capture", "analyze"

	; open putty
	ShellExecute("C:\Program Files\PuTTY\putty")
	;ShellExecute($videoDir & $vdieoName)
	Local $hPutty = WinWaitActive("PuTTY Configuration")

	;connect to the router linux server
	;Send($routerIP)
	ControlSend("","","",$routerIP)
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

	  ElseIf $cmd = "compute_plot" Then
	  $command = "sh SEEC/Windows-scripts/compute-thru.sh  capture-1-slow.pcap "  & $clinetIPAddress & " " & $rtt & " " & $loss
	  Send($command)
	  Send("{ENTER}")

	  ElseIf $cmd = "analyze_results" Then
	  $command = "nohup sh SEEC/Windows-scripts/analyze_RT.sh  " & $clinetIPAddress & " " & $rtt & " " & $loss & " " & $no_tasks & " " & $app & " " & $runNo & " " & $n & " & disown" ;I'm using nohup & disown so that the process is not killed when autoit quit the terminal
	  ;$command = "sh SEEC/Windows-scripts/analyze_RT.sh  " & $clinetIPAddress & " " & $rtt & " " & $loss & " " & $no_tasks & " " & $app & " " & $runNo  & " " & $n
	  Send($command)
	  Send("{ENTER}")
	  Send("{ENTER}")
	  Sleep(20000)


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
	  ControlClick($hWnd, "","Button2", "left", 1,8,8)

   ElseIf $cmd = "stop" Then
	  ;click the start button
	  ControlClick($hWnd, "","Button2", "left", 1,8,8)

   EndIf
EndFunc


