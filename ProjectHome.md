![http://www.google.com/accounts/ah/appengine.jpg](http://www.google.com/accounts/ah/appengine.jpg)

# Mac Launcher for Google App Engine #

The google-appengine-mac-launcher project contains the source code for the GUI launcher included in the Google App Engine SDK for Python on Mac.  The launcher itself is written in Objective-C.  The source code for the launcher distributed with the App Engine Windows SDK installer can be found on the [google-appengine-wx-launcher](http://code.google.com/p/google-appengine-wx-launcher/) project page.

## The Launcher ##

![http://google-appengine-mac-launcher.googlecode.com/svn/trunk/site/images/launcher-screen.png](http://google-appengine-mac-launcher.googlecode.com/svn/trunk/site/images/launcher-screen.png)

Here you can see the Launcher window with three projects.  The first project is currently running locally on port 8080.  The second project, selected, is running on port 8081.  The Log Console for this project is also open.  You can stop it, navigate to the local application in a browser, deploy it to appspot.com, and see the project dashboard.  The last project is not running.

## Development ##

An XCode project to compile it outside the Google build environment will soon be available.
