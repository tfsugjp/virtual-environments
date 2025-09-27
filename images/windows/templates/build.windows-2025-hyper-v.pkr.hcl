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

  # Minimal subset of provisioning from Azure build retained initially.
  provisioner "powershell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_OS=${var.image_os}", "AGENT_TOOLSDIRECTORY=${var.agent_tools_directory}", "IMAGEDATA_FILE=${var.imagedata_file}", "IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    execution_policy = "unrestricted"
    scripts          = [
      "${path.root}/../scripts/build/Configure-WindowsDefender.ps1",
      "${path.root}/../scripts/build/Configure-PowerShell.ps1",
      "${path.root}/../scripts/build/Install-Chocolatey.ps1",
      "${path.root}/../scripts/build/Configure-BaseImage.ps1",
      "${path.root}/../scripts/build/Configure-ImageDataFile.ps1",
      "${path.root}/../scripts/build/Configure-SystemEnvironment.ps1"
    ]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts          = [
      "${path.root}/../scripts/build/Install-Docker.ps1",
      "${path.root}/../scripts/build/Install-DockerCompose.ps1",
      "${path.root}/../scripts/build/Install-PowershellCore.ps1",
      "${path.root}/../scripts/build/Install-Runner.ps1"
    ]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_FOLDER=${var.image_folder}", "TEMP_DIR=${var.temp_dir}"]
    scripts          = [
      "${path.root}/../scripts/build/Install-Toolset.ps1",
      "${path.root}/../scripts/build/Configure-Toolset.ps1",
      "${path.root}/../scripts/build/Install-NodeJS.ps1",
      "${path.root}/../scripts/build/Install-Git.ps1",
      "${path.root}/../scripts/build/Install-GitHub-CLI.ps1",
      "${path.root}/../scripts/build/Install-Rust.ps1"
    ]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_FOLDER=${var.image_folder}"]
    inline           = ["pwsh -File '${var.image_folder}\\SoftwareReport\\Generate-SoftwareReport.ps1'"]
  }

  provisioner "powershell" {
    inline = [
      "Remove-Item C:\\Windows\\Panther -Recurse -Force -ErrorAction SilentlyContinue; exit 0"
    ]
  }
}
