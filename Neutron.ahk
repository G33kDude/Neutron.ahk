;
; Neutron.ahk for AHKv2 v1.0.0
; Copyright (c) 2022 Philip Taylor (known also as GeekDude, G33kDude)
; https://github.com/G33kDude/Neutron.ahk
;
; MIT License
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.
;

#Requires AutoHotkey v2.0

class NeutronWindow {
	/** Template for template-based class initialization */
	TEMPLATE := "
( ; html
<!DOCTYPE html><html>
<head>

<meta http-equiv='X-UA-Compatible' content='IE=edge'>
<style>
	html, body {
		width: 100%; height: 100%;
		margin: 0; padding: 0;
		font-family: sans-serif;
	}

	body {
		display: flex;
		flex-direction: column;
	}

	header {
		width: 100%;
		display: flex;
		background: silver;
		font-family: Segoe UI;
		font-size: 9pt;
	}

	.title-bar {
		padding: 0.35em 0.5em;
		flex-grow: 1;
	}

	.title-btn {
		padding: 0.35em 1.0em;
		cursor: pointer;
		vertical-align: bottom;
		font-family: Webdings;
		font-size: 11pt;
	}

	body .title-btn-restore {
		display: none
	}

	body.neutron-maximized .title-btn-restore {
		display: block
	}

	body.neutron-maximized .title-btn-maximize {
		display: none
	}

	.title-btn:hover {
		background: rgba(0, 0, 0, .2);
	}

	.title-btn-close:hover {
		background: #dc3545;
	}

	.main {
		flex-grow: 1;
		padding: 0.5em;
		overflow: auto;
	}
</style>
<style>{}</style>

</head>
<body>

<header>
	<span class='title-bar' onmousedown='neutron.DragTitleBar()'>{}</span>
	<span class='title-btn' onclick='neutron.Minimize()'>0</span>
	<span class='title-btn title-btn-maximize' onclick='neutron.Maximize()'>1</span>
	<span class='title-btn title-btn-restore' onclick='neutron.Maximize()'>2</span>
	<span class='title-btn title-btn-close' onclick='neutron.Close()'>r</span>
</header>

<div class='main'>{}</div>

<script>{}</script>

</body>
</html>
)"

	;#region Constants ---------------------------------------------------------

	VERSION => "1.0.1"

	; Windows Messages
	WM_DESTROY => 0x02
	WM_SIZE => 0x05
	WM_NCCALCSIZE => 0x83
	WM_NCHITTEST => 0x84
	WM_NCLBUTTONDOWN => 0xA1
	WM_KEYDOWN => 0x100
	WM_KEYUP => 0x101
	WM_SYSKEYDOWN => 0x104
	WM_SYSKEYUP => 0x105
	WM_MOUSEMOVE => 0x200
	WM_LBUTTONDOWN => 0x201

	; Virtual-Key Codes
	VK_TAB => 0x09
	VK_SHIFT => 0x10
	VK_CONTROL => 0x11
	VK_MENU => 0x12
	VK_F5 => 0x74

	; Non-client hit test values (WM_NCHITTEST)
	HT_VALUES := [[13, 12, 14], [10, 1, 11], [16, 15, 17]]

	; Registry keys
	KEY_FBE => "HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\MAIN"
		. "\FeatureControl\FEATURE_BROWSER_EMULATION"

	; Undoucmented Accent API constants
	; https://withinrafael.com/2018/02/02/adding-acrylic-blur-to-your-windows-10-apps-redstone-4-desktop-apps/
	ACCENT_ENABLE_GRADIENT => 1
	ACCENT_ENABLE_BLURBEHIND => 3
	WCA_ACCENT_POLICY => 19

	; Other constants
	EXE_NAME := A_IsCompiled ? A_ScriptName : StrSplit(A_AhkPath, "\").Pop()

	; OS minor version
	OS_MINOR_VER := StrSplit(A_OSVersion, ".")[3]

	; Messages to listen to
	LISTENERS := [this.WM_DESTROY, this.WM_SIZE, this.WM_NCCALCSIZE,
		this.WM_KEYDOWN, this.WM_KEYUP, this.WM_SYSKEYDOWN, this.WM_SYSKEYUP,
		this.WM_LBUTTONDOWN]

	; Modifier keys as seen by neutron
	MODIFIER_BITMAP := Map(
		this.VK_SHIFT, 1 << 0,
		this.VK_CONTROL, 1 << 1,
		this.VK_MENU, 1 << 2,
	)

	;#endregion

	;#region Instance Variables ------------------------------------------------

	/**
	 * The count of pixels inset from the window edge that the sizing handles to
	 * resize the window will appear for.
	 */
	border_size := 6

	/** The width of the Neutron window (please read only) */
	w := 800

	/** The height of the Neutron window (please read only) */
	h := 600

	/** Holds the bitwise OR of all modifiers defined in MODIFIER_BITMAP (please read only) */
	modifiers := 0

	/** Shortcuts to prevent the web page from processing */
	disabled_shortcuts := Map(
		; No modifiers
		0, Map(
			this.VK_F5, true	; Refresh page
		),
		; Ctrl
		this.MODIFIER_BITMAP[this.VK_CONTROL], Map(
			GetKeyVK("F"), true,	; Ctrl+F find
			GetKeyVK("L"), true,	; Ctrl+L focus location bar
			GetKeyVK("N"), true,	; Ctrl+N open new tab
			GetKeyVK("O"), true,	; Ctrl+O open file
			GetKeyVK("P"), true,	; Ctrl+P print page
		)
	)

	/**
	 * The underlying Gui object representing the window
	 * @type {Gui}
	 */
	gui := unset

	/**
	 * Bound functions with circular references that must be freed before the
	 * class can be successfully garbage collected
	 * @type {Object}
	 */
	bound := {}

	/**
	 * The GuiControl object representing the ActiveX document control
	 * @type {Gui.ActiveX}
	 */
	wbControl := ""

	/** Handle to the Internet Explorer_Server control (please read only) */
	hIES := 0

	/** Handle to the Shell DocObject View control (please read only) */
	hSDOV := 0

	;#endregion

	;#region Properties --------------------------------------------------------

	/** The JS DOM Document object */
	doc => this.wb.Document

	/** The JS Window object */
	wnd => this.wb.Document.parentWindow

	/** The GUI hWnd (or empty string if the hWnd is not yet available) */
	hWnd => this.HasProp("gui") ? this.gui.hWnd : ""

	;#endregion

	;#region Meta --------------------------------------------------------------

	__New(html := "", css := "", js := "", title := "Neutron") {
		; Create necessary circular references
		this.bound._OnMessage := this._OnMessage.Bind(this)

		; Bind message handlers
		for i, message in this.LISTENERS
			OnMessage(message, this.bound._OnMessage)

		; Create and save the GUI
		this.gui := Gui("+Resize -DPIScale")

		; Enable shadow
		NumPut("Int", 1, margins := Buffer(16, 0))
		DllCall("Dwmapi\DwmExtendFrameIntoClientArea",
			"Ptr", this.hWnd,	; HWND hWnd
			"Ptr", margins,	; MARGINS *pMarInset
		)

		; When manually resizing a window, the contents of the window often "lag
		; behind" the new window boundaries. Until they catch up, Windows will
		; render the border and default window color to fill that area. On most
		; windows this will cause no issue, but for borderless windows this can
		; cause rendering artifacts such as thin borders or unwanted colors to
		; appear in that area until the rest of the window catches up.
		;
		; When creating a dark-themed application, these artifacts can cause
		; jarringly visible bright areas. This can be mitigated some by changing
		; the window settings to cause dark/black artifacts, but it's not a
		; generalizable approach, so if I were to do that here it could cause
		; issues with light-themed apps.
		;
		; Some borderless window libraries, such as rossy's C implementation
		; (https://github.com/rossy/borderless-window) hide these artifacts by
		; playing with the window transparency settings which make them go away
		; but also makes it impossible to show certain colors (in rossy's case,
		; Fuchsia/FF00FF).
		;
		; Luckly, there's an undocumented Windows API function in user32.dll
		; called SetWindowCompositionAttribute, which allows you to change the
		; window accenting policies. This tells the DWM compositor how to fill
		; in areas that aren't covered by controls. By enabling the "blurbehind"
		; accent policy, Windows will render a blurred version of the screen
		; contents behind your window in that area, which will not be visually
		; jarring regardless of the colors of your application or those behind
		; it.
		;
		; Because this API is undocumented (and unavailable in Windows versions
		; below 10) it's not a one-size-fits-all solution, and could break with
		; future system updates. Hopefully a better soultion for the problem
		; this hack addresses can be found for future releases of this library.
		;
		; https://withinrafael.com/2018/02/02/adding-acrylic-blur-to-your-windows-10-apps-redstone-4-desktop-apps/
		; https://github.com/melak47/BorderlessWindow/issues/13#issuecomment-309154142
		; http://undoc.airesoft.co.uk/user32.dll/SetWindowCompositionAttribute.php
		; https://gist.github.com/riverar/fd6525579d6bbafc6e48
		; https://vhanla.codigobit.info/2015/07/enable-windows-10-aero-glass-aka-blur.html
		this.gui.BackColor := 0

		; Use ACCENT_ENABLE_GRADIENT on Windows 11 to fix window dragging issues
		accent := Buffer(16, 0)
		if this.OS_MINOR_VER >= 22000
			NumPut("Int", this.ACCENT_ENABLE_GRADIENT, accent)
		else
			NumPut("Int", this.ACCENT_ENABLE_BLURBEHIND, accent)

		NumPut(
			"Ptr", this.WCA_ACCENT_POLICY,
			"Ptr", accent.Ptr,
			"Int", 16,
			wcad := Buffer(A_PtrSize + A_PtrSize + 4, 0)
		)
		DllCall("SetWindowCompositionAttribute",
			"Ptr", this.hWnd,	; HWND hwnd
			"Ptr", wcad,	; WINCOMPATTRDATA* pAttrData
		)

		; Creating an ActiveX control with a valid URL instantiates a
		; WebBrowser, saving its object to the associated variable. The "about"
		; URL scheme allows us to start the control on either a blank page, or a
		; page with some HTML content pre-loaded by passing HTML after the
		; colon: "about:<!DOCTYPE html><body>...</body>"
		;
		; Read more about the WebBrowser control here:
		; http://msdn.microsoft.com/en-us/library/aa752085

		; For backwards compatibility reasons, the WebBrowser control defaults
		; to IE7 emulation mode. The standard method of mitigating this is to
		; include a compatibility meta tag in the HTML, but this requires
		; tampering to the HTML and does not solve all compatibility issues.
		; By tweaking the registry before and after creation of the control we
		; can opt-out of the browser emulation feature altogether with minimal
		; impact on the rest of the system.
		;
		; Read more about browser compatibility modes here:
		; https://docs.microsoft.com/en-us/archive/blogs/patricka/controlling-webbrowser-control-compatibility

		fbe := RegRead(this.KEY_FBE, this.EXE_NAME, "")
		RegWrite(0, "REG_DWORD", this.KEY_FBE, this.EXE_NAME)
		this.wbControl := this.gui.AddActiveX("x0 y0 w800 h600", "about:blank")
		this.wb := this.wbControl.Value
		if (fbe = "")
			RegDelete(this.KEY_FBE, this.EXE_NAME)
		else
			RegWrite(fbe, "REG_DWORD", this.KEY_FBE, this.EXE_NAME)

		; Connect the web browser's event stream to a new event handler object
		ComObjConnect(this.wb, NeutronWindow._WBEvents(this))

		; Compute the HTML template if necessary
		if !(html ~= "i)^<!DOCTYPE")
			html := Format(this.TEMPLATE, css, title, html, js)

		; Write the given content to the page
		this.doc.write(html)
		this.doc.close()

		; Inject the AHK objects into the JS scope
		this.wnd.neutron := this
		this.wnd.ahk := NeutronWindow._Dispatch(this)

		; Wait for the page to finish loading
		while this.wb.readyState < 4
			Sleep 50

		; Subclass the rendered Internet Explorer_Server control to intercept
		; its events, including WM_NCHITTEST and WM_NCLBUTTONDOWN.
		; Read more here: https://forum.juce.com/t/_/27937
		; And in the AutoHotkey documentation for RegisterCallback (Example 2)

		dhw := DetectHiddenWindows(true)
		this.hIES := ControlGetHwnd("Internet Explorer_Server1", "ahk_id " this.hWnd)
		this.hSDOV := ControlGetHwnd("Shell DocObject View1", "ahk_id " this.hWnd)
		DetectHiddenWindows(dhw)

		this.pWndProc := CallbackCreate(this._WindowProc.Bind(this), "", 4)
		this.pWndProcOld := DllCall("SetWindowLong" (A_PtrSize == 8 ? "Ptr" : "")
			, "Ptr", this.hIES	; HWND     hWnd
			, "Int", -4	; int      nIndex (GWLP_WNDPROC)
			, "Ptr", this.pWndProc	; LONG_PTR dwNewLong
			, "Ptr"	; LONG_PTR
		)

		; Stop the WebBrowser control from consuming file drag and drop events
		this.wb.RegisterAsDropTarget := False
		DllCall("ole32\RevokeDragDrop", "Ptr", this.hIES)
	}

	; Show an alert for debugging purposes when the class gets garbage collected
	; __Delete()
	; {
	; 	MsgBox, __Delete
	; }

	;#endregion

	;#region Event Handlers ----------------------------------------------------

	_OnMessage(wParam, lParam, msg, hWnd) {
		if (hWnd == this.hWnd) {
			; Handle messages for the main window

			if (msg == this.WM_NCCALCSIZE) {
				; Size the client area to fill the entire window.
				; See this project for more information:
				; https://github.com/rossy/borderless-window

				; Fill client area when not maximized
				if !DllCall("IsZoomed", "UPtr", hWnd)
					return 0
				; else crop borders to prevent screen overhang

				; Query for the window's border size
				NumPut("UInt", 60, windowinfo := Buffer(60, 0))
				DllCall("GetWindowInfo", "Ptr", hWnd, "Ptr", windowinfo)
				cxWindowBorders := NumGet(windowinfo, 48, "Int")
				cyWindowBorders := NumGet(windowinfo, 52, "Int")

				; Inset the client rect by the border size
				NumPut(
					"Int", NumGet(lParam, 0, "Int") + cxWindowBorders,
					"Int", NumGet(lParam, 4, "Int") + cyWindowBorders,
					"Int", NumGet(lParam, 8, "Int") - cxWindowBorders,
					"Int", NumGet(lParam, 12, "Int") - cyWindowBorders,
					lParam
				)

				return 0
			} else if (msg == this.WM_SIZE) {
				; Extract size from LOWORD and HIWORD (preserving sign)
				this.w := w := lParam << 48 >> 48
				this.h := h := lParam << 32 >> 48

				DllCall("MoveWindow",
					"UPtr", this.wbControl.hWnd,	; HWND hWnd
					"Int", 0,	; int  X
					"Int", 0,	; int  Y
					"Int", w,	; int  nWidth
					"Int", h,	; int  nHeight
					"UInt", 0	; BOOL bRepaint
				)

				return 0
			} else if (msg == this.WM_DESTROY) {
				; Clean up all our circular references so that the object may be
				; garbage collected.

				for i, message in this.LISTENERS
					OnMessage(message, this.bound._OnMessage, 0)
				ComObjConnect(this.wb)
				this.bound := []
			}
		} else if (hWnd == this.hIES || hWnd == this.hSDOV) {
			; Handle messages for the rendered Internet Explorer_Server

			pressed := (msg == this.WM_KEYDOWN || msg == this.WM_SYSKEYDOWN)
			released := (msg == this.WM_KEYUP || msg == this.WM_SYSKEYUP)

			if (pressed || released) {
				; Track modifier states
				if (bit := this.MODIFIER_BITMAP.Get(wParam, ""))
					this.modifiers := (this.modifiers & ~bit) | (pressed * bit)

				; Block disabled key combinations
				if (this.disabled_shortcuts.Get(this.modifiers, Map()).Get(wParam, false))
					return 0

				; When you press tab with the last tabbable item in the
				; document already selected, focus will be taken from the IES
				; control and moved to the SDOV control. The accelerator code
				; from the AutoHotkey installer uses a conditional loop in an
				; attempt to work around this behavior, but as implemented it
				; did not work correctly on my system. Instead, listen for the
				; tab up event on the SDOV and swap it for a tab down before
				; translating it. This should prevent the user from tabbing to
				; the SDOV in most cases, though there may still be some way to
				; tab to it that I am not aware of. A more elegant solution may
				; be to subclass the SDOV like was done for the IES, then
				; forward the WM_SETFOCUS message back to the IES control.
				; However, given the relative complexity of subclassing and the
				; fact that this message substution approach appears to work
				; just as well, we will use the message substitution. Consider
				; implementing the other approach if it turns out that the
				; undesirable behavior continues to manifest under some
				; circumstances.
				msg := hWnd == this.hSDOV ? this.WM_KEYDOWN : msg

				; Add OwnDialogs for threadless callbacks which normally
				; interrupt this process
				this.gui.Opt("+OwnDialogs")

				DllCall("GetCursorPos", "Ptr", cursorPoint := Buffer(8, 0))
				NumPut(
					"Ptr", hWnd,
					"Ptr", msg,
					"Ptr", wParam,
					"Ptr", lParam,
					"UInt", A_EventInfo,
					"Int", NumGet(cursorPoint, 0, "Int"),
					"Int", NumGet(cursorPoint, 4, "Int"),
					kMsg := Buffer(48, 0)
				)
				pipa := ComObjQuery(this.wb, "{00000117-0000-0000-C000-000000000046}")
				result := ComCall(5, pipa, "Ptr", kMsg)

				; S_OK: the message was translated to an accelerator.
				if (result == 0)
					return 0
				return
			}
		}
	}

	_WindowProc(hWnd, msg, wParam, lParam) {
		Critical

		if (msg == this.WM_NCHITTEST) {
			; Check to see if the cursor is near the window border, which
			; should be treated as the "non-client" drag-to-resize area.
			; https://autohotkey.com/board/topic/23969-/#entry155480

			; Extract coordinates from LOWORD and HIWORD (preserving sign)
			x := lParam << 48 >> 48, y := lParam << 32 >> 48

			; Get the window position for comparison
			WinGetPos(&wX, &wY, &wW, &wH, "ahk_id " this.Hwnd)

			; Calculate positions in the lookup tables
			row := (x < wX + this.BORDER_SIZE) ? 1 : (x >= wX + wW - this.BORDER_SIZE) ? 3 : 2
			col := (y < wY + this.BORDER_SIZE) ? 1 : (y >= wY + wH - this.BORDER_SIZE) ? 3 : 2

			return this.HT_VALUES[col][row]
		} else if (msg == this.WM_NCLBUTTONDOWN) {
			; Hoist nonclient clicks to main window
			return DllCall("SendMessage",
				"Ptr", this.hWnd,
				"UInt", msg,
				"UPtr", wParam,
				"Ptr", lParam,
				"Ptr"
			)
		}

		; Otherwise (since above didn't return), pass all unhandled events to
		; the original WindowProc
		Critical false
		return DllCall("CallWindowProc",
			"Ptr", this.pWndProcOld,	; WNDPROC lpPrevWndFunc
			"Ptr", hWnd,	; HWND    hWnd
			"UInt", msg,	; UINT    Msg
			"UPtr", wParam,	; WPARAM  wParam
			"Ptr", lParam,	; LPARAM  lParam
			"Ptr"	; LRESULT
		)
	}

	;#endregion

	;#region Instance Methods --------------------------------------------------

	/**
	 * Triggers window dragging. Call this on mouse click down. Best used as
	 * your title bar's onmousedown attribute.
	 * 
	 * ```html
	 * <span onmousedown="neutron.DragTitleBar()">
	 * ```
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 */
	DragTitleBar() {
		PostMessage(this.WM_NCLBUTTONDOWN, 2, 0, , "ahk_id " this.Hwnd)
		return this
	}

	/**
	 * Minimizes the Neutron window. Best used in your title bar's minimize
	 * button's onclick attribute.
	 * 
	 * ```html
	 * <span onclick='neutron.Minimize()'>
	 * ```
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 */
	Minimize() {
		this.gui.Minimize()
		return this
	}

	/**
	 * Maximize the Neutron window. Best used in your title bar's maximize
	 * button's onclick attribute.
	 * 
	 * ```html
	 * <span onclick='neutron.Maximize()'>
	 * ```
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 */
	Maximize() {
		if DllCall("IsZoomed", "UPtr", this.hWnd) {
			this.gui.Restore()
			this.qs("body").classList.remove("neutron-maximized")
		} else {
			this.gui.Maximize()
			this.qs("body").classList.add("neutron-maximized")
		}
		return this
	}

	/**
	 * Closes the Neutron window. Best used in your title bar's close
	 * button's onclick attribute.
	 * 
	 * ```html
	 * <span onclick='neutron.Close()'>
	 * ```
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 */
	Close() {
		WinClose("ahk_id " this.hWnd)
		return this
	}

	/**
	 * Hides the Nuetron window.
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 */
	Hide() {
		this.gui.Hide()
		return this
	}

	/**
	 * Destroys the Neutron window. Do this when you would no longer want to
	 * re-show the window, as it will free the memory taken up by the GUI and
	 * ActiveX control. This method is best used either as your title bar's
	 * close button's onclick attribute, or in a custom window close routine.
	 * 
	 * ```html
	 * <span onclick='neutron.Close()'>
	 * ```
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 */
	Destroy() {
		this.gui.Destroy()
		return this
	}

	/**
	 * Shows a hidden Neutron window
	 * 
	 * @param options Options to be passed to `Gui.Show(options)`
	 * @param title   A title for the base window (shows in task bar, alt tab)
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 */
	Show(options := "", title := "") {
		w := RegExMatch(options, "w\s*\K\d+", &match) ? match[] : this.w
		h := RegExMatch(options, "h\s*\K\d+", &match) ? match[] : this.h

		; AutoHotkey sizes the window incorrectly, trying to account for borders
		; that aren't actually there. Call the function AHK uses to offset and
		; apply the change in reverse to get the actual wanted size.
		rect := Buffer(16, 0)
		DllCall("AdjustWindowRectEx",
			"Ptr", rect,	; LPRECT lpRect
			"UInt", 0x80CE0000,	; DWORD  dwStyle
			"UInt", 0,	; BOOL   bMenu
			"UInt", 0,	; DWORD  dwExStyle
			"UInt"	; BOOL
		)
		w += NumGet(rect, 0, "Int") - NumGet(rect, 8, "Int")
		h += NumGet(rect, 4, "Int") - NumGet(rect, 12, "Int")

		this.gui.Title := title
		this.gui.Show(options " w" w " h" h)
		return this
	}

	/**
	 * Loads an HTML file by name (not path).
	 * 
	 * When running the script uncompiled, looks for the file in the local
	 * directory. When running the script compiled, looks for the file in the
	 * EXE's RCDATA. Files included in your compiled EXE by FileInstall are
	 * stored in RCDATA whether they get extracted or not. An easy way to get
	 * your Neutron resources into a compiled script, then, is to put
	 * FileInstall commands for them at the start or end of the AutoExecute
	 * section, wrapped in `if False {}`. For example:
	 * 
	 * ```ahk2
	 * ; AutoExecute Section
	 * neutron := NeutronWindow().Load("index.html").Show()
	 * 
	 * if False {
	 *     FileInstall "index.html", "*"
	 *     FileInstall "index.css", "*"
	 * }
	 * return
	 * ```
	 * 
	 * @param fileName The name of the HTML file to load into the Neutron window.
	 *                 Make sure to give just the file name, not the full path.
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 */
	Load(fileName) {
		; Complete the path based on compiled state
		if A_IsCompiled {
			url := "res://" A_ScriptFullPath "/10/" fileName
		} else
			url := A_WorkingDir "/" fileName

		; Navigate to the calculated file URL
		this.wb.Navigate(url)

		; Wait for the page to finish loading
		while this.wb.readyState < 3
			Sleep 50

		; Inject the AHK objects into the JS scope
		this.wnd.neutron := this
		this.wnd.ahk := NeutronWindow._Dispatch(this)

		; Wait for the page to finish loading
		while this.wb.readyState < 4
			Sleep 50

		return this
	}

	/**
	 * Registers a function or method to be called when the given event is
	 * raised by Neutron underlying GUI window.
	 * 
	 * The function will be called with its normal parameter set as defined by
	 * AutoHotkey, but with the first parameter changed from the `Gui` object to
	 * the `NeutronWindow` object.
	 * 
	 * @param {String} eventName The name of the event
	 * @param          callback  The callback to be run
	 * @param {Int}    addRemove (Optional) Specifies call order or removes the
	 *                           callback. See `Gui.OnEvent()` docs for more
	 *                           details
	 * 
	 * @return {NeutronWindow} The instance, for chaining
	 * 
	 * @example <caption>Exit AHK on Neutron close</caption>
	 * neutron.OnEvent("Close", (neutron) => ExitApp())
	 */
	OnEvent(eventName, callback, addRemove := unset) {
		this.gui.OnEvent(eventName, (p*) => (p[1] := this, callback(p*)), addRemove?)
		return this
	}

	/**
	 * Passthrough to sets one or more options for the underlying GUI window
	 * @return {NeutronWindow} The instance, for chaining
	 */
	Opt(options) {
		this.gui.Opt(options)
		return this
	}

	/**
	 * Shorthand method for document.querySelector
	 * @param selector The query selector
	 * @return the result of the query
	 */
	qs(selector) {
		return this.doc.querySelector(selector)
	}

	/**
	 * Shorthand method for document.querySelectorAll
	 * @param selector The query selector
	 * @return the result of the query
	 */
	qsa(selector) {
		return this.doc.querySelectorAll(selector)
	}

	;#endregion

	;#region Static Methods ----------------------------------------------------

	/**
	 * Given an HTML Form Element, construct a FormData object
	 * 
	 * Returns: A FormData object
	 * 
	 * Example:
	 * 
	 * neutron := NeutronWindow("<form>"
	 * . "<input type='text' name='field1' value='One'>"
	 * . "<input type='text' name='field2' value='Two'>"
	 * . "<input type='text' name='field3' value='Three'>"
	 * . "</form>").Show()
	 * formElement := neutron.doc.querySelector("form") ; Grab 1st form on page
	 * formData := NeutronWindow.GetFormData(formElement) ; Get form data
	 * MsgBox formData.field2 ; Pull a single field
	 * for name, element in formData ; Iterate all fields
	 *     MsgBox name ": " element
	 * 
	 * @param        formElement The HTML Form Element
	 * @param {Bool} useIdAsName (Optional, default `True`) When a field's name
	 *                           is blank, use it's ID instead.
	 * 
	 * @return {NeutronWindow.FormData}
	 */
	static GetFormData(formElement, useIdAsName := True) {
		formData := this.FormData()

		for i, field in this.Each(formElement.elements) {
			; Discover the field's name
			name := ""
			try	; fieldset elements error when reading the name field
				name := field.name
			if (name == "" && useIdAsName)
				name := field.id

			; Filter against fields which should be omitted
			if (name == "" || field.disabled
				|| field.type ~= "^file|reset|submit|button$")
				continue

			; Handle select-multiple variants
			if (field.type == "select-multiple") {
				for j, option in this.Each(field.options)
					if (option.selected)
						formData.add(name, option.value)
				continue
			}

			; Filter against unchecked checkboxes and radios
			if (field.type ~= "^checkbox|radio$" && !field.checked)
				continue

			; Return the field values
			formData.add(name, field.value)
		}

		return formData
	}

	/**
	 * Makes text safe to be embedded in HTML
	 * 
	 * Reference https://stackoverflow.com/a/6234804
	 * 
	 * @param {String} unsafe An HTML-unsafe string
	 * 
	 * @return {String} An HTML safe string
	 */
	static EscapeHTML(unsafe) {
		unsafe := StrReplace(unsafe, "&", "&amp;")
		unsafe := StrReplace(unsafe, "<", "&lt;")
		unsafe := StrReplace(unsafe, ">", "&gt;")
		unsafe := StrReplace(unsafe, '"', "&quot;")
		unsafe := StrReplace(unsafe, "'", "&#039;")
		return unsafe
	}

	/**
	 * Wrapper for Format that applies EscapeHTML to each value before passing
	 * them on. Useful for dynamic HTML generation.
	 * 
	 * @param {String} formatStr The format string
	 * @param values...          The placeholder values
	 * 
	 * @return {String} The formatted version of the specified string
	 */
	static FormatHTML(formatStr, values*) {
		for i, value in values
			values[i] := NeutronWindow.EscapeHTML(value)
		return Format(formatStr, values*)
	}

	;#endregion

	;#region Nested Classes ----------------------------------------------------

	/**
	 * Creates an enumerable object that will enumerate an HTML Collection
	 * or other JavaScript array.
	 * 
	 * @param collection The JavaScript array/collection to be enumerated
	 * 
	 * @return {NeutronWindow.Each}
	 * 
	 * @example <caption>Walk through the direct children of body</caption>
	 * neutron := NeutronWindow("<body><p>A</p><p>B</p><p>C</p></body>")
	 * neutron.Show()
	 * for i, element in NeutronWindow.Each(neutron.body.children)
	 *     MsgBox i ": " element.innerText
	 */
	class Each {
		__New(collection) {
			this.collection := collection
		}

		__Enum(numberOfVars) {
			index := 0
			return (&a, &b := unset) => (
				(index > this.collection.length) ? False : (True,
					a := index,
					b := this.collection.item(index++)
				)
			)
		}
	}

	/**
	 * A collection similar to an OrderedDict designed for holding form data.
	 * This collection allows duplicate keys and enumerates key value pairs in
	 * the order they were added.
	 */
	class FormData {
		names := []
		values := []

		/**
		 * Add a field to the FormData structure.
		 * 
		 * @param {String} name The form field name associated with the value
		 * @param          value The value of the form field
		 */
		Add(name, value) {
			this.names.Push(name)
			this.values.Push(value)
		}

		/**
		 * Get an array of all values associated with a name.
		 * 
		 * @param {String} name The form field name associated with the values
		 * 
		 * @return {Array} The values associated with the name
		 * 
		 * @example <caption>Get all form values with key "foods"</caption>
		 * fd := NeutronWindow.FormData()
		 * fd.Add("foods", "hamburgers")
		 * fd.Add("foods", "hotdogs")
		 * fd.Add("foods", "pizza")
		 * fd.Add("colors", "red")
		 * fd.Add("colors", "green")
		 * fd.Add("colors", "blue")
		 * for i, food in fd.All("foods")
		 *     out .= i ": " food "`n"
		 * MsgBox out
		 */
		All(name) {
			values := []
			for i, v in this.names
				if (v == name)
					values.Push(this.values[i])
			return values
		}

		/**
		 * Meta-function to allow direct access of field values using dot
		 * notation.
		 * 
		 * @example <caption>Get first value for key foods</caption>
		 * fd := NeutronWindow.FormData()
		 * fd.Add("foods", "hamburgers")
		 * fd.Add("foods", "hotdogs")
		 * MsgBox fd.foods ; hamburgers
		 */
		__Get(name, params) {
			return this[name]
		}

		/**
		 * Meta-property to allow direct access of field values using bracket
		 * notation. Can retrieve the nth item associated with a given name
		 * by passing more than one value.
		 * 
		 * @example <caption>Get first and second value for key foods</caption>
		 * fd := Neutron.FormData()
		 * fd.Add("foods", "hamburgers")
		 * fd.Add("foods", "hotdogs")
		 * MsgBox fd["foods"] ; hamburgers
		 * MsgBox fd["foods", 2] ; hotdogs
		 */
		__Item[name, n := 1] {
			get {
				for i, v in this.names
					if (v == name && !--n)
						return this.values[i]
			}
		}

		/**
		 * Allow iteration in the order fields were added, instead of a normal
		 * object's alphanumeric order of iteration.
		 * 
		 * @example <caption>Iterate through all form values in order</caption>
		 * fd := NeutronWindow.FormData()
		 * fd.Add("z", "3")
		 * fd.Add("y", "2")
		 * fd.Add("x", "1")
		 * for name, field in fd
		 *     out .= name ": " field ","
		 * MsgBox out ; z: 3, y: 2, x: 1
		 */
		__Enum(NumberOfVars) {
			i := 0
			return (&name, &value := unset) => (
				(++i > this.names.Length) ? (false) : (true,
					name := this.names[i],
					value := this.values[i]
				)
			)
		}
	}

	/**
	 * Proxies method calls to AHK function calls
	 * 
	 * These functions get called from JavaScript typically, which consumes any
	 * thrown errors and displays a really unhelpful dialog. For the best
	 * experience, any thrown errors are additionally re-thrown in a separate
	 * thread so the native dialog can be displayed.
	 * 
	 * @param {NeutronWindow} parent The parent {NeutronWindow} instance
	 */
	class _Dispatch {
		__New(parent) {
			this.parent := parent
		}

		__Call(name, params := []) {
			; Make sure the given name is a function
			if !((fn := %name% ?? false) && fn is Func)
				throw Error("Unknown function: " name)

			; Add a first parameter of the neutron instance
			params.InsertAt(1, this.parent)

			; Make sure enough parameters were given
			if (params.Length < fn.MinParams)
				throw Error("Too few parameters given to " fn.Name ": " params.Length)

			; Make sure too many parameters weren't given
			if (params.Length > fn.MaxParams && !fn.IsVariadic)
				throw Error("Too many parameters given to " fn.Name ": " params.Length)

			; Call the function
			try {
				return fn(params*)
			} catch as err {
				thrower() {
					throw err
				}
				SetTimer(thrower, -1)
				throw err
			}
		}
	}

	/**
	 * Handles Web Browser events
	 * https://docs.microsoft.com/en-us/previous-versions/windows/internet-explorer/ie-developer/platform-apis/aa768283%28v%3dvs.85%29
	 * 
	 * @param {NeutronWindow} parent The parent {NeutronWindow} instance
	 */
	class _WBEvents {
		__New(parent) {
			this.parent := parent
		}

		DocumentComplete(wb, p*) {
			; Inject the AHK objects into the JS scope
			wb.document.parentWindow.neutron := this.parent
			wb.document.parentWindow.ahk := NeutronWindow._Dispatch(this.parent)
		}
	}

	;#endregion
}
