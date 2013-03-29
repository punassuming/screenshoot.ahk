#SingleInstance, Force
#Persistent
#Include %A_ScriptDir%/lib/Gdip.ahk
Menu, Tray, Icon, Shell32.dll, 260 
Menu, Tray, NoStandard

Menu, Tray, Tip, Screenshot Clipper
Menu, Tray, Click, 1
Menu, Tray, add, Take Screen Shot, SClip
Menu, Tray, add
Menu, SendSub, add, To Onenote, SClip
Menu, SendSub, add, To Current Window, SClip
Menu, SendSub, add, To Desktop, SClip
Menu, Tray, add, Send To, :SendSub
Menu, Tray, Default, Take Screen Shot
Menu, Tray, Add
Menu, Tray, Add, Reload, ReloadSub
Menu, Tray, Add, Exit, ExitSub

^!s::ScreenCapture() ; Executes the Screenshot to clip function

ToolTipOff:
ToolTip
return

; Defines area then takes screenshot and stores it on the clipboard
SClip:
ScreenCapture()
return

ScreenCapture(location:="clipboard"){

    Global OverlayFlag
    DefineBox(TLX, TLY, BLX, BLY, BW, BH)
    mode := "box"

    If (OverlayFlag = "Error")
    {
        ToolTip, Error: Screencap exited
        SetTimer, ToolTipOff, -3000 
        return
    }

    ToDesktop := GetKeyState("Control", "P")
    ShowMenu := GetKeyState("Alt", "P")

    If (BW + BH < 20) {
        MouseGetPos, , , VarWin
        WinGetPos, TLX, TLY, BW, BH, ahk_id %VarWin%
        mode := "window"
    }

    WinGetClass, winClass, ahk_id %VarWin%

    If (winClass = "Shell_TrayWnd" or winClass = "Progman") {
        ScreenPass := 0
        mode := "desktop"
    } Else {
        ScreenPass := TLX "|" TLY "|" BW "|" BH
    }

    if (!pToken:=Gdip_Startup()) {
          msgbox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
          ExitApp
    }

    MypBitmap := Gdip_BitmapFromScreen(ScreenPass)

    If (ToDesktop) {
        FormatTime, TimeStamp, , yyyyMMdd_HHmmss
        Gdip_SaveBitmapToFile(MypBitmap, A_Desktop . "\" . TimeStamp . ".png")
        location := "desktop"
    } else {
        Gdip_SetBitmapToClipboard(MypBitmap)
        location := "clipboard"
    }

    DeleteObject(MypBitmap)
    Gdip_DisposeImage(MypBitmap)
    ; Gdip_Shutdown(pToken)

    ToolTip, Screenshot stored on %location%. (%mode%)
    SetTimer, ToolTipOff, -3000
    return
}

; User defined box and the dimensions
DefineBox(ByRef TopLeftX, ByRef TopLeftY, ByRef BottomRightX, ByRef BottomRightY, ByRef BoxWidth, ByRef BoxHeight) ;This function needs to return the coords of the top left corner x/y  of the square and bottom right corner x/y of the square
{
    CoordMode, ToolTip, Screen
    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    WS_EX_LAYERED:=0x00080000 ;positioned here for ease of GDI+ use
    WS_EX_NOACTIVATE:=0x08000000

    ; {
    ;generate GUI to cover the active window so you don't play with things in it while you select your box.
    Gui, 2: +LastFound -Caption +AlwaysOnTop
    Gui, 2: Color, white
    Gui, 2: Show, Hide
    WinSet, Transparent, 10
    Gui, 2: Show, NA x0 y0 w%A_ScreenWidth% h%A_ScreenHeight%
    Global OverlayFlag
    OverlayFlag := 1

    ;Wait for the left mouse button to start the GDI+
    KeyWait, LButton, D
    if (!pToken:=Gdip_Startup()) {
      msgbox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
      ExitApp
    }
    ;Generate the GDI+
    Gui, 3: +LastFound -Caption +AlwaysOnTop +E%WS_EX_LAYERED% +E%WS_EX_NOACTIVATE%
    Gui, 3: Show, NA
    Width:=A_ScreenWidth
    Height:=A_ScreenHeight
    MouseGetPos, MX, MY
    MX := MX-1
    MY := MY-1

    Loop {
        MouseGetPos, NewMX, NewMY
        NewMX := NewMX-1
        NewMY := NewMY-1
        XWidth := (NewMX-MX)
        YHeight := (NewMY-MY)

        hwnd1 := WinExist()
        hbm := CreateDIBSection(Width, Height)
        hdc := CreateCompatibleDC()
        obm := SelectObject(hdc, hbm)
        G := Gdip_GraphicsFromHDC(hdc)
        Gdip_SetSmoothingMode(G, 4)
        pPen := Gdip_CreatePen(0xfff73146, 2)

        If (XWidth < 0) {
            LeftBorder := MX + XWidth
            XWidth := -XWidth
        } else {
            LeftBorder := MX
        }

        If (YHeight < 0) {
            TopBorder := MY + YHeight
            YHeight := -YHeight
        } else {
            TopBorder := MY
        }

        Gdip_DrawRoundedRectangle(G, pPen, LeftBorder, TopBorder, XWidth, YHeight, 1)
        Gdip_DeletePen(pPen)
        UpdateLayeredWindow(hwnd1, hdc, 0, 0, Width, Height)
        SelectObject(hdc, obm)
        DeleteObject(hbm)
        DeleteDC(hdc)
        Gdip_DeleteGraphics(G)
        if (GetKeyState("LButton", "P") = 0) {
            Break
        }
    }
    Gui, 2:Destroy
    Gui, 3:Destroy

    If (OverlayFlag != "Error")
        OverlayFlag := 0

    TopLeftX:= LeftBorder
    TopLeftY:= TopBorder
    BoxWidth := XWidth
    BoxHeight := YHeight
    BottomRightX:= LeftBorder + XWidth
    BottomRightY:= TopBorder + YHeight

    ; MsgBox % TopLeftX . "," . TopLeftY . " : " . BoxWidth . "x" . BoxHeight . " : " . BottomRightX . "," . BottomRightY

    ; }
    CoordMode, ToolTip, Relative
    CoordMode, Pixel, Relative
    CoordMode, Mouse, Relative
    return
}

ReloadSub:
Reload
return

ExitSub:
ExitApp
return
