;Thanks to tic (Tariq Porter) for his GDI+ Library
;http://www.autohotkey.com/forum/viewtopic.php?t=32238
#Singleinstance force
#NoEnv
;#include, gdip.ahk
SetBatchLines, -1
CoordMode, Mouse, screen

SetWorkingDir := a_scriptdir
clppth := "C:\"									;path to where you want to save your screen clips
scrw := a_screenwidth, scrh := A_ScreenHeight, smlw := a_screenwidth /2, smlh := A_ScreenHeight/2, winw := smlw + 100 		
mouse_blocked := false 
count := 1
SetTimer, pdt_drwng, 25

LButton::
MouseGetPos, oVarX%count%, oVarY%count%
SoundPlay, *-1:									;replace with SoundPlay, Click.wav or delete for silence...
if count = 2
	{
	SetTimer, pdt_drwng, off
	hotkey, LButton,,off
	gui, Drawing:destroy
	tooltip
	pToken 					:= Gdip_Startup()
	hdc_frame_full 				:= GetDC("Program Manager")
	hdc_buffer_full 			:= CreateCompatibleDC(hdc_frame_full)
	hbm_buffer_full 			:= CreateCompatibleBitmap(hdc_frame_full, oVarX2 - oVarX1, oVarY2 - oVarY1)
	r_full 					:= SelectObject(hdc_buffer_full, hbm_buffer_full)
	BitBlt(hdc_buffer_full, 0, 0, oVarX2 - oVarX1, oVarY2 - oVarY1, hdc_frame_full, oVarX1, oVarY1, 0x00CC0020)  
	bitmap_full 				:= Gdip_CreateBitmapFromHBITMAP(hbm_buffer_full, 0)
	DeleteDC(hdc_buffer_full)
	DeleteObject(hbm_buffer_full)
	Formattime,todaydate,a_now, yyyyMMdd_HHmmss				;timestamp
	fl2shwnopth := todaydate "clip.jpg"
	fl2shw := clppth fl2shwnopth
	Gdip_SaveBitmapToFile(bitmap_full, fl2shw, 100)          
;	Gdip_SetBitmapToClipboard(bitmap_full)					;sets the clipboard to the clip
	clipboard := fl2shw							;sets the clipboard to the file name 
	gosub, showsmall
	}
++count
return

esc:: gosub guiclose
;---------------------------------------------------------------------------------------------------------------------------------------
pdt_drwng:
gui,Drawing:submit, nohide
if (!mouse_blocked)
	{                                                    		        ; This is the first time the pdt_drwng is run.
	mouse_blocked := true                                                  	; Prepare Drawing GUI for crosshair
	gui, Drawing:+AlwaysOnTop +E0x20 -Caption +E0x80000 -Border +ToolWindow +OwnDialogs +Owner +LastFound
	gui, Drawing: Show, , Drawing											
	pToken := Gdip_Startup()
	hwnd1 := WinExist("Drawing")
	hbm := CreateDIBSection(scrw, scrh)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	g := Gdip_GraphicsFromHDC(hdc)
	pPen := Gdip_CreatePen("0xFFFF0000", 1)					       ;set the line color thickness (thin is 1)
	pPen2 := Gdip_CreatePen("0xFF0000FF", 1)				       ;set the line color thickness (thin is 1)
	}
else 
	{                                                                    	       ; Update crosshair according to mouse position
	MouseGetPos, now_x, now_y
	wdth := now_x - oVarX1
	hght := now_y - oVarY1
	wxh := wdth "x" hght
	msg1 := "First, click on the top left`r`ncorner of the area to clip.`r`nThen click on the bottom`r`nright corner. ESC to quit."
	msg2 := "Size: " wdth " X " hght "`nRatio: " wdth/hght "`nGuide angle is set @`n" scrw "x" round(scrh,0)
	msg := count = 1 ? msg1 : (count = 2 ? msg2 : )
	ToolTip, %msg%, now_x - 200, now_y + 25, 1
	Gdip_GraphicsClear(G)                                                  	       ; Delete old graphics
	if count = 1
		{
		Gdip_DrawLine(G, pPen, now_x, now_y, now_x, A_ScreenHeight)             ; Vertical Line of Crosshair
		Gdip_DrawLine(G, pPen, now_x, now_y, A_ScreenWidth, now_y)              ; Horizontal Line of Crosshair
		Gdip_DrawLine(G, pPen2, now_x+scrw, now_y+scrh, now_x, now_y)      	; diagonal
		}
	if count = 2
		{
		Gdip_DrawLine(G, pPen, now_x, oVarY1, now_x, now_y)         		; Vertical Line of Crosshair
		Gdip_DrawLine(G, pPen, oVarX1, now_y, now_x, now_y)          		; Horizontal Line of Crosshair
		Gdip_DrawLine(G, pPen2, oVarX1+scrw, oVarY1+scrh, oVarX1, oVarY1)	; diagonal
		Gdip_DrawLine(G, pPen, oVarX1, oVarY1, oVarX1, now_y)       		; Vertical Line of Crosshair
		Gdip_DrawLine(G, pPen, oVarX1, oVarY1, now_x, oVarY1)        		; Horizontal Line of Crosshair
		}
	UpdateLayeredWindow(hwnd1, hdc, 0, 0, A_ScreenWidth, A_ScreenHeight)   	        ; Draw everything
	}
return

showsmall:
gui, submit, nohide
gui, small:-caption +border
gui, small:margin,		0,0
gui, small:font, s11
gui, small:add,picture, 	x0 		y0 	w-1 		h%smlh% 		vmypic 		, %fl2shw%
gui, small:add,button, 		x%smlw%		y3 	w98 					gfolder		, folder
gui, small:add,button, 		x%smlw% 	y+3 	w98 					gsaveas		, save as
gui, small:add,button, 		x%smlw% 	y+3 	w98 					gfldelete	, delete
gui, small:Show, 					w%winw%		h%smlh%					, small
return

saveas:
FileSelectFile, newpath, S8, c:\, , *.jpg
if newpath = 
	return
if SubStr(newpath, -3) = .jpg							;in case you include the .jpg extension
	StringTrimRight, newpath, newpath, 4
FileCopy, %fl2shw%, %newpath%.jpg, 1
fl2shw := newpath ".jpg"
SplitPath, fl2shw, , clppth
clppth := clppth "\"
return

folder:
run, %clppth%
return

fldelete:
gui, small:destroy
filedelete, %fl2shw%
gosub, guiclose
return

guiclose:
Gdip_Shutdown(pToken)
exitapp