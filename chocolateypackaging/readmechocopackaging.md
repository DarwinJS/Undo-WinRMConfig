
# Dual Purposing To Run Utility Scripts In and Out of Chocolatey

The structure of this chocolatey package enables:
* the core code to be a plain shell script that can be pulled directly from the web or copied to a target system
* the chocolatey package to a wrapper / additional execution mechanism
* the core code and its documentation to be the primary thing seen when visiting the repository page
* the chocolatey packaging to all be in a subfolder below the primary code