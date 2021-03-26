# PSGLPI

This Powershell module makes easy the manipulation of the GLPI database thru the Rest API of GLPI.
Search, add, modify, delete items has never be so easy.
Native object and plugin objects are available.

Use the module integrated help to see how it works.

Enjoy! :-)

## Prerequisites
- Rest API needs to be enabled in GLPI (GLPI Setup -> General -> API).
- An APP token (GLPI Setup -> General -> API -> API Client)
- username-password or a API token (See GLPI user management)

## Install the Module
Donwload the module.
Follow Microsoft directions : https://docs.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module

## Or use it directly from GITHUB
Insert the folowwing lines in your script. It will download the module from GitHub and import it in your Powershell session.

`[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/J-C-P/PSGLPI/master/PSGLPI.psm1" -OutFile "$env:TEMP\PSGLPI.psm1"
Import-Module "$env:TEMP\PSGLPI.psm1" -Force`


## Exemples
### Generate your Basic user token
Use this to generate your Basic token in case you don't want to use the API token associated with your GLPI account.
`Get-GlpiBase64Login -login mysusername -password MySuperComplicatedPassw0rd
bXlzdXNlcm5hbWU6TXlTdXBlckNvbXBsaWNhdGVkUGFzc3cwcmQ=`




Update in progress...
