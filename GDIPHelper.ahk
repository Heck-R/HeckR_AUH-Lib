
JustTheBasics() {
	global
	
	; Start gdi+
	If !pToken := Gdip_Startup()
	{
		MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		ExitApp
	}
	OnExit, Exit
	return
	
	
	Exit:
	; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(pToken)
	ExitApp
	Return

}

GDIP_SetUp(iWidth=-1, iHeight=-1, iPosX=0, iPosY=0) {
	global

	; Flag for indicating when we are drawing (only applicable in this Helper)
	GDIP_IsDrawing := false

	; Setting up position and size
	if( iWidth<0 || iHeight<0 ){

		SysGet, monitorNum, MonitorCount
	
		leftMostPoint = 0
		topMostPoint = 0

		Loop, %monitorNum%
		{
			SysGet, monitorBorderPos, Monitor, %A_Index%
			
			if(monitorBorderPosLeft <= leftMostPoint)
				leftMostPoint=%monitorBorderPosLeft%
			
			if(monitorBorderPosTop <= topMostPoint)
				topMostPoint=%monitorBorderPosTop%
		}
		
		SysGet, fullWidth, 78
		SysGet, fullHeight, 79

		width := fullWidth
		height := fullHeight
		posX := leftMostPoint
		posY := topMostPoint

	} else{
		width := iWidth
		height := iHeight
		posX := iPosX
		posY := iPosY
	}
	
	
	JustTheBasics()
	
	; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
	Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs

	; Show the window
	Gui, 1: Show, NA

	; Get a handle to this window we have created in order to update it later
	hwnd1 := WinExist()
	return
}

GDIP_StartDraw() {
	global
	
	; Only start to draw if we are not already drawing
	if(!GDIP_IsDrawing){
		; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
		hbm := CreateDIBSection(width, height)

		; Get a device context compatible with the screen
		hdc := CreateCompatibleDC()

		; Select the bitmap into the device context
		obm := SelectObject(hdc, hbm)

		; Get a pointer to the graphics of the bitmap, for use with drawing functions
		G := Gdip_GraphicsFromHDC(hdc)
		
		; Indicate that we are drawing
		GDIP_IsDrawing := true
	}
}

GDIP_EndDraw() {
	global
	
	; Only end the draw if we are drawing
	if(GDIP_IsDrawing){
		; Update the specified window we have created (hwnd1) with a handle to our bitmap (hdc), specifying the x,y,w,h we want it positioned on our screen
		; So this will position our gui at (posX,posY) with the Width and Height specified earlier
		UpdateLayeredWindow(hwnd1, hdc, posX, posY, width, height)


		; Select the object back into the hdc
		SelectObject(hdc, obm)

		; Now the bitmap may be deleted
		DeleteObject(hbm)

		; Also the device context related to the bitmap may be deleted
		DeleteDC(hdc)

		; The graphics may now be deleted
		Gdip_DeleteGraphics(G)
		
		; Indicate that we are drawing
		GDIP_IsDrawing := false
	}
}

GDIP_Clean() {
	global
	Gdip_GraphicsClear(G)
}

GDIP_Update(){
	global
	UpdateLayeredWindow(hwnd1, hdc, posX, posY, width, height)
}
