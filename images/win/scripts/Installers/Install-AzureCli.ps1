################################################################################
##  File:  Install-AzureCli.ps1
##  Desc:  Install Azure CLI
################################################################################

Choco-Install -PackageName azure-cli

$AzureCliExtensionPath = Join-Path $Env:CommonProgramFiles 'AzureCliExtensionDirectory'
if (-not(Test-Path -Path $AzureCliExtensionPath)) {
	New-Item -ItemType "directory" -Path $AzureCliExtensionPath -Force
}

[Environment]::SetEnvironmentVariable("AZURE_EXTENSION_DIR", $AzureCliExtensionPath, [System.EnvironmentVariableTarget]::Machine)

Invoke-PesterTests -TestFile "CLI.Tools" -TestName "Azure CLI"