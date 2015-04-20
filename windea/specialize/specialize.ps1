$resourcesDir = "$ENV:SystemDrive\glazier\profile"

$zmqInstaller = Join-Path $resourcesDir "zmq-installer.exe"
$gitInstaller = Join-Path $resourcesDir "git-installer.exe"
$webTargetsZip = Join-Path $resourcesDir "web-targets"

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function InstallGit()
{
  Write-Output "Installing git ..."

  $installGitProcess = Start-Process -Wait -PassThru -NoNewWindow $gitInstaller "/silent"

  if ($installGitProcess.ExitCode -ne 0)
  {
    throw 'Failed to install git.'
  }
  else
  {
    Write-Output "[OK] Git installation was successful."
  }
}

function InstallZMQ()
{
  Write-Output "Installing ZeroMQ ..."

  $installZMQProcess = Start-Process -Wait -PassThru -NoNewWindow $zmqInstaller "/S /D=c:\zmq"

  if ($installZMQProcess.ExitCode -ne 0)
  {
    throw 'Failed to install ZeroMQ.'
  }
  else
  {
    Write-Output "[OK] ZeroMQ installation was successful."
  }
}

function InstallWebTargets($version)
{
  Write-Output "Extracting Web targets ..."

  $guid = [guid]::NewGuid()

  $extractPath = Join-Path $resourcesDir $guid

  Write-Host $extractPath

  New-Item $extractPath -type directory 
  Expand-ZIPFile -file "${webTargetsZip}${version}.zip" -destination $extractPath

  Write-Output "Installing Web targets"

  $webTargetsPath = Join-Path $extractPath "tools\VSToolsPath"
  $vsPath = "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v${version}.0"
  
  if (-Not (Test-Path $vsPath))
  {
    New-Item $vsPath -type directory
  }

  Copy-Item "${webTargetsPath}\*" -Destination $vsPath -Recurse -Force

  Write-Output "[OK] Web targets succesfully installed."
  
}

function Expand-ZIPFile($file, $destination)
{
    $shell = new-object -com shell.application
    $zip = $shell.NameSpace($file)
    foreach($item in $zip.items())
    {
        $shell.Namespace($destination).copyhere($item)
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


InstallGit
InstallZMQ
InstallWebTargets -version 11
InstallWebTargets -version 12
SetupWinRM 5986 '127.0.0.1'
SetupStackatoUser