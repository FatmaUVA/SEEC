
#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Fatma Alali
 Script Function:
	RT objective test for GIMP
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
Local $aLoss[1] = [0];,3] ;,0.05,1] ;packet loss rate, unit is %
Global $app = "ImageView"
Local $logDir = "C:\Users\fha6np\Desktop\SEEC\Windows-scripts"
local $picsDir = $logDir & "\Pics10\"
local $picsExt = ".jpg"
GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected
GLobal $routerUsr = "harlem1"
Global $routerPsw = "harlem"
Local $timeInterval = 6000 ;30000
Local $picName = "test-pic"
Local $clinetIPAddress = "172.28.30.9"
Global $udpPort = 60000
Global $no_tasks = 6
Global $runNo = "1-Pics13-model1"
Local $no_of_runs = 25



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

;#comments-start
 ;=====================open the app and load all pic to RAM============
;ShellExecute($logDir & "\Pics\1.jpg","","","",@SW_MAXIMIZE)
;Local $hImage = WinWaitActive("Photos")
;WinClose($hImage)
Local $i = 1
while  $i <= $no_tasks
   ;Send('{RIGHT}') ;send right arrrow to move to next pic
   ;ShellExecute($picsDir &$i&".jpg","","","",@SW_MAXIMIZE)
   ShellExecute($picsDir &$i&$picsExt,"","","",@SW_MAXIMIZE)
   Local $hImage = WinWaitActive("Photo")
   ;MsgBox($MB_SYSTEMMODAL, "File", "pic opened")
   WinClose($hImage)
   $i = $i + 1
WEnd
;#comments-end

;================= Start actual test =============================

For $n = 1 To $no_of_runs

For $j = 0 To UBound($aLoss) - 1
   For $i = 0 To UBound($aRTT) - 1

	  ;load the first image
	  ;log time
	  Local $hTimer = TimerInit() ;begin the timer and store the handler

	  ShellExecute($picsDir & "1" & $picsExt,"","","",@SW_MAXIMIZE)
	  Local $hImage = WinWaitActive("Photo")

	  Local $timeDiff = TimerDiff($hTimer)/1000 ; find the time difference from the first call of TImerInit, unit sec

	  FileWrite($hFilehandle, $aRTT[$i] & " "& $aLoss[$j] & " " & $timeDiff & " ")
	  Sleep($timeInterval)
	  WinClose($hImage)



	  ;load images one by one with sleep in between
	  Local $k = 2
	  while  $k <= $no_tasks


		 ;log time
		 Local $hTimer = TimerInit() ;begin the timer and store the handler

		 ShellExecute($picsDir &$k&$picsExt,"","","",@SW_MAXIMIZE)
		 $hImage = WinWaitActive("Photo")

		 Local $timeDiff = TimerDiff($hTimer)/1000 ; find the time difference from the first call of TImerInit, unit sec

		 FileWrite($hFilehandle, $timeDiff & " ")

		 Sleep($timeInterval)
		 WinClose($hImage)
		 $k = $k + 1



	  WEnd

	  FileWrite($hFilehandle, @CRLF) ;add new line to the file

   Next
Next

Next





