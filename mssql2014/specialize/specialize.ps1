$resourcesDir = "$ENV:SystemDrive\glazier\profile"
$sqlServerExtractionPath = Join-Path $resourcesDir "extract"
$saPasswd = "INullPeer0000"

$sqlServerExpressPath = Join-Path $resourcesDir "sqlexpr2014_x64.exe"

function ExtractSQLServer(){
    Write-Output "Extracting SQL Server Express 2014"
    $argList = "/q", "/x:${sqlServerExtractionPath}"

    $extactProcess = Start-Process -Wait -PassThru -NoNewWindow $sqlServerExpressPath -ArgumentList $argList
    if ($extactProcess.ExitCode -ne 0)
    {
        throw "Failed to extract Sql Server Express 2014."
    }
    else
	{
		Write-Output "[OK] SQL Server Express extraction was successful."
	}

}

function InstallSqlServer()
{
	Write-Output "Installing SQL Server Express 2014"

    $argList = "/ACTION=Install", "/INDICATEPROGRESS", "/Q", "/UpdateEnabled=False", "/FEATURES=SQLEngine", "/INSTANCENAME=SQLEXPRESS",
                "/INSTANCEID=SQLEXPRESS","/X86=False", "/SQLSVCSTARTUPTYPE=Automatic","/SQLSYSADMINACCOUNTS=Administrator",
                "/ADDCURRENTUSERASSQLADMIN=False","/TCPENABLED=1","/NPENABLED=0","/SECURITYMODE=SQL","/IACCEPTSQLSERVERLICENSETERMS",
                "/SAPWD=${saPasswd}"

    $sqlServerSetup = Join-Path $sqlServerExtractionPath "SETUP.EXE"

    Start-Process -Wait -PassThru -NoNewWindow $sqlServerSetup -ArgumentList $argList
    

	if ($installSQLServerProcess.ExitCode -gt 0)
	{
        $exitCode = $installSQLServerProcess.ExitCode
		throw "Failed to install Sql Server Express 2014 exit code ${exitCode}"
	}
	else
	{
		Write-Output "[OK] SQL Server Express installation was successful."
	}
}


function EnableStaticPort()
{
	Write-Output "Enabling TCP access to SQL Server"
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp\IPAll' -Name TcpDynamicPorts -Value ""
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp\IPAll' -Name TcpPort -Value 1433

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

ExtractSQLServer
InstallSqlServer
EnableStaticPort
EnableContainedDatabaseAuthentication
AddSystemUser