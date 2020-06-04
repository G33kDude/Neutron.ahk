/*
	Compile Me!
	
	This example is designed to show how you can use third party frameworks like
	Bootstrap to build advanced user interfaces, while still keeping all the
	code local. This script can be compiled and still function fine without the
	need to extract any files to a temporary directory.
	
	As this example is more advanced, it assumes a stronger familiarity with the
	technology and may gloss over some parts more than other examples. If you're
	just getting started it may be helpful to work with some of the other
	example scripts first.
*/

#NoEnv
SetBatchLines, -1

; Include the Neutron library
#Include ../../Neutron.ahk

; Create a new NeutronWindow and navigate to our HTML page
neutron := new NeutronWindow()
neutron.Load("Bootstrap.html")

; Use the Gui method to set a custom label prefix for GUI events. This code is
; equivalent to the line `Gui, name:+LabelNeutron` for a normal GUI.
neutron.Gui("+LabelNeutron")

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

; The built in GuiClose, GuiEscape, and GuiDropFiles event handlers will work
; with Neutron GUIs. Using them is the current best practice for handling these
; types of events. Here, we're using the name NeutronClose because the GUI was
; given a custom label prefix up in the auto-execute section.
NeutronClose:
ExitApp
return


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
