<#
.SYNOPSIS
	Present hostname and IP with notification icon
.DESCRIPTION
	This script will display a notification icon and will display hostname and ip address for support usage
.PARAMETER <Parameter_Name>
	None
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        	1.0
  Author:         	Bart Jacobs - @Cloudsparkle
  Creation Date:  	15/10/2020
  Purpose/Change: 	Present hostname and ip address
	General credits:  Denniver Reining - https://bytecookie.wordpress.com/2011/12/28/gui-creation-with-powershell-part-2-the-notify-icon-or-how-to-make-your-own-hdd-health-monitor/
 .EXAMPLE
	None
#>

#load the framework to display stuff
[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

#Get the current working directory
#Credits 1: https://www.alkanesolutions.co.uk/2019/10/10/obtaining-the-current-working-directory-using-powershell/ - Kae Travis
#Credits 2: https://powershell.org/forums/topic/compile-ps1-to-exe/ - Dave Wyatt
$currentDir = [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\')
if ($currentDir -eq $PSHOME.TrimEnd('\'))
	{
		$currentDir = $PSScriptRoot
	}

#Set path to display icon
$IconOKPath = $currentDir + "\support.ico"
$IconOKFileExists = Test-Path $IconOKPath
If ($IconOKFileExists -eq $fals)
	{
			Write-Host -ForegroundColor Red "Display icon not found. Exiting..."
			exit 1
	}

#Initialize
$form1 = New-Object System.Windows.Forms.form
$NotifyIcon= New-Object System.Windows.Forms.NotifyIcon
$ContextMenu = New-Object System.Windows.Forms.ContextMenu
$MenuItem = New-Object System.Windows.Forms.MenuItem
$TimerPC = New-Object System.Windows.Forms.Timer
$iconOK = New-Object System.Drawing.Icon($IconOKPath)

$form1.ShowInTaskbar = $false
$form1.WindowState = "minimized"

$NotifyIcon.Icon =  $iconOK
$NotifyIcon.ContextMenu = $ContextMenu
$NotifyIcon.contextMenu.MenuItems.AddRange($MenuItem)
$NotifyIcon.Visible = $True

#Set the refresh timer
$TimerPC.Interval =  30000  # (30 sec)

$TimerPC.add_Tick({CheckComputer})
$TimerPC.start()

#Set up the right-click menu
$MenuItem.Text = "Exit"
$MenuItem.add_Click({
   $TimerPC.stop()
   $NotifyIcon.Visible = $False
   $form1.close()
})

#The part that actually gets the information
function CheckComputer
{
    $computername = $Env:computername

    $Netinfo = Test-Connection $computername -count 1 | select Address,Ipv4Address
    $ipaddress = $netinfo.IPV4Address.IPAddressToString

    $Text =
@"
${computername}
${ipAddress}
"@

    $NotifyIcon.Text = $Text
}

CheckComputer
[void][System.Windows.Forms.Application]::Run($form1)
