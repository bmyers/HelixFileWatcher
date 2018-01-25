# HelixFileWatcher

This is a tool to automatically take changes made in your code repository and move them over to your Sitecore webroot as you make changes.  Eliminating the need to run a manual publish.

## Configuring the tool

Required:  Modify the settings in parameters.ps1 to point the watcher to both your code and the web root.

### Adjusting watch locations

By default this tool handles 4 areas:
#### bin
For binary files
#### App_Setting\Include
For configuration files
#### Views
For cshtml files
#### Assets
For front end stuff (css, js)

you may change, add, or remove any of these from [FileWatchSetup.ps1](https://github.com/JeffDarchuk/HelixFileWatcher/blob/e15bf20f5c01202e5d71412202e370d1ef5e3eb3/FileWatchSetup.ps1#L46) line 46

### Adjusting file copy process

By default this tool handles some basic cases where a file changes and it gets moved to the appropriate place in the webroot.  For example:
(source)\bin -> (webroot)\bin
(source)\App_Config\Include -> (webroot)\App_Config\Include

You can change what types of files are managed and how they are managed in the [DeploymentDefinitions.ps1](https://github.com/JeffDarchuk/HelixFileWatcher/blob/master/DeploymentDefinitions.ps1)
the magic happens with a hashtable that's a string to script block object.  When a watcher finds a file with an extention matching what is in the hashtable, it executes the script block with the parameters Path, OldPath (if a rename) and a switch for deleted (if deleted) then it's up to your script block to decide what happens to it.
