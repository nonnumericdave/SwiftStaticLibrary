## SwiftStaticLibrary
Create an Xcode static library target containing Swift code.

### Description
You're probably here because you tried adding a Swift source file to an Xcode project targetting a static library and you got the following message:

Swift is not supported for static libraries.

This project creates and installs an Xcode plugin that will allow you, the developer, who knows EXACTLY what you are doing, to add a Swift source file to an Xcode project targetting a static library.

### Requirements
This project was designed and built against Xcode 7.3.1.

### Usage
Build the SwiftStaticLibrary Xcode project, which will automagically install the Xcode plugin in the follow location:

${HOME}/Library/Application Support/Developer/Shared/Xcode/Plug-ins/SwiftStaticLibrary.xcplugin

After building and installing the Xcode plugin, you will need to exit and relaunch Xcode in order for the plugin to be loaded properly.  Xcode will notice the plugin and ask if you want to use it, at which point you'll proably shout "YAAASSS!" because you're trying to work around Apple's completely arbitrary rules that make absolutely no sense, like, say, getting rid of C-style for loops in Swift.

If you want to stop using the plugin, simply delete the aforementioned directory from Terminal:

rm -rf "${HOME}/Library/Application Support/Developer/Shared/Xcode/Plug-ins/SwiftStaticLibrary.xcplugin"

I've also included an example project which is comprised of an application (ExampleApplication) which has a dependency on a static library (ExampleStaticLibrary) containing Swift code.  Simply load up the ExampleApplication project in Xcode, and it will suddenly all make sense.

Eventually I'll get around to adding this to Alcatraz, who I'd like to give a special shout-out to for giving us awesome plugin templates.
