$resourcesDir = "$ENV:SystemDrive\glazier\profile"

$zmqInstaller = Join-Path $resourcesDir "zmq-installer.exe"
$gitInstaller = Join-Path $resourcesDir "git-installer.exe"
$vs2013BuildToolsInstaller = Join-Path $resourcesDir "vs2012bt-installer.exe"

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

function InstallVSBuildTools()
{
  Write-Output "Installing VS2013 Build Tools ..."

  $installVSBTProcess = Start-Process -Wait -PassThru -NoNewWindow $vs2013BuildToolsInstaller "/Q"

  if ($installVSBTProcess.ExitCode -ne 0)
  {
    throw 'Failed to install VS2013 Build Tools.'
  }
  else
  {
    Write-Output "[OK] VS2013 Build Tools installation was successful."
  }
}

InstallGit
InstallZMQ
InstallVSBuildTools