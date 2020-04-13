
GDIP_JustTheBasics() {
	global
	
	; Start gdi+
	If !GDIP_pToken := Gdip_Startup()
	{
		MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		ExitApp
	}
	OnExit, Exit
	return
	
	
	Exit:
	; gdi+ may now be shutdown on exiting the program
	Gdip_Shutdown(GDIP_pToken)
	ExitApp
	Return

}

GDIP_SetUp(width=-1, height=-1, posX=0, posY=0) {
	global

	; Flag for indicating when we are drawing (only applicable in this Helper)
	GDIP_IsDrawing := false

	; Setting up position and size
	if( width<0 || height<0 ){

		SysGet, GDIP_MonitorNum, MonitorCount
	
		GDIP_TopLeftPoint := {}
		GDIP_TopLeftPoint.x := 0
		GDIP_TopLeftPoint.y := 0

		Loop, %GDIP_MonitorNum%
		{
			SysGet, GDIP_MonitorBorderPos, Monitor, %A_Index%
			
			if(GDIP_MonitorBorderPosLeft <= GDIP_TopLeftPoint.x)
				GDIP_TopLeftPoint.x := GDIP_MonitorBorderPosLeft
			
			if(GDIP_MonitorBorderPosTop <= GDIP_TopLeftPoint.y)
				GDIP_TopLeftPoint.y := GDIP_MonitorBorderPosTop
		}
		
		SysGet, GDIP_FullWidth, 78
		SysGet, GDIP_FullHeight, 79

		GDIP_width := GDIP_FullWidth
		GDIP_height := GDIP_FullHeight
		GDIP_posX := GDIP_TopLeftPoint.x
		GDIP_posY := GDIP_TopLeftPoint.y

	} else{
		GDIP_width := width
		GDIP_height := height
		GDIP_posX := posX
		GDIP_posY := posY
	}
	
	
	GDIP_JustTheBasics()
	
	; Create a layered window (+E0x80000 : must be used for UpdateLayeredWindow to work!) that is always on top (+AlwaysOnTop), has no taskbar entry or caption
	Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs

	; Show the window
	Gui, 1: Show, NA

	; Get a handle to this window we have created in order to update it later
	GDIP_hwnd := WinExist()
	return
}

GDIP_StartDraw() {
	global
	
	; Only start to draw if we are not already drawing
	if(!GDIP_IsDrawing){
		; Create a gdi bitmap with width and height of what we are going to draw into it. This is the entire drawing area for everything
		GDIP_BitmapHandle := CreateDIBSection(GDIP_width, GDIP_height)

		; Get a device context compatible with the screen
		GDIP_DeviceContextHandle := CreateCompatibleDC()

		; Select the bitmap into the device context
		GDIP_BitmapObject := SelectObject(GDIP_DeviceContextHandle, GDIP_BitmapHandle)

		; Get a pointer to the graphics of the bitmap, for use with drawing functions
		GDIP_Graphics := Gdip_GraphicsFromHDC(GDIP_DeviceContextHandle)
		
		; Indicate that we are drawing
		GDIP_IsDrawing := true
	}
}

GDIP_EndDraw() {
	global
	
	; Only end the draw if we are drawing
	if(GDIP_IsDrawing){
		; Update the specified window we have created (GDIP_hwnd) with a handle to our bitmap (GDIP_DeviceContextHandle), specifying the x,y,w,h we want it positioned on our screen
		; So this will position our gui at (GDIP_posX,GDIP_posY) with the Width and Height specified earlier
		UpdateLayeredWindow(GDIP_hwnd, GDIP_DeviceContextHandle, GDIP_posX, GDIP_posY, GDIP_width, GDIP_height)


		; Select the object back into the GDIP_DeviceContextHandle
		SelectObject(GDIP_DeviceContextHandle, GDIP_BitmapObject)

		; Now the bitmap may be deleted
		DeleteObject(GDIP_BitmapHandle)

		; Also the device context related to the bitmap may be deleted
		DeleteDC(GDIP_DeviceContextHandle)

		; The graphics may now be deleted
		Gdip_DeleteGraphics(GDIP_Graphics)
		
		; Indicate that we are drawing
		GDIP_IsDrawing := false
	}
}

GDIP_Clean() {
	global
	Gdip_GraphicsClear(GDIP_Graphics)
}

GDIP_Update(){
	global
	UpdateLayeredWindow(GDIP_hwnd, GDIP_DeviceContextHandle, GDIP_posX, GDIP_posY, GDIP_width, GDIP_height)
}
