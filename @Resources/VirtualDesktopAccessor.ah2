; AutoHotkey v2 script
SetWorkingDir(A_ScriptDir)

; Path to the DLL, relative to the script
VDA_PATH := A_ScriptDir . "\VirtualDesktopAccessor.dll"
hVirtualDesktopAccessor := DllCall("LoadLibrary", "Str", VDA_PATH, "Ptr")

if (A_PtrSize != 8) {
    MsgBox("This build is 32-bit. Recompile VirtualDesktopAccessor.exe as 64-bit.", "VirtualDesktopAccessor", "Iconx")
    ExitApp(2)
}
if (!hVirtualDesktopAccessor) {
    MsgBox("Failed to load DLL:`n" VDA_PATH, "VirtualDesktopAccessor", "Iconx")
    ExitApp(2)
}

GetDesktopCountProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopCount", "Ptr")
GoToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GoToDesktopNumber", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetCurrentDesktopNumber", "Ptr")
IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnCurrentVirtualDesktop", "Ptr")
IsWindowOnDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsWindowOnDesktopNumber", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "MoveWindowToDesktopNumber", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "IsPinnedWindow", "Ptr")
GetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "GetDesktopName", "Ptr")
SetDesktopNameProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "SetDesktopName", "Ptr")
CreateDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "CreateDesktop", "Ptr")
RemoveDesktopProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RemoveDesktop", "Ptr")

; On change listeners
RegisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "RegisterPostMessageHook", "Ptr")
UnregisterPostMessageHookProc := DllCall("GetProcAddress", "Ptr", hVirtualDesktopAccessor, "AStr", "UnregisterPostMessageHook", "Ptr")

if (!GetDesktopCountProc || !GoToDesktopNumberProc || !GetCurrentDesktopNumberProc || !CreateDesktopProc || !RemoveDesktopProc) {
    MsgBox("Failed to resolve one or more required exports from VirtualDesktopAccessor.dll.", "VirtualDesktopAccessor", "Iconx")
    ExitApp(3)
}

CleanupAndExit(code := 0) {
    global hVirtualDesktopAccessor
    if (hVirtualDesktopAccessor) {
        DllCall("FreeLibrary", "Ptr", hVirtualDesktopAccessor)
    }
    ExitApp(code)
}

GetDesktopCount() {
    global GetDesktopCountProc
    count := DllCall(GetDesktopCountProc, "Int")
    return count
}

MoveCurrentWindowToDesktop(number) {
    global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc
    activeHwnd := WinGetID("A")
    DllCall(MoveWindowToDesktopNumberProc, "Ptr", activeHwnd, "Int", number, "Int")
    DllCall(GoToDesktopNumberProc, "Int", number, "Int")
}

GoToPrevDesktop() {
    global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is 0, go to last desktop
    if (current = 0) {
        MoveOrGotoDesktopNumber(last_desktop)
    } else {
        MoveOrGotoDesktopNumber(current - 1)
    }
    return
}

GoToNextDesktop() {
    global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
    current := DllCall(GetCurrentDesktopNumberProc, "Int")
    last_desktop := GetDesktopCount() - 1
    ; If current desktop is last, go to first desktop
    if (current = last_desktop) {
        MoveOrGotoDesktopNumber(0)
    } else {
        MoveOrGotoDesktopNumber(current + 1)
    }
    return
}

GoToDesktopNumber(num) {
    global GoToDesktopNumberProc
    DllCall(GoToDesktopNumberProc, "Int", num, "Int")
    return
}
MoveOrGotoDesktopNumber(num) {
    ; If user is holding down Mouse left button, move the current window also
    if (GetKeyState("LButton")) {
        MoveCurrentWindowToDesktop(num)
    } else {
        GoToDesktopNumber(num)
    }
    return
}
GetDesktopName(num) {
    global GetDesktopNameProc
    utf8_buffer := Buffer(1024, 0)
    ran := DllCall(GetDesktopNameProc, "Int", num, "Ptr", utf8_buffer, "Ptr", utf8_buffer.Size, "Int")
    name := StrGet(utf8_buffer, 1024, "UTF-8")
    return name
}
SetDesktopName(num, name) {
    global SetDesktopNameProc
    OutputDebug(name)
    name_utf8 := Buffer(1024, 0)
    StrPut(name, name_utf8, "UTF-8")
    ran := DllCall(SetDesktopNameProc, "Int", num, "Ptr", name_utf8, "Int")
    return ran
}
CreateDesktop() {
    global CreateDesktopProc
    ran := DllCall(CreateDesktopProc, "Int")
    return ran
}
RemoveDesktop(remove_desktop_number, fallback_desktop_number) {
    global RemoveDesktopProc
    ran := DllCall(RemoveDesktopProc, "Int", remove_desktop_number, "Int", fallback_desktop_number, "Int")
    return ran
}

; CLI mode for Rainmeter / RunCommand:
;   GoToDesktopNumber <zeroBased>
;   MoveToDesktop <oneBased>
;   CreateDesktop
;   RemoveDesktop <zeroBasedTarget> <zeroBasedFallback>
;   DeleteDesktopAt <oneBasedTarget> <oneBasedFallback>
if (A_Args.Length > 0) {
    cmd := A_Args[1]

    if (cmd = "GoToDesktopNumber" && A_Args.Length >= 2) {
        GoToDesktopNumber(Integer(A_Args[2]))
        CleanupAndExit()
    }

    if (cmd = "MoveToDesktop" && A_Args.Length >= 2) {
        GoToDesktopNumber(Integer(A_Args[2]) - 1)
        CleanupAndExit()
    }

    if (cmd = "CreateDesktop") {
        CreateDesktop()
        CleanupAndExit()
    }

    if (cmd = "RemoveDesktop" && A_Args.Length >= 3) {
        RemoveDesktop(Integer(A_Args[2]), Integer(A_Args[3]))
        CleanupAndExit()
    }

    if (cmd = "DeleteDesktopAt" && A_Args.Length >= 3) {
        count := GetDesktopCount()
        if (count <= 1) {
            CleanupAndExit()
        }

        target := Integer(A_Args[2]) - 1
        fallback := Integer(A_Args[3]) - 1

        if (target < 0) {
            target := 0
        }
        if (target >= count) {
            target := count - 1
        }
        if (fallback < 0) {
            fallback := 0
        }
        if (fallback >= count) {
            fallback := count - 1
        }
        if (fallback = target) {
            if (target > 0) {
                fallback := target - 1
            } else {
                fallback := 1
            }
        }

        RemoveDesktop(target, fallback)
        CleanupAndExit()
    }

    CleanupAndExit(1)
}

; SetDesktopName(0, "It works! 🐱")

DllCall(RegisterPostMessageHookProc, "Ptr", A_ScriptHwnd, "Int", 0x1400 + 30, "Int")
OnMessage(0x1400 + 30, OnChangeDesktop)
OnChangeDesktop(wParam, lParam, msg, hwnd) {
    Critical(1)
    OldDesktop := wParam + 1
    NewDesktop := lParam + 1
    Name := GetDesktopName(NewDesktop - 1)

    ; Use Dbgview.exe to checkout the output debug logs
    OutputDebug("Desktop changed to " Name " from " OldDesktop " to " NewDesktop)
    ; TraySetIcon(".\Icons\icon" NewDesktop ".ico")
}

; #^!+1::MoveOrGotoDesktopNumber(0)
; #^!+2::MoveOrGotoDesktopNumber(1)
; #^!+3::MoveOrGotoDesktopNumber(2)
; #^!+4::MoveOrGotoDesktopNumber(3)
; #^!+5::MoveOrGotoDesktopNumber(4)
; #^!+q::MoveOrGotoDesktopNumber(5)
; #^!+w::MoveOrGotoDesktopNumber(6)
; #^!+e::MoveOrGotoDesktopNumber(7)
; #^!+r::MoveOrGotoDesktopNumber(8)
; #^!+t::MoveOrGotoDesktopNumber(9)
; #^!+x::MoveOrGotoDesktopNumber(10)
; #^!+c::MoveOrGotoDesktopNumber(11)
; #^!+v::MoveOrGotoDesktopNumber(12)
; #^!+b::MoveOrGotoDesktopNumber(13)


F13 & 1:: MoveOrGotoDesktopNumber(0)
F13 & 2:: MoveOrGotoDesktopNumber(1)
F13 & 3:: MoveOrGotoDesktopNumber(2)
F13 & 4:: MoveOrGotoDesktopNumber(3)
F13 & 5:: MoveOrGotoDesktopNumber(4)
F13 & q:: MoveOrGotoDesktopNumber(5)
F13 & w:: MoveOrGotoDesktopNumber(6)
F13 & e:: MoveOrGotoDesktopNumber(7)
F13 & r:: MoveOrGotoDesktopNumber(8)
F13 & t:: MoveOrGotoDesktopNumber(9)
F13 & x:: MoveOrGotoDesktopNumber(10)
F13 & c:: MoveOrGotoDesktopNumber(11)
F13 & v:: MoveOrGotoDesktopNumber(12)
F13 & b:: MoveOrGotoDesktopNumber(13)
F14 UP:: GoToPrevDesktop()
F15 UP:: GoToNextDesktop()
