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

#Function to read config.ini
Function Get-IniContent
{
    <#
    .Synopsis
        Gets the content of an INI file
    .Description
        Gets the content of an INI file and returns it as a hashtable
    .Notes
        Author        : Oliver Lipkau <oliver@lipkau.net>
        Blog        : http://oliver.lipkau.net/blog/
        Source        : https://github.com/lipkau/PsIni
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
        Version        : 1.0 - 2010/03/12 - Initial release
                      1.1 - 2014/12/11 - Typo (Thx SLDR)
                                         Typo (Thx Dave Stiff)
        #Requires -Version 2.0
    .Inputs
        System.String
    .Outputs
        System.Collections.Hashtable
    .Parameter FilePath
        Specifies the path to the input file.
    .Example
        $FileContent = Get-IniContent "C:\myinifile.ini"
        -----------
        Description
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent
    .Example
        $inifilepath | $FileContent = Get-IniContent
        -----------
        Description
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent
    .Example
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"
        C:\PS>$FileContent["Section"]["Key"]
        -----------
        Description
        Returns the key "Key" of the section "Section" from the C:\settings.ini file
    .Link
        Out-IniFile
    #>

    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$FilePath
    )

    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}

    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

        $ini = @{}
        switch -regex -file $FilePath
        {
            "^\[(.+)\]$" # Section
            {
                $section = $matches[1]
                $ini[$section] = @{}
                $CommentCount = 0
            }
            "^(;.*)$" # Comment
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = "Comment" + $CommentCount
                $ini[$section][$name] = $value
            }
            "(.+?)\s*=\s*(.*)" # Key
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $name,$value = $matches[1..2]
                $ini[$section][$name] = $value
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
        Return $ini
    }

    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}

#Function to actually check for information
Function CheckComputer
{
    $script:computername = $Env:computername
    $username = $env:USERNAME
    $domainname = $env:USERDOMAIN
    $script:domainuser = $domainname + "\" + $username
    $Netinfo = Test-Connection $computername -count 1 | select Address,Ipv4Address
    $script:ipaddress = $netinfo.IPV4Address.IPAddressToString

    if ($ShowUser -eq 0)
        {
            $script:Text =
@"
${computername}
${ipAddress}
"@
        }
    Else
        {
        $script:Text =
@"
${domainuser}
${computername}
${ipAddress}
"@
        }

    $NotifyIcon.Text = $Text
}

#Load the framework to display stuff
[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

#Get the current working directory
#Credits 1: https://www.alkanesolutions.co.uk/2019/10/10/obtaining-the-current-working-directory-using-powershell/ - Kae Travis
#Credits 2: https://powershell.org/forums/topic/compile-ps1-to-exe/ - Dave Wyatt
$currentDir = [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\')
if ($currentDir -eq $PSHOME.TrimEnd('\'))
	{
		$currentDir = $PSScriptRoot
	}

#Read inifile
$IniFilePath = $currentDir + "\config.ini"
$IniFileExists = Test-Path $IniFilePath
If ($IniFileExists -eq $true)
  {
    $IniFile = Get-IniContent $IniFilePath

    $ShowExit = $IniFile["MENU"]["ShowExit"]
    if ($ShowExit -eq $null)
      {
        $ShowExit = 0
      }

    $ShowSupportMail = $IniFile["MENU"]["ShowSupportMail"]
    if ($ShowSupportMail -eq $null)
      {
        $ShowSupportMail = 0
      }

    $ShowSupportPortal = $IniFile["MENU"]["ShowSupportPortal"]
    if ($ShowSupportMail -eq $null)
      {
        $ShowSupportMail = 0
      }

    $ShowUser = $IniFile["OUTPUT"]["ShowUser"]
    if ($ShowUser -eq $null)
      {
        $ShowUser = 0
      }
	}
Else
  {
    $ShowExit = 0
    $ShowUser = 0
    $ShowSupportMail = 0
  }

#Set path to display icon
$IconOKPath = $currentDir + "\support.ico"
$IconOKFileExists = Test-Path $IconOKPath
If ($IconOKFileExists -eq $false)
	{
			Write-Host -ForegroundColor Red "Display icon not found. Exiting..."
			exit 1
	}

#Initialize
$form1 = New-Object System.Windows.Forms.form
$NotifyIcon= New-Object System.Windows.Forms.NotifyIcon
$ContextMenu = New-Object System.Windows.Forms.ContextMenu
$TimerPC = New-Object System.Windows.Forms.Timer
$iconOK = New-Object System.Drawing.Icon($IconOKPath)

$form1.ShowInTaskbar = $false
$form1.WindowState = "minimized"

$NotifyIcon.Icon =  $iconOK
$NotifyIcon.ContextMenu = $ContextMenu
$NotifyIcon.Visible = $True

#Set up the right-click menu for Exiting
if ($ShowExit -eq 1)
  {
    $MenuItem1 = New-Object System.Windows.Forms.MenuItem
    $NotifyIcon.contextMenu.MenuItems.AddRange($MenuItem1)

    $MenuItem1.Text = "Exit"
    $MenuItem1.add_Click({
        $TimerPC.stop()
        $NotifyIcon.Visible = $False
        $form1.close()
    })
  }

#Set up the right-click menu for E-mailing Support
if ($ShowSupportMail -eq 1)
  {
    $MenuItem3 = New-Object System.Windows.Forms.MenuItem
    $NotifyIcon.contextMenu.MenuItems.AddRange($MenuItem3)

    $MenuItem3.Text = "Support E-Mail"
    $MenuItem3.add_Click({
        $Mailto = $IniFile["SUPPORT"]["SupportMail"]
        if ($mailto -eq "")
            {
            $mailto = "WARNING: Support E-mail address not defined in config.ini!"
            }
        $Mailstring = "mailto:"+ $Mailto + "?Body=User: " + $domainuser + "%0D%0A" + "Computer: " + $computername + "%0D%0A" + "IP Address: " + $ipAddress
        Start-Process $Mailstring
        
    })
  }

#Set up the right-click menu for opening Support Web Portal
if ($ShowSupportPortal -eq 1)
  {
    $MenuItem4 = New-Object System.Windows.Forms.MenuItem
    $NotifyIcon.contextMenu.MenuItems.AddRange($MenuItem4)

    $MenuItem4.Text = "Support Portal"
    $MenuItem4.add_Click({
        $PortalURL = $IniFile["SUPPORT"]["SupportPortal"]
        if ($PortalURL -eq "")
            {
            $PortalURL = "https://www.google.com"
            }
        Write-Host $PortalURL
        Start-Process $PortalURL
        
    })
  }

#Set up the right-click menu for Copy to ClipBoard
$MenuItem2 = New-Object System.Windows.Forms.MenuItem
$NotifyIcon.contextMenu.MenuItems.AddRange($MenuItem2)
$MenuItem2.Text = "Copy To ClipBoard"
$MenuItem2.add_Click({
   Set-Clipboard -Value $Text
})

#Set the refresh timer
$TimerPC.Interval =  30000  # (30 sec)

$TimerPC.add_Tick({CheckComputer})
$TimerPC.start()

CheckComputer
[void][System.Windows.Forms.Application]::Run($form1)