/*
	Compile Me!

	This example demonstrates displaying images through a tabbed multi-page
	interface. When compiled, this image gallery will stay contained in the exe
	file without having to extract the image resources to use them on the page.
*/

#Requires AutoHotkey v2.0

; Include the Neutron library
#Include ../../Neutron.ahk

; Create a new NeutronWindow and navigate to our HTML page
neutron := NeutronWindow()
	.OnEvent("Close", (neutron) => ExitApp())
	.Load("Image1.html")
	.Show(, "Images")	; Show the GUI at its default size.

; FileInstall all your dependencies, but put the FileInstall lines somewhere
; they won't ever be reached.
if false {
	FileInstall "Image1.html", "*"
	FileInstall "Image1.jpg", "*"
	FileInstall "Image2.html", "*"
	FileInstall "Image2.jpg", "*"
	FileInstall "Image3.html", "*"
	FileInstall "Image3.jpg", "*"
	FileInstall "Images.css", "*"
}
return