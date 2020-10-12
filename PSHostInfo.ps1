[void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

$currentDir = [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\') 
if ($currentDir -eq $PSHOME.TrimEnd('\')) 
{     
	$currentDir = $PSScriptRoot 
}

$IconOKPath = $currentDir + "\support.ico"
$IconWarnPath = $currentDir + "\TWS_Caller_5.ico"

$form1 = New-Object System.Windows.Forms.form
$NotifyIcon= New-Object System.Windows.Forms.NotifyIcon
$ContextMenu = New-Object System.Windows.Forms.ContextMenu
$MenuItem = New-Object System.Windows.Forms.MenuItem
$TimerPC = New-Object System.Windows.Forms.Timer
$iconOK = New-Object System.Drawing.Icon($IconOKPath)
$iconWarn = New-Object System.Drawing.Icon($IconWarnPath)
 
$form1.ShowInTaskbar = $false
$form1.WindowState = "minimized"
 
$NotifyIcon.Icon =  $iconOK
$NotifyIcon.ContextMenu = $ContextMenu
$NotifyIcon.contextMenu.MenuItems.AddRange($MenuItem)
$NotifyIcon.Visible = $True
 
$TimerPC.Interval =  300000  # (5 min)

$TimerPC.add_Tick({FNCheckComputer})
$TimerPC.start()
 
$MenuItem.Text = "Exit"
$MenuItem.add_Click({
   $TimerPC.stop()
   $NotifyIcon.Visible = $False
   $form1.close()
})

function FNCheckComputer
    {
    $computername = $Env:computername
    
    
    $Netinfo = Test-Connection $computername -count 1 | select Address,Ipv4Address
    $ipaddress = $netinfo.IPV4Address.IPAddressToString
    #$Text = $computername
    $Text = 
@"
${computername}
${ipAddress}
"@
    
    $NotifyIcon.Text = $Text

    $NotifyIcon.Icon = $iconOK
    } 

FNcheckComputer
[void][System.Windows.Forms.Application]::Run($form1)