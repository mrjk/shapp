# Clish: Command Line for the Shell

The Clish Framework provides standard and independant libraries for you shell script. It provide
a modular way to organise programs and libraries.

Clish provides many componants:
* shcli (clish_cli.sh): Provides a complete argument parser
    * Command help management
    * Options and Argument management
    * 
* shapp (clish_app.sh): Provide an app skeleton
    * Provide basic app, with help and other stuffs
    * Action centric command line, and nested commands
    * Provide help menu with all available commands


Library structure:
* clish_cli:
    * prefix: shcli
* clish_app:
    * prefix: shapp
    * depends:
        * clish_cli
    * plugins:
        * clish_app_simple
        * clish_app_crud

Files:
* clish_utils:
    * NO PREFIX
* clish_cli:
    * clish_cli_lib.sh
* clish_app:
* clish:
    * Template application with tutor or not
    * Call one instance of shapp



## Quickstart

```
# If you use import.sh

import clish_app.sh  # shapp_
import clish_cli.sh  # shcli_
```



## Documentation


