#cs

	iPadOS Cursor for Windows
	by scintilla4evr

	---

	Note: works only with standard
	Win32 controls.

#ce

#include <GUIConstants.au3>
#include <GDIPlus.au3>

#include <WinAPIEx.au3>

Local $hCursorContainer = GUICreate( _
	"iPadOSCursor", @DesktopWidth, @DesktopHeight, _
	0, 0, -1, $WS_EX_LAYERED + $WS_EX_TRANSPARENT _
)

Local $fTargetCursorDX = 0, $fTargetCursorDY = 0
Local $fTargetCursorWidth = 20, $fTargetCursorHeight = 20
Local $fTargetCursorRadius = 10
Local $fTargetCursorOpacity = 0.6

; Smooth reshaping
Local $fAnimWeight = 0.4
Local $fCursorDX = 0, $fCursorDY = 0
Local $fCursorWidth = 0, $fCursorHeight = 0
Local $fCursorRadius = 0
Local $fCursorOpacity = 0

GUISetState()

WinSetOnTop($hCursorContainer, "", True)

_GDIPlus_Startup()

Local $hBmp = _GDIPlus_BitmapCreateFromScan0(@DesktopWidth, @DesktopHeight)
Local $hGpx = _GDIPlus_ImageGetGraphicsContext($hBmp)
_GDIPlus_GraphicsSetSmoothingMode($hGpx, 2)

Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF505050)

While 1
	_DrawCursor()
	_SetUIImage()

	Switch GUIGetMsg()
		Case $GUI_EVENT_CLOSE
			ExitLoop
	EndSwitch
WEnd

_GDIPlus_BrushDispose($hBrush)
_GDIPlus_GraphicsDispose($hGpx)
_GDIPlus_BitmapDispose($hBmp)

_GDIPlus_Shutdown()

Func _ReshapeCursor()
	Local $aMousePos = MouseGetPos()
	Local $iCursorID = MouseGetCursor()

	Local $tPoint = _WinAPI_CreatePoint($aMousePos[0], $aMousePos[1])
	Local $hCursorWnd = _WinAPI_WindowFromPoint($tPoint)
	Local $sWndClass = _WinAPI_GetClassName($hCursorWnd)

	If $iCursorID = 5 Then
		; Definitely a text editing cursor
		$fTargetCursorWidth = 4
		$fTargetCursorHeight = 24
		$fTargetCursorRadius = 2
		$fTargetCursorOpacity = 0.6
		$fTargetCursorDX = 0
		$fTargetCursorDY = 0
	ElseIf $sWndClass = "Button" Or $sWndClass = "TrayButton" Then
		; Morph the cursor around a button
		Local $aBtnSize = WinGetPos($hCursorWnd)

		Local $fBtnCenterX = $aBtnSize[0] + $aBtnSize[2] / 2
		Local $fBtnCenterY = $aBtnSize[1] + $aBtnSize[3] / 2


		$fTargetCursorDX = $fBtnCenterX + 4 * ($aMousePos[0] - $fBtnCenterX) / $aBtnSize[2] - $aMousePos[0]
		$fTargetCursorDY = $aMousePos[1] = $fBtnCenterY + 4 * ($aMousePos[1] - $fBtnCenterY) / $aBtnSize[3] - $aMousePos[1]

		$fTargetCursorWidth = $aBtnSize[2] + 8
		$fTargetCursorHeight = $aBtnSize[3] + 8
		$fTargetCursorRadius = 4
		$fTargetCursorOpacity = 0.2
	Else
		; Roll back to the default
		$fTargetCursorDX = 0
		$fTargetCursorDY = 0
		$fTargetCursorWidth = 20
		$fTargetCursorHeight = 20
		$fTargetCursorRadius = 10
		$fTargetCursorOpacity = 0.6
	EndIf

	Return $aMousePos
EndFunc

Func _CreateCursorPath($aCursorPos)
	Local $hPath = _GDIPlus_PathCreate()
	Local $dX = $aCursorPos[0] - $fCursorWidth / 2 + $fCursorDX
	Local $dY = $aCursorPos[1] - $fCursorHeight / 2 + $fCursorDY

	_GDIPlus_PathAddArc( _
		$hPath, _
		$dX, $dY, _
		$fCursorRadius * 2, $fCursorRadius * 2, _
		180, 90 _
	)
	_GDIPlus_PathAddArc( _
		$hPath, _
		$dX + $fCursorWidth - $fCursorRadius * 2, $dY, _
		$fCursorRadius * 2, $fCursorRadius * 2, _
		270, 90 _
	)
	_GDIPlus_PathAddArc( _
		$hPath, _
		$dX + $fCursorWidth - $fCursorRadius * 2, $dY + $fCursorHeight - $fCursorRadius * 2, _
		$fCursorRadius * 2, $fCursorRadius * 2, _
		0, 90 _
	)
	_GDIPlus_PathAddArc( _
		$hPath, _
		$dX, $dY + $fCursorHeight - $fCursorRadius * 2, _
		$fCursorRadius * 2, $fCursorRadius * 2, _
		90, 90 _
	)

	Return $hPath
EndFunc

Func _DrawCursor()
	Local $aMousePos = _ReshapeCursor()

	_GDIPlus_GraphicsClear($hGpx, 0)

	Local $hCursorPath = _CreateCursorPath($aMousePos)
	_GDIPlus_GraphicsFillPath( _
		$hGpx, _
		$hCursorPath, $hBrush _
	)
	_GDIPlus_PathDispose($hCursorPath)

	$fCursorDX = $fCursorDX + $fAnimWeight * ($fTargetCursorDX - $fCursorDX)
	$fCursorDY = $fCursorDY + $fAnimWeight * ($fTargetCursorDY - $fCursorDY)
	$fCursorWidth = $fCursorWidth + $fAnimWeight * ($fTargetCursorWidth - $fCursorWidth)
	$fCursorHeight = $fCursorHeight + $fAnimWeight * ($fTargetCursorHeight - $fCursorHeight)
	$fCursorRadius = $fCursorRadius + $fAnimWeight * ($fTargetCursorRadius - $fCursorRadius)
	$fCursorOpacity = $fCursorOpacity + $fAnimWeight * ($fTargetCursorOpacity - $fCursorOpacity)
EndFunc

; from the AlphaBlend example
Func _SetUIImage()
	Local $hScrDC, $hMemDC, $hBitmap, $hOld, $pSize, $tSize, $pSource, $tSource, $pBlend, $tBlend

	$hScrDC = _WinAPI_GetDC(0)
	$hMemDC = _WinAPI_CreateCompatibleDC($hScrDC)
	$hBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBmp)
	$hOld = _WinAPI_SelectObject($hMemDC, $hBitmap)
	$tSize = DllStructCreate($tagSIZE)
	$pSize = DllStructGetPtr($tSize)
	DllStructSetData($tSize, "X", @DesktopWidth)
	DllStructSetData($tSize, "Y", @DesktopHeight)
	$tSource = DllStructCreate($tagPOINT)
	$pSource = DllStructGetPtr($tSource)
	$tBlend = DllStructCreate($tagBLENDFUNCTION)
	$pBlend = DllStructGetPtr($tBlend)
	DllStructSetData($tBlend, "Alpha", Floor($fCursorOpacity * 255))
	DllStructSetData($tBlend, "Format", 1)
	_WinAPI_UpdateLayeredWindow($hCursorContainer, $hScrDC, 0, $pSize, $hMemDC, $pSource, 0, $pBlend, $ULW_ALPHA)
	_WinAPI_ReleaseDC(0, $hScrDC)
	_WinAPI_SelectObject($hMemDC, $hOld)
	_WinAPI_DeleteObject($hBitmap)
	_WinAPI_DeleteDC($hMemDC)
EndFunc
