$resourcesDir = "$ENV:SystemDrive\glazier\profile"
$sqlServerExtractionPath = Join-Path $resourcesDir "extract"
$saPasswd = "INullPeer0000"

$sqlServerExpressPath = Join-Path $resourcesDir "sqlexpr2012_x64.exe"

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function ExtractSQLServer(){
    Write-Output "Extracting SQL Server Express 2012"
    $argList = "/q", "/x:${sqlServerExtractionPath}"

    $extactProcess = Start-Process -Wait -PassThru -NoNewWindow $sqlServerExpressPath -ArgumentList $argList
    if ($extactProcess.ExitCode -ne 0)
    {
        throw "Failed to extract Sql Server Express 2012."
    }
    else
	{
		Write-Output "[OK] SQL Server Express extraction was successful."
	}

}

function InstallSqlServer()
{
	Write-Output "Installing SQL Server Express 2012"

    $argList = "/ACTION=Install", "/INDICATEPROGRESS", "/Q", "/UpdateEnabled=False", "/FEATURES=SQLEngine", "/INSTANCENAME=SQLEXPRESS",
                "/INSTANCEID=SQLEXPRESS","/X86=False", "/SQLSVCSTARTUPTYPE=Automatic","/SQLSYSADMINACCOUNTS=Administrator",
                "/ADDCURRENTUSERASSQLADMIN=False","/TCPENABLED=1","/NPENABLED=0","/SECURITYMODE=SQL","/IACCEPTSQLSERVERLICENSETERMS",
                "/SAPWD=${saPasswd}"

    $sqlServerSetup = Join-Path $sqlServerExtractionPath "SETUP.EXE"

    Start-Process -Wait -PassThru -NoNewWindow $sqlServerSetup -ArgumentList $argList
    

	if ($installSQLServerProcess.ExitCode -gt 0)
	{
        $exitCode = $installSQLServerProcess.ExitCode
		throw "Failed to install Sql Server Express 2012 exit code ${exitCode}"
	}
	else
	{
		Write-Output "[OK] SQL Server Express installation was successful."
	}
}


function EnableStaticPort()
{
	Write-Output "Enabling TCP access to SQL Server"
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp\IPAll' -Name TcpDynamicPorts -Value ""
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp\IPAll' -Name TcpPort -Value 1433

    Write-Output "Restarting SQL Server"
    Restart-Service 'MSSQL$SQLEXPRESS'
}

function EnableContainedDatabaseAuthentication()
{
	Write-Output "Enable contained database authentication"

    $argList = "-S .\sqlexpress","-U sa", "-P ${saPasswd}", "-Q `"EXEC sp_configure `'contained database authentication`', 1; reconfigure;`""
    $sqlCmdProcess = Start-Process -Wait -PassThru -NoNewWindow "SQLCmd" -ArgumentList $argList

    if ($sqlCmdProcess.ExitCode -ne 0)
    {
        $exitCode = $installSQLServerProcess.ExitCode
		throw "Failed to enable contained database authentication, exit code ${exitCode}"
    }

}

function AddSystemUser()
{
	Write-Output "Adding system user"

    $argList = "-S .\sqlexpress","-U sa", "-P ${saPasswd}", "-Q `"ALTER SERVER ROLE [sysadmin] ADD MEMBER [NT AUTHORITY\SYSTEM];`""

    $sqlCmdProcess = Start-Process -Wait -PassThru -NoNewWindow "SQLCmd" -ArgumentList $argList

    if ($sqlCmdProcess.ExitCode -ne 0)
    {
        $exitCode = $installSQLServerProcess.ExitCode
		throw "Failed to enable contained database authentication, exit code ${exitCode}"
    }
}

function SetupWinRM($port, $hostName)
{
  Write-Output 'Setting up WinRM ...'

  Write-Output "Generating a new self-signed cert ..."
  $cert = New-SelfSignedCertificate -DnsName $hostName -CertStoreLocation cert:\localmachine\my
  $thumbprint = $cert.Thumbprint

  Write-Output "Cleanup WinRM settings ..."
  cmd /c 'winrm delete winrm/config/Listener?Address=*+Transport=HTTP'
  cmd /c 'winrm delete winrm/config/Listener?Address=*+Transport=HTTPS'

  Write-Output "Creating WinRM configuration ..."
  & cmd /c "winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname=`"${hostName}`";CertificateThumbprint=`"${thumbprint}`";Port=`"${port}`"}"

  Write-Output "Enabling certificate authentication ..."
  & cmd /c  'winrm set winrm/config/client/auth @{Certificate="true"}'

  Write-Output "Opening firewall port ${port}"
  & netsh advfirewall firewall add rule name="WinRM" protocol=TCP dir=in localport=${port} action=allow
}

function SetupStackatoUser()
{
  Write-Output 'Setting up stackato user ...'

  $computername = $Env:COMPUTERNAME
  $username = "stackato"

  $Computer = [ADSI]"WinNT://$computername,Computer"
  $LocalAdmin = $Computer.Create("User", $username)
  $LocalAdmin.SetPassword("St@ckato")
  $LocalAdmin.SetInfo()
  $LocalAdmin.FullName = "stackato"
  $LocalAdmin.SetInfo()
  $LocalAdmin.Description = "Stackato account used for setup"
  $LocalAdmin.SetInfo()
  $LocalAdmin.UserFlags = 65536
  $LocalAdmin.SetInfo()

  $group = [ADSI]("WinNT://$computername/administrators,group")
  $group.add("WinNT://$username,user")
}

ExtractSQLServer
InstallSqlServer
EnableStaticPort
EnableContainedDatabaseAuthentication
AddSystemUser
SetupWinRM 5986 '127.0.0.1'
SetupStackatoUser