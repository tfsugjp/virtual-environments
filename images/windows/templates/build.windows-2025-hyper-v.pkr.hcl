// Hyper-V build template for Windows Server 2025 derived from Azure template
// This template uses the hyperv-iso builder instead of azure-arm.

packer {
  required_version = ">= 1.10.0"
  required_plugins {
    windows-update = {
      version = ">= 0.14.2"
      source  = "github.com/rgl/windows-update"
    }
  }
}

# Variables expected to be provided externally or via -var-file.
# Kept minimal for initial prototype. Adjust as needed for your environment.
variable "iso_url" {
  type        = string
  description = "HTTP/HTTPS or file path to Windows Server 2025 ISO"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum of the ISO in format: sha256:..."
}

variable "vm_name" {
  type        = string
  default     = "win2025-hyperv"
  description = "Name of the Hyper-V VM during build"
}

variable "switch_name" {
  type        = string
  default     = "Default Switch"
  description = "Hyper-V virtual switch to attach to (must exist)"
}

variable "cpus" {
  type    = number
  default = 4
}

variable "memory_mb" {
  type    = number
  default = 8192
}

variable "disk_size" {
  type    = number
  default = 128000
  description = "Primary disk size in MB"
}

variable "install_user" {
  type    = string
  default = "packer"
}

variable "install_password" {
  type    = string
  default = "PackerP@ssw0rd!"
}

variable "image_version" {
  type    = string
  default = "dev"
}

variable "image_os" {
  type    = string
  default = "win25"
}

variable "agent_tools_directory" {
  type    = string
  default = "C:/hostedtoolcache/windows"
}

variable "imagedata_file" {
  type    = string
  default = "C:/image-imagedata.json"
}

variable "image_folder" {
  type    = string
  default = "C:/image"
}

variable "temp_dir" {
  type    = string
  default = "C:/temp"
}

variable "helper_script_folder" {
  type    = string
  default = "C:/image/_helper_scripts"
}

# Unattend/autounattend configuration (simplified). In a mature setup, you would
# maintain a dedicated autounattend.xml file; here we rely on common practice of
# injecting an answer file via floppy_files.

locals {
  autounattend = templatefile("${path.root}/locals.windows.pkr.hcl", {})
}

source "hyperv-iso" "win2025" {
  iso_url              = var.iso_url
  iso_checksum         = var.iso_checksum
  iso_checksum_type    = "sha256"

  shutdown_command     = "shutdown /s /t 5 /f"
  communicator         = "winrm"
  winrm_use_ssl        = false
  winrm_insecure       = true
  winrm_timeout        = "6h"
  winrm_username       = var.install_user
  winrm_password       = var.install_password

  vm_name              = var.vm_name
  switch_name          = var.switch_name
  cpus                 = var.cpus
  memory               = var.memory_mb
  disk_size            = var.disk_size
  generation           = 2
  enable_secure_boot   = true
  enable_virtualization_extensions = true

  floppy_files = [
    # Provide your autounattend.xml here; placeholder path.
    # Replace with a real file in subsequent iterations.
    "${path.root}/autounattend/windows-2025-autounattend.xml"
  ]

  # Boot command would be defined if needed for custom install sequences;
  # for modern Windows ISOs with autounattend, this is typically unnecessary.
}

build {
  name    = "windows-2025-hyperv"
  sources = ["source.hyperv-iso.win2025"]

  provisioner "powershell" {
    inline = [
      "New-Item -Path ${var.image_folder} -ItemType Directory -Force",
      "New-Item -Path ${var.temp_dir} -ItemType Directory -Force"
    ]
  }

  # Ensure install user is in Administrators (autounattend should handle, this is a safety check)
  provisioner "powershell" {
    inline = ["if (-not ((net localgroup Administrators) -contains '${var.install_user}')) { Write-Error 'Install user not in Administrators'; exit 1 }"]
  }

  # Enable test signing (parity with Azure template sequence)
  provisioner "powershell" {
    elevated_password = "${var.install_password}"
    elevated_user     = "${var.install_user}"
    inline            = ["bcdedit.exe /set TESTSIGNING ON"]
  }

  provisioner "file" {
    destination = "${var.image_folder}\\"
    sources     = [
      "${path.root}/../assets",
      "${path.root}/../scripts",
      "${path.root}/../toolsets"
    ]
  }

  provisioner "file" {
    destination = "${var.image_folder}\\scripts\\docs-gen\\"
    source      = "${path.root}/../../../helpers/software-report-base"
  }

  provisioner "powershell" {
    inline = [
      "Move-Item '${var.image_folder}\\assets\\post-gen' 'C:\\post-generation'",
      "Remove-Item -Recurse '${var.image_folder}\\assets'",
      "Move-Item '${var.image_folder}\\scripts\\docs-gen' '${var.image_folder}\\SoftwareReport'",
      "Move-Item '${var.image_folder}\\scripts\\helpers' '${var.helper_script_folder}\\ImageHelpers'",
      "New-Item -Type Directory -Path '${var.helper_script_folder}\\TestsHelpers\\'",
      "Move-Item '${var.image_folder}\\scripts\\tests\\Helpers.psm1' '${var.helper_script_folder}\\TestsHelpers\\TestsHelpers.psm1'",
      "Move-Item '${var.image_folder}\\scripts\\tests' '${var.image_folder}\\tests'",
      "Remove-Item -Recurse '${var.image_folder}\\scripts'",
      "Move-Item '${var.image_folder}\\toolsets\\toolset-2025.json' '${var.image_folder}\\toolset.json'",
      "Remove-Item -Recurse '${var.image_folder}\\toolsets'"
    ]
  }

  # --- Phase 1: Base configuration (parity with Azure sequence) ---
  provisioner "powershell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_OS=${var.image_os}", "AGENT_TOOLSDIRECTORY=${var.agent_tools_directory}", "IMAGEDATA_FILE=${var.imagedata_file}", "IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    execution_policy = "unrestricted"
    scripts          = [
      "${path.root}/../scripts/build/Configure-WindowsDefender.ps1",
      "${path.root}/../scripts/build/Configure-PowerShell.ps1",
      "${path.root}/../scripts/build/Install-PowerShellModules.ps1",
      "${path.root}/../scripts/build/Install-WSL2.ps1",
      "${path.root}/../scripts/build/Install-WindowsFeatures.ps1",
      "${path.root}/../scripts/build/Install-Chocolatey.ps1",
      "${path.root}/../scripts/build/Configure-BaseImage.ps1",
      "${path.root}/../scripts/build/Configure-ImageDataFile.ps1",
      "${path.root}/../scripts/build/Configure-SystemEnvironment.ps1",
      "${path.root}/../scripts/build/Configure-DotnetSecureChannel.ps1"
    ]
  }

  provisioner "windows-restart" {
    check_registry        = true
    restart_check_command = "powershell -command \"& {while ( (Get-WindowsOptionalFeature -Online -FeatureName Containers -ErrorAction SilentlyContinue).State -ne 'Enabled' ) { Start-Sleep 30; Write-Output 'InProgress' }}\""
    restart_timeout       = "10m"
  }

  provisioner "powershell" {
    inline = ["Set-Service -Name wlansvc -StartupType Manual", "if ($(Get-Service -Name wlansvc).Status -eq 'Running') { Stop-Service -Name wlansvc}"]
  }

  # --- Phase 2: Core tooling ---
  provisioner "powershell" {
    environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts          = [
      "${path.root}/../scripts/build/Install-Docker.ps1",
      "${path.root}/../scripts/build/Install-DockerWinCred.ps1",
      "${path.root}/../scripts/build/Install-DockerCompose.ps1",
      "${path.root}/../scripts/build/Install-PowershellCore.ps1",
      "${path.root}/../scripts/build/Install-WebPlatformInstaller.ps1",
      "${path.root}/../scripts/build/Install-Runner.ps1"
    ]
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  # --- Phase 3: Visual Studio & Kubernetes tools ---
  provisioner "powershell" {
    elevated_password = "${var.install_password}"
    elevated_user     = "${var.install_user}"
    environment_vars  = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts           = [
      "${path.root}/../scripts/build/Install-VisualStudio.ps1",
      "${path.root}/../scripts/build/Install-KubernetesTools.ps1"
    ]
    valid_exit_codes  = [0, 3010]
  }

  provisioner "windows-restart" {
    check_registry  = true
    restart_timeout = "10m"
  }

  # --- Phase 4: Extended language/platform tooling ---
  provisioner "powershell" {
    pause_before     = "2m0s"
    environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts          = [
      "${path.root}/../scripts/build/Install-Wix.ps1",
      "${path.root}/../scripts/build/Install-VSExtensions.ps1",
      "${path.root}/../scripts/build/Install-AzureCli.ps1",
      "${path.root}/../scripts/build/Install-AzureDevOpsCli.ps1",
      "${path.root}/../scripts/build/Install-ChocolateyPackages.ps1",
      "${path.root}/../scripts/build/Install-JavaTools.ps1",
      "${path.root}/../scripts/build/Install-Kotlin.ps1",
      "${path.root}/../scripts/build/Install-OpenSSL.ps1"
    ]
  }

  provisioner "powershell" {
    execution_policy = "remotesigned"
    environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts          = ["${path.root}/../scripts/build/Install-ServiceFabricSDK.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

  # --- Phase 5: Broad toolset installation ---
  provisioner "powershell" {
    environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts          = [
      "${path.root}/../scripts/build/Install-ActionsCache.ps1",
      "${path.root}/../scripts/build/Install-Ruby.ps1",
      "${path.root}/../scripts/build/Install-PyPy.ps1",
      "${path.root}/../scripts/build/Install-Toolset.ps1",
      "${path.root}/../scripts/build/Configure-Toolset.ps1",
      "${path.root}/../scripts/build/Install-NodeJS.ps1",
      "${path.root}/../scripts/build/Install-AndroidSDK.ps1",
      "${path.root}/../scripts/build/Install-PowershellAzModules.ps1",
      "${path.root}/../scripts/build/Install-Pipx.ps1",
      "${path.root}/../scripts/build/Install-Git.ps1",
      "${path.root}/../scripts/build/Install-GitHub-CLI.ps1",
      "${path.root}/../scripts/build/Install-PHP.ps1",
      "${path.root}/../scripts/build/Install-Rust.ps1",
      "${path.root}/../scripts/build/Install-Sbt.ps1",
      "${path.root}/../scripts/build/Install-Chrome.ps1",
      "${path.root}/../scripts/build/Install-EdgeDriver.ps1",
      "${path.root}/../scripts/build/Install-Firefox.ps1",
      "${path.root}/../scripts/build/Install-Selenium.ps1",
      "${path.root}/../scripts/build/Install-IEWebDriver.ps1",
      "${path.root}/../scripts/build/Install-Apache.ps1",
      "${path.root}/../scripts/build/Install-Nginx.ps1",
      "${path.root}/../scripts/build/Install-Msys2.ps1",
      "${path.root}/../scripts/build/Install-WinAppDriver.ps1",
      "${path.root}/../scripts/build/Install-R.ps1",
      "${path.root}/../scripts/build/Install-AWSTools.ps1",
      "${path.root}/../scripts/build/Install-DACFx.ps1",
      "${path.root}/../scripts/build/Install-MysqlCli.ps1",
      "${path.root}/../scripts/build/Install-SQLPowerShellTools.ps1",
      "${path.root}/../scripts/build/Install-SQLOLEDBDriver.ps1",
      "${path.root}/../scripts/build/Install-DotnetSDK.ps1",
      "${path.root}/../scripts/build/Install-Mingw64.ps1",
      "${path.root}/../scripts/build/Install-Haskell.ps1",
      "${path.root}/../scripts/build/Install-Stack.ps1",
      "${path.root}/../scripts/build/Install-Miniconda.ps1",
      "${path.root}/../scripts/build/Install-AzureCosmosDbEmulator.ps1",
      "${path.root}/../scripts/build/Install-Zstd.ps1",
      "${path.root}/../scripts/build/Install-Vcpkg.ps1",
      "${path.root}/../scripts/build/Install-Bazel.ps1",
      "${path.root}/../scripts/build/Install-RootCA.ps1",
      "${path.root}/../scripts/build/Install-MongoDB.ps1",
      "${path.root}/../scripts/build/Install-CodeQLBundle.ps1",
      "${path.root}/../scripts/build/Configure-Diagnostics.ps1"
    ]
  }

  # --- Phase 6: Elevated installs & system configuration ---
  provisioner "powershell" {
    elevated_password = "${var.install_password}"
    elevated_user     = "${var.install_user}"
    environment_vars  = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts           = [
      "${path.root}/../scripts/build/Install-PostgreSQL.ps1",
      "${path.root}/../scripts/build/Install-WindowsUpdates.ps1",
      "${path.root}/../scripts/build/Configure-DynamicPort.ps1",
      "${path.root}/../scripts/build/Configure-GDIProcessHandleQuota.ps1",
      "${path.root}/../scripts/build/Configure-Shell.ps1",
      "${path.root}/../scripts/build/Configure-DeveloperMode.ps1",
      "${path.root}/../scripts/build/Install-LLVM.ps1"
    ]
  }

  provisioner "windows-restart" {
    check_registry        = true
    restart_check_command = "powershell -command \"& {if ((-not (Get-Process TiWorker.exe -ErrorAction SilentlyContinue)) -and (-not [System.Environment]::HasShutdownStarted) ) { Write-Output 'Restart complete' }}\""
    restart_timeout       = "30m"
  }

  # --- Phase 7: Post-update tasks, tests, reports ---
  provisioner "powershell" {
    pause_before     = "2m0s"
    environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts          = [
      "${path.root}/../scripts/build/Install-WindowsUpdatesAfterReboot.ps1",
      "${path.root}/../scripts/build/Invoke-Cleanup.ps1",
      "${path.root}/../scripts/tests/RunAll-Tests.ps1"
    ]
  }

  provisioner "powershell" {
    inline = ["if (-not (Test-Path ${var.image_folder}\\tests\\testResults.xml)) { throw '${var.image_folder}\\tests\\testResults.xml not found' }"]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_FOLDER=${var.image_folder}"]
    inline           = ["pwsh -File '${var.image_folder}\\SoftwareReport\\Generate-SoftwareReport.ps1'"]
  }

  provisioner "powershell" {
    inline = ["if (-not (Test-Path C:\\software-report.md)) { throw 'C:\\software-report.md not found' }", "if (-not (Test-Path C:\\software-report.json)) { throw 'C:\\software-report.json not found' }"]
  }

  provisioner "file" {
    destination = "${path.root}/../Windows2025-Readme.md"
    direction   = "download"
    source      = "C:\\software-report.md"
  }

  provisioner "file" {
    destination = "${path.root}/../software-report.json"
    direction   = "download"
    source      = "C:\\software-report.json"
  }

  # --- Phase 8: Final user/system configuration ---
  provisioner "powershell" {
    environment_vars = ["INSTALL_USER=${var.install_user}"]
    scripts          = [
      "${path.root}/../scripts/build/Install-NativeImages.ps1",
      "${path.root}/../scripts/build/Configure-System.ps1",
      "${path.root}/../scripts/build/Configure-User.ps1",
      "${path.root}/../scripts/build/Post-Build-Validation.ps1"
    ]
    skip_clean       = true
  }

  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

  # --- Phase 9: Sysprep / Generalize ---
  provisioner "powershell" {
    inline = [
      "if( Test-Path $env:SystemRoot\\System32\\Sysprep\\unattend.xml ){ rm $env:SystemRoot\\System32\\Sysprep\\unattend.xml -Force}",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /mode:vm /quiet /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10 } else { break } }"
    ]
  }

  # Cleanup (Panther logs)
  provisioner "powershell" {
    inline = ["Remove-Item C:\\Windows\\Panther -Recurse -Force -ErrorAction SilentlyContinue; exit 0"]
  }
}
