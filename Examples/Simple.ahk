#NoEnv
SetBatchLines, -1

; Include the Neutron library
#Include ../Neutron.ahk

; Read in the HTML and load it into a Neutron window
FileRead, html, Simple.html
neutron := new NeutronWindow(html)

; Instead of using neutron's built in Close method, make the window close action
; call our Func_ExitApp.
neutron.Close := Func("Func_ExitApp")
return

Func_ExitApp()
{
	ExitApp
}


; --- Trigger AHK by page events ---

Example1_Button(neutron, event)
{
	; event.target will contain the HTML Element that fired the event.
	; Show a message box with its inner text.
	MsgBox, % "You clicked: " event.target.innerText
}

Example1_MouseMove(neutron, event)
{
	; Some events, like MouseMove, have custom attributes that can be read.
	; offsetX and offsetY contain the mouse position relative to the event that
	; fired the event.
	event.target.innerText := Format("({:i}, {:i})", event.offsetX, event.offsetY)
}

Example1_MouseLeave(neutron, event)
{
	; Reset the text of the MouseMove example when the mouse is no longer over
	; it.
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
	; Use the JavaScript function document.querySelectorAll to find elements
	; based on a CSS selector.
	keyDivs := neutron.doc.querySelectorAll(".keys > div")

	; Use Neutron's .Each() method to iterate through the HTMLCollection in a
	; for loop.
	for i, div in neutron.Each(keyDivs)
	{
		; Check if the div's innerText matches the key that was pressed
		if (div.innerText == keyName)
		{
			; Update the div's className property to change its style on the fly
			div.className := className
		}
	}
}

#if


; --- Pass form data to AHK ---

Submit(neutron, event)
{
	; Some events have a default action that needs to be prevented. A form will
	; redirect the page by default, but we want to handle the form data ourself.
	event.preventDefault()

	; Use Neutron's GetFormData method to process the form data into a form that
	; is easily accessed. Fields that have a 'name' attribute will be keyed by
	; that, or if they don't they'll be keyed by their 'id' attribute.
	formData := neutron.GetFormData(event.target)
	
	; You can access all of the form fields by iterating over the FormData
	; object. It will go through them in the order they appear in the HTML.
	out := "Access all fields by iterating:`n"
	for name, value in formData
		out .= name ": " value "`n"
	out .= "`n"
	
	; You can also get field values by name directly. Use object dot notation
	; with the field name/id.
	out .= "Or access individual fields directly:`n"
	out .= "Hello " formData.firstName " " formData.lastName "!`n"
	if formData.remember
		out .= ""
	else
		out .= "You forgot to check the 'Remember Me' box :("
	
	; Show the output
	MsgBox, %out%
}

Submit2(neutron, event)
{
	event.preventDefault()
	formData := neutron.GetFormData(event.target)

	; When you iterate over a FormData object with multi-selected checkboxes or
	; select elements, it will act like an object with duplicate keys. The same
	; name will appear multiple times, once per selected item.
	out := "Access all fields by iterating:`n"
	for name, value in formData
		out .= name ": " value "`n"
	out .= "`n"

	; Iterating over the entire set of form fields is useful in some situations,
	; but often you'll want to just get all the options selected for a single
	; multi-select form field. Use the FormData's .All() method to get all the
	; values associated with one field name as a standard array.
	out .= "Or individually:`n"
	out .= "Foods: [ "
	for i, food in formData.All("food")
		out .= food " "
	out .= "]`n"
	out .= "Languages: [ "
	for i, language in formData.All("favLangs")
		out .= language " "
	out .= "]`n"

	; The FormData object will combine a group of Radios with the same name
	; under a single entry. Grab a Radio group's value using dot or bracket
	; notation.
	out .= "Contact: " formData.contact "`n"
	
	; Show the output
	MsgBox, %out%
}
