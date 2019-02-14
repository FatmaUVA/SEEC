
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
Local $video24fps = "zootopia-cut-1080p-36-sec.mkv"

Local $vidLength1fps = 864000 ;video length in ms (14:24 min)
Local $vidLength24fps = 36000 ;video length in ms (36 sec)


$hVideo = play_video($video24fps)

MouseClick("left",737,538,2)


$color = PixelGetColor(1655,916)

While $color <> 3637692
   Sleep(10000)
   MsgBox($MB_OK,"","The pixel color is "& $color,$hVideo)
   $color = PixelGetColor(1655,916)
WEnd

WinClose($hVideo)



;Sleep(10000)
;$color = PixelGetColor(1655,916)
;MsgBox($MB_OK,"","The pixel color is "& $color,$hVideo)




Func play_video($vdieoName)
   Local $winTitle = "Movies & TV"
   ShellExecute($videoDir & $vdieoName)
   Local $hApp = WinWaitActive($winTitle)
   return $hApp
EndFunc