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

#Requires AutoHotkey v2.0

; Include the Neutron library
#Include ../../Neutron.ahk

; Create a new NeutronWindow and navigate to our HTML page
neutron := NeutronWindow()
	.OnEvent("close", (neutron) => ExitApp())
	.Load("Bootstrap.html")
	; Show the Neutron window
	.Show(, "Bootstrap")

; FileInstall all your dependencies, but put the FileInstall lines somewhere
; they won't ever be reached.
if false {
	FileInstall "Bootstrap.html", "*"
	FileInstall "bootstrap.min.css", "*"
	FileInstall "bootstrap.min.js", "*"
	FileInstall "jquery.min.js", "*"
}
return


Button(neutron, event) {
	MsgBox "You clicked " event.target.innerText
}

Submit(neutron, event) {
	; Some events have a default action that needs to be prevented. A form will
	; redirect the page by default, but we want to handle the form data ourself.
	event.preventDefault()

	; Use Neutron's GetFormData method to process the form data into a form that
	; is easily accessed. Fields that have a 'name' attribute will be keyed by
	; that, or if they don't they'll be keyed by their 'id' attribute.
	formData := NeutronWindow.GetFormData(event.target)

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
	MsgBox out
}
