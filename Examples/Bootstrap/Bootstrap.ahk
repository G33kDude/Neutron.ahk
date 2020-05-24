#NoEnv
SetBatchLines, -1

; Compile Me!

; This Neutron script contains many separate web files and dependencies, but can
; still be compiled into a portable EXE that won't have to extract anything to
; work.

; Include the Neutron library
#Include ../../Neutron.ahk

; Create a new NeutronWindow and navigate to our HTML page
neutron := new NeutronWindow()
neutron.Load("Bootstrap.html")

; Instead of using neutron's built in Close method, make the window close action
; call our Func_ExitApp.
neutron.Close := Func("Func_ExitApp")

; Show the Neutron window
neutron.Show()
return

; FileInstall all your dependencies, but put the FileInstall lines somewhere
; they won't ever be reached. Right below your AutoExecute section is a great
; location!
FileInstall, Bootstrap.html, Bootstrap.html
FileInstall, bootstrap.min.css, bootstrap.min.css
FileInstall, bootstrap.min.js, bootstrap.min.js
FileInstall, jquery.min.js, jquery.min.js

Func_ExitApp()
{
	ExitApp
}

Button(neutron, event)
{
	MsgBox, % "You clicked " event.target.innerText
}

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
	out .= "Email: " formData.inputEmail "`n"
	out .= "Password: " formData.inputPassword "`n"
	if formData.gridCheck
		out .= "You checked the box!"
	else
		out .= "You didn't check the box."
	
	; Show the output
	MsgBox, %out%
}
