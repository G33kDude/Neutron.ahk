
# Welcome to Neutron

Neutron provides a powerful set of tools for build HTML-based user interfaces
with AutoHotkey. It leverages the Trident engine, known for its use in Internet
Explorer, because of its deep integration with the Microsoft Windows operating
system and its wide availability across systems.

Notable features:

* Create GUIs with HTML, CSS, JS, and AHK all working together.
* Make responsive user interfaces that reflow when you resize the window, and
  scroll when elements go out of view.
* Full customization of the title bar including fonts and colors.
* Make better looking interfaces easily with web frameworks like Bootstrap.
* Compile resources into your script and access them without extracting. Very
  useful for including images in the script!

![Neutron Window](https://i.imgur.com/hKecfvb.png)

Listen and watch about Neutron on
[YouTube](https://www.youtube.com/watch?v=cTRcOG28hYI), from the May 2020
webinar recording. This was for a very early version of Neutron but it still
contains many of the core concepts.

## Getting Started with Neutron

The Neutron library is designed to be minimally invasive, easily included into
existing scripts without major modifications. Neutron GUIs are created and
managed similarly to native AutoHotkey GUIs.

```ahk
; --- Creating a GUI ---
; Traditional syntax:
Gui, name:New,, title
Gui, name:Add, ...
; Neutron syntax:
name := new NeutronWindow("html", "css", "js", "title")
; or
name := new NeutronWindow("<!DOCTYPE html><html>full html document</html>")
; or
name := new NeutronWindow()
name.Load("file.html")

; --- Giving Window Options ---
; Traditional syntax:
Gui, name:+Option +Option
; Neutron syntax:
name.Gui("+Option +Option")

; --- Showing the GUI ---
; Traditional syntax:
Gui, name:Show, w800 h600
; Neutron syntax:
name.Show("w800 h600")

; --- Handling Events ---
; Traditional syntax:
Gui, name:+LabelNamedGui
return
NamedGuiClose:
NamedGuiEscape:
NamedGuiDropFiles:
MsgBox, Events!
return
; Neutron syntax:
name.Gui("+LabelNamedGui")
return
NamedGuiClose:
NamedGuiEscape:
NamedGuiDropFiles:
MsgBox, Events!
return

; --- Hiding the GUI ---
; Traditional syntax:
Gui, name:Hide
; Neutron syntax:
name.Hide()

; --- Destroying the GUI ---
; Traditional syntax:
Gui, name:Destroy
; Neutron syntax:
name.Destroy()
```

Because all controls are now created through the HTML you provide to Neutron,
you're going to need a new way to set up event handlers like the button gLabels
you may be familiar with from native GUIs. Neutron provides the HTML/JS with a
way to call functions defined in your AutoHotkey source. This is a very
convenient method to set up event handlers.

The AHK function will receive any parameters passed by the JavaScript, with an
extra "neutron" parameter passed in first that contains the Neutron instance
that triggered the event.

```ahk
neutron := new NeutronWindow("<button onclick='ahk.Clicked(event)'>Hi</button>")
neutron.Show()
return

Clicked(neutron, event)
{
    MsgBox, % "You clicked: " event.target.innerText
}
```

Neutron offers a number of shorthands and utility methods to make it easier to
interact with the page from AutoHotkey. A non-exhaustive list of these is below:

```ahk
neutron := new NeutronWindow("<span>a</span><span>b</span><span>c</span>")

; neutron.doc
; Equivalent to "document" in JS, used to access page contents
MsgBox, % neutron.doc.body.outerHTML

; neutron.wnd
; Equivalent to "window" in JS, used to access JS functions and variables
neutron.wnd.alert("Hi")

; neutron.qs("CSS Selector")
; Equivalent to "document.querySelector" in JS
element := neutron.qs(".main span")

; neutron.qsa("CSS Selector")
; Equivalent to "document.querySelectorAll" in JS
elements := neutron.qsa(".main span")

; neutron.Each(collection)
; Allow enumeration of JS arrays / element collections
for index, element in neutron.Each(elements)
    MsgBox, % index ": " element.innerText

; neutron.GetFormData(formElement)
; More easily processing of form data
formData := neutron.GetFormData(formElement)
MsgBox, % formData.fieldName ; Pull a single field
for name, value in formData ; Iterate all fields
    MsgBox, %name%: %value%

; Escape values to place into HTML
; neutron.EscapeHTML("unsafe text")
neutron.qs(".main").innerHTML := "<div>" neutron.EscapeHTML("a<'&>z") "</div>"
; neutron.FormatHTML("format string", "unsafe text 1", "unsafe text 2", ...)
neutron.qs(".main").innerHTML := neutron.FormatHTML("<div>{}</div>", "a<'&>z")
```

There's plenty more to be learned about Neutron from browsing its source and
examples. Neutron's source is commented with great detail, and many methods
have full runnable usage examples in the comments alongside them.

## Neutron Examples

Neutron comes with a few example scripts to demonstrate how to use the library
in a variety of situations. None of them are a one-size-fits-all solution, but
they can be a great starting point for building your own Neutron UIs.

### Template

Complexity: 1 / 5

> This example is designed to show how to use the default Neutron template page.
> Because it uses the default template, it is also the simplest example to use
> and tweak as a beginner.
>
> It is also designed to show how you would apply your own theming to the
> template without having to modify it directly, by applying CSS styling to the
> built-in template title bar elements.

### Images

Complexity: 2 / 5

> This example demonstrates displaying images through a tabbed multi-page
> interface. When compiled, this image gallery will stay contained in the exe
> file without having to extract the image resources to use them on the page.

### Simple

Complexity: 2 / 5

> This example, while named Simple, is not the most simplistic example. Instead,
> it is designed to demonstrate all of Neutron's built in behavior as a single
> custom page. It is meant to be simple by comparison to other examples like the
> Bootstrap example which demonstrate extending Neutron's functionality with
> third party web frameworks.

### Bootstrap

Complexity: 4 / 5

> This example is designed to show how you can use third party frameworks like
> Bootstrap to build advanced user interfaces, while still keeping all the code
> local. This script can be compiled and still function fine without the need to
> extract any files to a temporary directory.
>
> As this example is more advanced, it assumes a stronger familiarity with the
> technology and may gloss over some parts more than other examples. If you're
> just getting started it may be helpful to work with some of the other example
> scripts first.

## Compiling Neutron Scripts
Some Neutron scripts may require many dependencies, such as HTML, CSS, JS, SVG,
and image files. Using one of the following methods, your Neutron script can 
be compiled into a portable exe that contains all these dependencies internally,
without needing to extract them to a temporary directory for use.

### A. Using compiler directives *(requires AutoHotkey v1.1.33+)*
1. Add a `;@Ahk2Exe-AddResource *10 FileName` directive for each dependent file.
    * For example: `;@Ahk2Exe-AddResource *10 index.html`
    * Dependant files can be in any sub directory 
      `;@Ahk2Exe-AddResource *10 %A_ScriptDir%\css\styles.css`.
    * It doesn't matter where the directive line is in the script.
2. Reference dependent files by name only, without any path portion.
   * In AHK: `neutron.Load("index.html")`
   * In HTML: `<script src="index.js">`,
    `<link href="index.css" rel="stylesheet">`,
    `<img src="image.jpg">`

### B. Using FileInstall
1. Any dependent files must be in the same directory as your AutoHotkey script
   file.
2. Reference dependent files by name only, without any path portion.
   * In AHK: `neutron.Load("index.html")`
   * In HTML: `<script src="index.js">`,
     `<link href="index.css" rel="stylesheet">`,
     `<img src="image.jpg">`
3. Have a `FileInstall` for each dependent file somewhere in the script. Put this
   somewhere that it won't be reached, such as just below the `return` after
   your auto-execute section.

When you do this, the dependent files will be saved into the EXE's RCDATA
resources. Neutron's `Load()` method will detect when your script is compiled
and read the dependencies from there instead of looking for files on the system.

## Copyright Disclaimer

The core components of this library have been released under the MIT license,
but some examples contain third party code where other or additional license
restrictions may apply.

### Examples/Bootstrap/bootstrap.min.css

```css
/*!
 * Bootstrap v4.5.0 (https://getbootstrap.com/)
 * Copyright 2011-2020 The Bootstrap Authors
 * Copyright 2011-2020 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 */
```

### Examples/Bootstrap/bootstrap.min.js

```js
/*!
  * Bootstrap v4.3.1 (https://getbootstrap.com/)
  * Copyright 2011-2019 The Bootstrap Authors (https://github.com/twbs/bootstrap/graphs/contributors)
  * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
  */
```

### Examples/Bootstrap/jquery.min.js

```js
/*! jQuery v3.5.1 | (c) JS Foundation and other contributors | jquery.org/license */
```

---

## [Download Neutron](https://github.com/G33kDude/Neutron.ahk/releases)