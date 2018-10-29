
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <AutoItConstants.au3>
#include <File.au3>

#RequireAdmin ; this required for clumsy to work properly

Opt("WinTitleMatchMode",-2) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase
;opt("MouseCoordMode",0)


; ============================ Parameters initialization ====================
; QoS
Local $aRTT[1] = [0];,50,100];1,2,5,10,50,100] ;,50, 150]
Local $aLoss[1] = [0];,3,5];,3] ;,0.05,1] ;packet loss rate, unit is %
Global $app = "Web"
Local $logDir = "C:\Users\Harlem5\SEEC\Windows-scripts" ;TODO: change this to the path of alexa-list-parsed.txt file
GLobal $routerIP = "172.28.30.124" ; the ip address of the server acting as router and running packet capture
Global $routerIF = "ens160" ; the router interface where the clinet is connected
GLobal $routerUsr = "harlem1"
Global $routerPsw = "harlem"
Local $timeInterval = 5000 ;TODO: change this parameter if you want to add more or less delay between task for testing
Local $clinetIPAddress = "172.28.30.9"
Global $udpPort = 60000
Global $no_tasks = 3
Global $runNo = 1
Local $no_of_runs = 1

Global $aWebsites_cate = ["search", "shop", "news", "video", "social", "forum", "misc", "bank", "chrome"]


;============================= Read website list from a file =======================

$sFileName = $logDir & "/alexa-list-parsed.txt"

; Open the file for reading and store the handle to a variable.
Local $hFileOpen = FileOpen($sFileName, $FO_READ)
If $hFileOpen = -1 Then
   MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
   Exit
EndIf

; Read the contents of the file  and save it to an attay
$no_sites = _FileCountLines($hFileOpen)
Local $aWebSites [$no_sites] ;crate array to hold web-sites

For $i = 1 to 3 ;$no_sites
   $line = FileReadLine($hFileOpen, $i)
   $aWebSites[$i-1] = $line;-1 is because the array starts with 0 and not 1
Next

; Close the handle returned by FileOpen.
FileClose($hFileOpen)

;============================= Create a file for results======================
; Create file in same folder as script one file for each website category

$oFileHandlerDict = ObjCreate("Scripting.Dictionary")
For $cate in $aWebsites_cate
   Global $sFileName = $logDir &"\results\" & $app & "_" &$cate & "_RT_autoit_run_"& $runNo  ;".txt"

   ; Open file
   Global $hFilehandle = FileOpen($sFileName, $FO_APPEND)
   ;add the file handler to the dictionary
   $oFileHandlerDict.Add ($cate, $hFilehandle)
   ; Prove it exists
   If FileExists($sFileName) Then
	   ;MsgBox($MB_SYSTEMMODAL, "File", "Exists")
   Else
	   MsgBox($MB_SYSTEMMODAL, "File", "Does not exist")
   EndIf

 Next

;=================================Create dictionary for websites ================
; the key is the website, value is the website category, for now the values are coded in the script for future we could read the values from a file\

; Create dictionary object
$oDictionary = ObjCreate("Scripting.Dictionary")

If @error Then
    MsgBox(0, '', 'Error creating the dictionary object')
 Else
	AddItemToDic($oDictionary)
EndIf

;==================================== activity =====================================

;load the web-browser (Chrome)
;log time
Local $hTimer = TimerInit() ;begin the timer and store the handler
;mark start of task with a udp packet
SendPacket("start")

ShellExecute("C:\Program Files (x86)\Google\Chrome\Application\chrome.exe","","","",@SW_MAXIMIZE)
Local $hChrome = WinWaitActive("New Tab - Google Chrome")

Local $timeDiff = TimerDiff($hTimer)/1000 ; find the time difference from the first call of TImerInit, unit sec
SendPacket("end")
$hFilehandle = $oFileHandlerDict.Item('chrome')
FileWrite($hFilehandle, $aRTT[0] & " "& $aLoss[0] & " " & $timeDiff & " ")


For $k = 0 To 3 ;$no_sites-1
   ;open new tab
   Send("^t")

   $sWebSiteTitle = StringTrimRight ( $aWebSites[$k], 4 ); to remove .com from the website name
   ;some cases where the tab title (which is used for WinWaitActive is different than the website nam
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

   Sleep($timeInterval)

   ;task 1 visit the website
   Send($aWebSites[$k]) ;type the web-site name
   $hTimer = TimerInit() ;log time
   SendPacket("start") ;send marker paket
   Send("{ENTER}") ;click enter to go the website
   $hWnd = WinWaitActive($sWebSiteTitle)
   $timeDiff = TimerDiff($hTimer)/1000
   SendPacket("end") ;send marker paket
   FileWrite($hFilehandle, $timeDiff & " ")

   ;task2 based on the website category
   $site_cate = $oDictionary.Item($aWebSites[$k])
   Switch $site_cate
   Case "search"
	  SearchTest($aWebSites[$k],$hWnd)
   Case "social"
	  SocialTest($aWebSites[$k],$hWnd)
   Case "shop"
	  ShopTest($aWebSites[$k],$hWnd)
   Case "video"
	  VideoTest($aWebSites[$k],$hWnd)
   Case "news" or "forums"
	  NewsTest($aWebSites[$k],$hWnd, $site_cate)
   Case "bank" or "misc"
	  BankTest($aWebSites[$k],$hWnd, $site_cate)

   EndSwitch

   Sleep($timeInterval)
   ;close current tab
   Send("^w")
Next

;add new line for the new Run$oFileHandlerDict = ObjCreate("Scripting.Dictionary")
For $cate in $aWebsites_cate
   $hFilehandle = $oFileHandlerDict.Item($cate)
   FileWrite($hFilehandle, @CRLF)
Next

WinClose($hChrome)

;===================================== Functions Definitions ===================================
Func ScrollDown($cate)

   $hTimer = TimerInit() ;log time before the enter to search
   SendPacket("start") ;send marker paket

   Send('{PGDN}')

   $timeDiff = TimerDiff($hTimer)/1000
   SendPacket("end") ;send marker paket
   $hFilehandle = $oFileHandlerDict.Item($cate)
   FileWrite($hFilehandle, $timeDiff & " ") ;write results to file

EndFunc

Func Search($hWnd, $x,$y,$sWord, $cate)
   _ConvertXY($x, $y) ; Convert proportionally to the actual desktop size

   MouseClick("left",$x,$y)
   Send($sWord)

   $hTimer = TimerInit() ;log time before the enter to search
   SendPacket("start") ;send marker paket

   Send('{ENTER}')

   $timeDiff = TimerDiff($hTimer)/1000
   SendPacket("end") ;send marker paket
   $hFilehandle = $oFileHandlerDict.Item($cate)
   FileWrite($hFilehandle, $timeDiff & " ") ;write results to file

EndFunc

Func ClickOnItem($hWnd, $x, $y ,$cate)
   _ConvertXY($x, $y) ; Convert proportionally to the actual desktop size

   $hTimer = TimerInit() ;log time before the enter to search
   SendPacket("start") ;send marker paket

   MouseClick("left",$x,$y)

   $timeDiff = TimerDiff($hTimer)/1000
   SendPacket("end") ;send marker paket
   $hFilehandle = $oFileHandlerDict.Item($cate)
   FileWrite($hFilehandle, $timeDiff & " ") ;write results to file

EndFunc

; Fuction to convert screen coordinates
Func _ConvertXY(ByRef $Xin, ByRef $Yin)
     $Xin = Round( ($Xin / 1680) * @DesktopWidth ) ; 1680 is the display resoution of the display where I wrote my code and based on it found the x,y coord
     $Yin = Round( ($Yin / 1050) * @DesktopHeight )
EndFunc


Func AddItemToDic(ByRef $oDictionary)
   ; The values for the dictionary are: search, social, shop, news, video, bank, forum, misc
   ; Add keys with items
    $oDictionary.Add ("Google.com", "search" )
    $oDictionary.Add ("Youtube.com", "video" )
    $oDictionary.Add ("Facebook.com","social" )
    $oDictionary.Add ("Amazon.com", "shop" )
    $oDictionary.Add ("Reddit.com","news" )
    $oDictionary.Add ("Yahoo.com", "search" )
    $oDictionary.Add ("Cnn.com", "news" )
    $oDictionary.Add ("Breitbart.com", "news" )
    $oDictionary.Add ("Nytimes.com", "news" )
    $oDictionary.Add ("Stackoverflow.com", "forum" )
    $oDictionary.Add ("Quora.com", "forum" )
    $oDictionary.Add ("Amazonaws.com", "misc" )

	;TODO: add the websites you worked with, I'll add the rest, make sure to type the site exactly as it shown in the website list file
EndFunc


Func SearchTest ($webSite, $hWnd)
;TODO: add other websites with x, y coord to click on the search bar
MsgBox($MB_SYSTEMMODAL, "", "Inside search test.")
   $cate = "search"
   ;task2 search on word
   Switch $webSite
   Case "Google.com"
	  Search($hWnd, 840,412,"speaker", $cate)

   EndSwitch

   Sleep($timeInterval)

   ;task3 scroll down
   ScrollDown($cate)

EndFunc

Func SocialTest ($webSite, $hWnd)

   $cate = "social"
   ;task2 scroll down
   ScrollDown($cate)

   Sleep($timeInterval)

   ;TODO: add other websites with x, y coord to click on post/item
   ;task3 click on post item
   Switch $webSite
   Case "Facebook.com"
	  ClickOnItem($hWnd, 600,700,$cate) ; the x,y are not real just random number, need to change to the actual x,y coord
   EndSwitch

EndFunc

Func ShopTest ($webSite, $hWnd)
   ;TODO: add other websites with actual x,y coord for search and click on item/post

   $cate = "shop"
   ;task2 search on word
   Switch $webSite
   Case "Amazon.com"
	  Search($hWnd, 660,156,"speaker", $cate)
   Case "Ebay.com"
	  Search($hWnd, 600,130,"speaker", $cate)
   EndSwitch

   Sleep($timeInterval)

   ;task3 scroll down
   ScrollDown($cate, $hWnd)

   Sleep($timeInterval)

   ;task4
   Switch $webSite
   Case "Facebook.com"
	  ClickOnItem($hWnd, 600,700,$cate) ; the x,y are not real just random number, need to change to the actual x,y coord
   EndSwitch

EndFunc

Func VideoTest ($webSite, $hWnd)

   $cate= "video"
   ;task2 scroll down
   ScrollDown($cate)

   Sleep($timeInterval)

   ;TODO: add other websites with x, y coord to click on post/item
   ;task3 click on post item
   Switch $webSite
   Case "Youtube.com"
	  Search($hWnd, 679,100,"speaker", $cate)
   EndSwitch
EndFunc

Func NewsTest ($webSite, $hWnd, $cate)

   ;task2 scroll down
   ScrollDown($cate)

   Sleep($timeInterval)

   ;TODO: add other websites with x, y coord to click on post/item
   ;task3 click on post item
   Switch $webSite
   Case "Cnn.com"
	  ClickOnItem($hWnd, 441,192,$cate)
   Case "Nytimes.com"
	  ClickOnItem($hWnd, 687,607,$cate)
   Case "Breitbart.com"
	  ClickOnItem($hWnd, 719,724,$cate)
   Case "Quora.com"
	  ClickOnItem($hWnd, 712,431,$cate)
   Case "Stackoverflow.com"
	  ClickOnItem($hWnd, 692,683,$cate)
   EndSwitch

EndFunc

Func BankTest ($webSite, $hWnd, $cate)
   ;task2 scroll down
   ScrollDown($cate)
   
   Sleep($timeInterval)
   
   Switch $webSite
   Case "Amazonaws.com"
   	ClickOnItem($nWnd, 286, 681, $cate)
   EndSwitch
EndFunc



Func SendPacket($msg)
   Return
EndFunc

 Func router_command($cmd, $videoSpeed="slow", $rtt=0, $loss=0, $n=0); cmd: "start_capture", "stop_capture", "analyze"
   Return
EndFunc






