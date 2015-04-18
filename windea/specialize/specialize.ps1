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

InstallGit
InstallZMQ
InstallWebTargets -version 11
InstallWebTargets -version 12