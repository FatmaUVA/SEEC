
#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Fatma Alali
 Script Function:
	RT objective test for web-browsing
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
#include <File.au3>

#RequireAdmin ; this required for clumsy to work properlys

Opt("WinTitleMatchMode",-2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase ;used for WInWaitActive title matching


; ============================ Parameters initialization ====================
; QoS
Local $aRTT[1] = [0];,50,100];1,2,5,10,50,100] ;,50, 150]
Local $aLoss[3] = [0,3,5];,3] ;,0.05,1] ;packet loss rate, unit is %
Global $app = "WebBrowsing"
Local $logDir = "C:\Users\Harlem5\SEEC\Windows-scripts"
GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected
GLobal $routerUsr = "harlem1"
Global $routerPsw = "harlem"
Local $timeInterval = 20000 ;30000
Local $picName = "test-pic"
Local $clinetIPAddress = "172.28.30.9"
Global $udpPort = 60000
Global $no_tasks = 15
Global $runNo = 3
Local $no_of_runs = 15

;============================= Read website list from a file =======================

$sFileName = $logDir & "/alexa-list-parsed-cleaned.txt"

; Open the file for reading and store the handle to a variable.
Local $hFileOpen = FileOpen($sFileName, $FO_READ)
If $hFileOpen = -1 Then
   MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
   Exit
EndIf

; Read the contents of the file  and save it to an attay
$no_sites = _FileCountLines($hFileOpen)
Local $aWebSites [$no_sites] ;crate array to hold web-sites

For $i = 1 to $no_sites
   $line = FileReadLine($hFileOpen, $i)
   $aWebSites[$i-1] = $line;-1 is because the array starts with 0 and not 1
Next

; Close the handle returned by FileOpen.
FileClose($hFileOpen)

;============================= Create a file for results======================
; Create file in same folder as script
Global $sFileName = $logDir &"\results\" & $app &"_RT_autoit_run_"& $runNo  ;".txt"

; Open file
Global $hFilehandle = FileOpen($sFileName, $FO_APPEND)

; Prove it exists
If FileExists($sFileName) Then
    ;MsgBox($MB_SYSTEMMODAL, "File", "Exists")
Else
    MsgBox($MB_SYSTEMMODAL, "File", "Does not exist")
 EndIf


;================= Start  test =============================
;setup clumsy basic param to prepare for network configuration
Local $hClumsy = Clumsy("", "open", $clinetIPAddress)

For $n = 1 To $no_of_runs:

For $j = 0 To UBound($aLoss) - 1
   For $i = 0 To UBound($aRTT) - 1
	  ;configure clumsy
	  Clumsy($hClumsy, "configure","",$aRTT[$i], $aloss[$j])
	  Clumsy($hClumsy, "start")

	  ; start packet capture
	  router_command("start_capture")

	  ;setup UDP socket
	  SetupUDP($clinetIPAddress, $udpPort)

	  Sleep($timeInterval)

	  ;load the web-browser (Chrome)
	  ;log time
	  Local $hTimer = TimerInit() ;begin the timer and store the handler
	  ;mark start of task with a udp packet
	  SendPacket("start")

	  ShellExecute("C:\Program Files (x86)\Google\Chrome\Application\chrome.exe","","","",@SW_MAXIMIZE)
	  Local $hChrome = WinWaitActive("New Tab - Google Chrome")

	  Local $timeDiff = TimerDiff($hTimer)/1000 ; find the time difference from the first call of TImerInit, unit sec
	  SendPacket("end")
	  FileWrite($hFilehandle, $aRTT[$i] & " "& $aLoss[$j] & " " & $timeDiff & " ")
	  Sleep($timeInterval)


	  For $k = 0 To $no_sites-1
		 ;open new tab
		 Send("^t")

		 $sWebSiteTitle = StringTrimRight ( $aWebSites[$k], 4 ); to remove .com from the website name
		 If $sWebSiteTitle == "Wikia" Then
			$sWebSiteTitle = "FANDOM"
		 ElseIf $sWebSiteTitle  == "Nytimes" Then
			$sWebSiteTitle = "New York Times"
		  ElseIf $sWebSiteTitle  == "Stackoverflow" Then
			$sWebSiteTitle = "Stack"
		 ElseIf $sWebSiteTitle  == "Bankofamerica" or == $sWebSiteTitle "Wellsfargo" Then
			$sWebSiteTitle = "bank"
		 ElseIf $sWebSiteTitle  == "Amazonaws" Then
			$sWebSiteTitle = "Amazon"
			EndIf

		 Sleep(1000)

		 ;vist the web-site
		 Send($aWebSites[$k]) ;type the web-site name
		 $hTimer = TimerInit() ;log time
		 SendPacket("start") ;send marker paket
		 Send("{ENTER}") ;click enter to go the website
		 WinWaitActive($sWebSiteTitle)
		 $timeDiff = TimerDiff($hTimer)/1000
		 SendPacket("end") ;send marker paket
		 FileWrite($hFilehandle, $timeDiff & " ")

		 Sleep($timeInterval)
		 ;close current tab
		 Send("^w")
	  Next

	  FileWrite($hFilehandle, @CRLF) ;add new line to the file

	  ;stop capture
	  router_command("stop_capture")

	  ;analyze results
	  router_command("analyze_results","",$aRTT[$i], $aLoss[$j],$n) ;$n is the count within one run

	  Clumsy($hClumsy, "stop")

   Next
Next

 ;close chrome
 WinClose($hChrome)

Next

 WinClose($hClumsy)




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


Func router_command($cmd, $videoSpeed="slow", $rtt=0, $loss=0, $n=0); cmd: "start_capture", "stop_capture", "analyze"

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
	  Send($command)
	  Send("{ENTER}")
	  Send("{ENTER}")
	  Sleep(40000) ; becaue it takes some time to process and we don't want to overwrite the pcap


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

