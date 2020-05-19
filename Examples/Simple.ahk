#NoEnv
SetBatchLines, -1

FileRead, html, Simple.html
neutron := new NeutronWindow(html)
neutron.Close := "Func_ExitApp"
return


; --- Trigger AHK by page events ---

Example1_Button(neutron, event)
{
	MsgBox, % "You clicked: " event.target.innerText
}

Example1_MouseMove(neutron, event)
{
	event.target.innerText := Format("({:i}, {:i})", event.Offsetx, event.Offsety)
}

Example1_MouseLeave(neutron, event)
{
	event.target.innerText := "Mouse over this area!"
}


; --- Update page by Hotkey ---

; Limit this hotkey to only fire while our Neutron window is the active window.
#if WinActive("ahk_id" neutron.hWnd)

~1::UpdateKeyExample(neutron, "1", "active")
~2::UpdateKeyExample(neutron, "2", "active")
~3::UpdateKeyExample(neutron, "3", "active")
~4::UpdateKeyExample(neutron, "4", "active")
~1 Up::UpdateKeyExample(neutron, "1", "")
~2 Up::UpdateKeyExample(neutron, "2", "")
~3 Up::UpdateKeyExample(neutron, "3", "")
~4 Up::UpdateKeyExample(neutron, "4", "")

UpdateKeyExample(neutron, keyName, className) {
	; Iterate through items found by the CSS selector, updating the CSS class of
	; the elements with the right inner text.
	for i, element in neutron.Each(neutron.doc.querySelectorAll(".keys > div"))
		if (element.innerText == keyName)
			element.className := className
}

#if


; --- Pass form data to AHK ---

Func_ExitApp()
{
	ExitApp
}

Submit(neutron, event)
{
	event.preventDefault()
	for i, input in neutron.Each(event.target.querySelectorAll("input, select"))
		out .= input.id ": " input.value "`n"
	MsgBox, %out%
}


; --- Neutron Code ---

#Include ../Neutron.ahk