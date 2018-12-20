#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <ButtonConstants.au3>
#include <FontConstants.au3>
#include <AutoItConstants.au3>

;#pragma compile(AutoItExecuteAllowed, true)
#RequireAdmin

$script1 = "web360-obj.au3"
$script2 = "image-view-RT.au3"



RunWait(@AutoItExe & " /AutoIt3ExecuteScript "& $script2)

Sleep(600000)

RunWait(@AutoItExe & " /AutoIt3ExecuteScript "& $script2)

Sleep(600000)

RunWait(@AutoItExe & " /AutoIt3ExecuteScript "& $script1)

