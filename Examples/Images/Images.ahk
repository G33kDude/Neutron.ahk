/*
	Compile Me!
	
	This example demonstrates displaying images through a tabbed multi-page
	interface. When compiled, this image gallery will stay contained in the exe
	file without having to extract the image resources to use them on the page.
*/

#NoEnv
SetBatchLines, -1

; Include the Neutron library
#Include ../../Neutron.ahk

; Create a new NeutronWindow and navigate to our HTML page
neutron := new NeutronWindow()
neutron.Load("Image1.html")

; Show the GUI at its default size.
neutron.Show()
return


; FileInstall all your dependencies, but put the FileInstall lines somewhere
; they won't ever be reached. Right below your AutoExecute section is a great
; location!
FileInstall, Image1.html, Image1.html
FileInstall, Image1.jpg, Image1.jpg
FileInstall, Image2.html, Image2.html
FileInstall, Image2.jpg, Image2.jpg
FileInstall, Image3.html, Image3.html
FileInstall, Image3.jpg, Image3.jpg
FileInstall, Images.css, Images.css

; The built in GuiClose, GuiEscape, and GuiDropFiles event handlers will work
; with Neutron GUIs. Using them is the current best practice for handling these
; types of events.
GuiClose:
ExitApp
return
