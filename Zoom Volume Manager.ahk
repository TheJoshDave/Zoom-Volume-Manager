#SingleInstance Force
SetTitleMatchMode, 1
global CurrentVolume := 100
global SaveVolume := 100
global Muted := false
global GuiWindowActive := false
global GuiWindowActiveSeconds := 0
global GuiWindowWidth := 80
global GuiWindowHeight := 40
global GuiWindowGap := 40
global WindowHwnd

global Folder := A_Temp "\ZoomVolumeManager\"
FileCreateDir, % Folder
FileInstall, C:\Users\Dave\Desktop\Programming\Code\AutoHotKey\ZoomVolume\Icon.png, % Folder "icon.png", 1

SetTimer, UpdateGuiWindow, 100
SetTimer, VolumeUpdate, 500
return


#If WinActive("ahk_exe Zoom.exe") || WinActive("ahk_id" WindowHwnd)
Volume_Down::VolumeAjust(-1)
Volume_Up::VolumeAjust(1)
Volume_Mute::Mute()
XButton2::
	WinMove, A,, -9, -9, 1938, 1048
return
#IfWinActive

Mute() {
	WinGet, ZoomOutputVar, PID, ahk_exe Zoom.exe
	if (!Muted) {
		SaveVolume := CurrentVolume
		CurrentVolume := 0
	} else
		CurrentVolume := SaveVolume
	Muted := !Muted ; toggles mode
	if (!GuiWindowActive)
		StartGuiWindow()
	else
		GuiWindowActiveSeconds := 3
	Sleep, 100
}
VolumeAjust(value) {
	WinGet, ZoomOutputVar, PID, ahk_exe Zoom.exe
	if (Muted) {
		CurrentVolume := SaveVolume
		Muted := false
	}
	CurrentVolume += value
	CurrentVolume := CurrentVolume > 100 ? 100 : CurrentVolume < 0 ? 0 : CurrentVolume
	if (!GuiWindowActive)
		StartGuiWindow()
	else
		GuiWindowActiveSeconds := 3
}
StartGuiWindow() {
	Gui, New, +AlwaysOnTop -Caption +Owner HwndWindowHwnd, Volume
	Gui, Font, S12 CFFFFFF, Arial
	Gui, Add, Text,, % 100
	Gui, Color, 000000
	Gui, Add, Picture, X44 Y6 W32 H32, % Folder "icon.png"
	Gui, Show
	, % "X" GuiWindowGap "Y" GuiWindowGap "W" GuiWindowWidth "H" GuiWindowHeight
	WinSet, Transparent, % (255 - 48), ahk_id %WindowHwnd%

	
	Gosub TextUpdate
	
	GuiWindowActive := true
	GuiWindowActiveSeconds := 3
}
UpdateGuiWindow:
	if (GuiWindowActive == true) {
		if (GuiWindowActiveSeconds <= 0) {
			WinClose, ahk_id %WindowHwnd%
		} else {
			GoSub TextUpdate
			GuiWindowActiveSeconds -= 0.1
		}
	}
return
VolumeUpdate:
	WinGet, ZoomOutputVar, PID, ahk_exe Zoom.exe
	SetAppVolume(ZoomOutputVar, CurrentVolume)
return
TextUpdate:
	ControlGet, OutputVar, Hwnd,, Static1, ahk_id %WindowHwnd%
	GuiControl, Text, %OutputVar%, % CurrentVolume
	
	GuiControlGet, Text, Pos, %OutputVar%
	GuiTextX := ((GuiWindowWidth/10))
	GuiTextY := ((GuiWindowHeight/2)-(TextH/2))
	GuiControl, Move, %OutputVar%, % "x" GuiTextX "y" GuiTextY
return
GuiClose:
	GuiWindowActive := false
	GuiWindowActiveSeconds := 0
	Gui, Destroy
return






GetAppVolume(PID) {
    Local MasterVolume := ""

    IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+4*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 1, "UPtrP", IMMDevice, "UInt")
    ObjRelease(IMMDeviceEnumerator)

    VarSetCapacity(GUID, 16)
    DllCall("Ole32.dll\CLSIDFromString", "Str", "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}", "UPtr", &GUID)
    DllCall(NumGet(NumGet(IMMDevice+0)+3*A_PtrSize), "UPtr", IMMDevice, "UPtr", &GUID, "UInt", 23, "UPtr", 0, "UPtrP", IAudioSessionManager2, "UInt")
    ObjRelease(IMMDevice)

    DllCall(NumGet(NumGet(IAudioSessionManager2+0)+5*A_PtrSize), "UPtr", IAudioSessionManager2, "UPtrP", IAudioSessionEnumerator, "UInt")
    ObjRelease(IAudioSessionManager2)

    DllCall(NumGet(NumGet(IAudioSessionEnumerator+0)+3*A_PtrSize), "UPtr", IAudioSessionEnumerator, "UIntP", SessionCount, "UInt")
    Loop % SessionCount {
        DllCall(NumGet(NumGet(IAudioSessionEnumerator+0)+4*A_PtrSize), "UPtr", IAudioSessionEnumerator, "Int", A_Index-1, "UPtrP", IAudioSessionControl, "UInt")
        IAudioSessionControl2 := ComObjQuery(IAudioSessionControl, "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}")
        ObjRelease(IAudioSessionControl)

        DllCall(NumGet(NumGet(IAudioSessionControl2+0)+14*A_PtrSize), "UPtr", IAudioSessionControl2, "UIntP", currentProcessId, "UInt")
        If (PID == currentProcessId) {
            ISimpleAudioVolume := ComObjQuery(IAudioSessionControl2, "{87CE5498-68D6-44E5-9215-6DA47EF883D8}")
            DllCall(NumGet(NumGet(ISimpleAudioVolume+0)+4*A_PtrSize), "UPtr", ISimpleAudioVolume, "FloatP", MasterVolume, "UInt")
            ObjRelease(ISimpleAudioVolume)
        }
        ObjRelease(IAudioSessionControl2)
    }
    ObjRelease(IAudioSessionEnumerator)

    Return Round(MasterVolume * 100)
}
SetAppVolume(PID, MasterVolume) {
    MasterVolume := MasterVolume > 100 ? 100 : MasterVolume < 0 ? 0 : MasterVolume

    IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+4*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 1, "UPtrP", IMMDevice, "UInt")
    ObjRelease(IMMDeviceEnumerator)

    VarSetCapacity(GUID, 16)
    DllCall("Ole32.dll\CLSIDFromString", "Str", "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}", "UPtr", &GUID)
    DllCall(NumGet(NumGet(IMMDevice+0)+3*A_PtrSize), "UPtr", IMMDevice, "UPtr", &GUID, "UInt", 23, "UPtr", 0, "UPtrP", IAudioSessionManager2, "UInt")
    ObjRelease(IMMDevice)

    DllCall(NumGet(NumGet(IAudioSessionManager2+0)+5*A_PtrSize), "UPtr", IAudioSessionManager2, "UPtrP", IAudioSessionEnumerator, "UInt")
    ObjRelease(IAudioSessionManager2)

    DllCall(NumGet(NumGet(IAudioSessionEnumerator+0)+3*A_PtrSize), "UPtr", IAudioSessionEnumerator, "UIntP", SessionCount, "UInt")
    Loop % SessionCount {
        DllCall(NumGet(NumGet(IAudioSessionEnumerator+0)+4*A_PtrSize), "UPtr", IAudioSessionEnumerator, "Int", A_Index-1, "UPtrP", IAudioSessionControl, "UInt")
        IAudioSessionControl2 := ComObjQuery(IAudioSessionControl, "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}")
        ObjRelease(IAudioSessionControl)

        DllCall(NumGet(NumGet(IAudioSessionControl2+0)+14*A_PtrSize), "UPtr", IAudioSessionControl2, "UIntP", currentProcessId, "UInt")
        If (PID == currentProcessId) {
            ISimpleAudioVolume := ComObjQuery(IAudioSessionControl2, "{87CE5498-68D6-44E5-9215-6DA47EF883D8}")
            DllCall(NumGet(NumGet(ISimpleAudioVolume+0)+3*A_PtrSize), "UPtr", ISimpleAudioVolume, "Float", MasterVolume/100.0, "UPtr", 0, "UInt")
            ObjRelease(ISimpleAudioVolume)
        }
        ObjRelease(IAudioSessionControl2)
    }
    ObjRelease(IAudioSessionEnumerator)
}