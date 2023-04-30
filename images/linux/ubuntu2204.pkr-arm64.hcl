
variable "allowed_inbound_ip_addresses" {
  type    = list(string)
  default = []
}

variable "azure_tag" {
  type    = map(string)
  default = {}
}

variable "build_resource_group_name" {
  type    = string
  default = "${env("BUILD_RESOURCE_GROUP_NAME")}"
}

variable "capture_name_prefix" {
  type    = string
  default = "packer"
}

variable "client_id" {
  type    = string
  default = "${env("ARM_CLIENT_ID")}"
}

variable "client_secret" {
  type      = string
  default   = "${env("ARM_CLIENT_SECRET")}"
  sensitive = true
}

variable "client_cert_path" {
  type      = string
  default   = "${env("ARM_CLIENT_CERT_PATH")}"
}

variable "commit_url" {
  type      = string
  default   = ""
}

variable "dockerhub_login" {
  type    = string
  default = "${env("DOCKERHUB_LOGIN")}"
}

variable "dockerhub_password" {
  type    = string
  default = "${env("DOCKERHUB_PASSWORD")}"
}

variable "helper_script_folder" {
  type    = string
  default = "/imagegeneration/helpers"
}

variable "image_folder" {
  type    = string
  default = "/imagegeneration"
}

variable "image_os" {
  type    = string
  default = "ubuntu22"
}

variable "image_version" {
  type    = string
  default = "dev"
}

variable "imagedata_file" {
  type    = string
  default = "/imagegeneration/imagedata.json"
}

variable "installer_script_folder" {
  type    = string
  default = "/imagegeneration/installers"
}

variable "install_password" {
  type  = string
  default = ""
}

variable "location" {
  type    = string
  default = "${env("ARM_RESOURCE_LOCATION")}"
}

variable "private_virtual_network_with_public_ip" {
  type    = bool
  default = false
}

variable "resource_group" {
  type    = string
  default = "${env("ARM_RESOURCE_GROUP")}"
}

variable "run_validation_diskspace" {
  type    = bool
  default = false
}

variable "storage_account" {
  type    = string
  default = "${env("ARM_STORAGE_ACCOUNT")}"
}

variable "subscription_id" {
  type    = string
  default = "${env("ARM_SUBSCRIPTION_ID")}"
}

variable "temp_resource_group_name" {
  type    = string
  default = "${env("TEMP_RESOURCE_GROUP_NAME")}"
}

variable "tenant_id" {
  type    = string
  default = "${env("ARM_TENANT_ID")}"
}

variable "virtual_network_name" {
  type    = string
  default = "${env("VNET_NAME")}"
}

variable "virtual_network_resource_group_name" {
  type    = string
  default = "${env("VNET_RESOURCE_GROUP")}"
}

variable "virtual_network_subnet_name" {
  type    = string
  default = "${env("VNET_SUBNET")}"
}

variable "vm_size" {
  type    = string
  default = "Standard_D4s_v4"
}

source "azure-arm" "build_vhd" {
  allowed_inbound_ip_addresses           = "${var.allowed_inbound_ip_addresses}"
  build_resource_group_name              = "${var.build_resource_group_name}"
  capture_container_name                 = "images"
  capture_name_prefix                    = "${var.capture_name_prefix}"
  client_id                              = "${var.client_id}"
  client_secret                          = "${var.client_secret}"
  client_cert_path                       = "${var.client_cert_path}"
  image_offer                            = "0001-com-ubuntu-server-jammy"
  image_publisher                        = "canonical"
  image_sku                              = "22_04-lts-arm64"
  location                               = "${var.location}"
  os_disk_size_gb                        = "86"
  os_type                                = "Linux"
  private_virtual_network_with_public_ip = "${var.private_virtual_network_with_public_ip}"
  resource_group_name                    = "${var.resource_group}"
  storage_account                        = "${var.storage_account}"
  subscription_id                        = "${var.subscription_id}"
  temp_resource_group_name               = "${var.temp_resource_group_name}"
  tenant_id                              = "${var.tenant_id}"
  virtual_network_name                   = "${var.virtual_network_name}"
  virtual_network_resource_group_name    = "${var.virtual_network_resource_group_name}"
  virtual_network_subnet_name            = "${var.virtual_network_subnet_name}"
  vm_size                                = "${var.vm_size}"

  dynamic "azure_tag" {
    for_each = var.azure_tag
    content {
      name = azure_tag.key
      value = azure_tag.value
    }
  }
}

build {
  sources = ["source.azure-arm.build_vhd"]

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mkdir ${var.image_folder}", "chmod 777 ${var.image_folder}"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/apt-mock.sh"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/base/repos.sh"]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script           = "${path.root}/scripts/base/apt.sh"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/limits.sh"
  }

  provisioner "file" {
    destination = "${var.helper_script_folder}"
    source      = "${path.root}/scripts/helpers"
  }

  provisioner "file" {
    destination = "${var.installer_script_folder}"
    source      = "${path.root}/scripts/installers"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/post-generation"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/scripts/test_arm64"
  }

  provisioner "file" {
    destination = "${var.image_folder}"
    source      = "${path.root}/scripts/SoftwareReport"
  }

  provisioner "file" {
    destination = "${var.image_folder}/SoftwareReport/"
    source      = "${path.root}/../../helpers/software-report-base"
  }

  provisioner "file" {
    destination = "${var.installer_script_folder}/toolset.json"
    source      = "${path.root}/toolsets/toolset-2204-arm.json"
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGEDATA_FILE=${var.imagedata_file}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/preimagedata.sh"]
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_OS=${var.image_os}", "HELPER_SCRIPTS=${var.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/configure-environment.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/complete-snap-setup.sh", "${path.root}/scripts/installers_arm64/powershellcore.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/Install-PowerShellModules.ps1", "${path.root}/scripts/installers_arm64/Install-AzureModules.ps1"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "DOCKERHUB_LOGIN=${var.dockerhub_login}", "DOCKERHUB_PASSWORD=${var.dockerhub_password}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/docker-compose.sh", "${path.root}/scripts/installers_arm64/docker-moby.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "DEBIAN_FRONTEND=noninteractive"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = [
                        "${path.root}/scripts/installers_arm64/azcopy.sh",
                        "${path.root}/scripts/installers_arm64/azure-cli.sh",
                        "${path.root}/scripts/installers_arm64/azure-devops-cli.sh",
                        "${path.root}/scripts/installers_arm64/basic.sh",
                        "${path.root}/scripts/installers_arm64/bicep.sh",
                        "${path.root}/scripts/installers_arm64/aliyun-cli.sh",
                        "${path.root}/scripts/installers_arm64/apache.sh",
                        "${path.root}/scripts/installers_arm64/clang.sh",
                        "${path.root}/scripts/installers_arm64/swift.sh",
                        "${path.root}/scripts/installers_arm64/cmake.sh",
                        "${path.root}/scripts/installers_arm64/containers.sh",
                        "${path.root}/scripts/installers_arm64/dotnetcore-sdk.sh",
                        "${path.root}/scripts/installers_arm64/gcc.sh",
                        "${path.root}/scripts/installers_arm64/git.sh",
                        "${path.root}/scripts/installers_arm64/github-cli.sh",
                        "${path.root}/scripts/installers_arm64/haskell.sh",
                        "${path.root}/scripts/installers_arm64/heroku.sh",
                        "${path.root}/scripts/installers_arm64/java-tools.sh",
                        "${path.root}/scripts/installers_arm64/kubernetes-tools.sh",
                        "${path.root}/scripts/installers_arm64/oc.sh",
                        "${path.root}/scripts/installers_arm64/leiningen.sh",
                        "${path.root}/scripts/installers_arm64/miniconda.sh",
                        "${path.root}/scripts/installers_arm64/mono.sh",
                        "${path.root}/scripts/installers_arm64/kotlin.sh",
                        "${path.root}/scripts/installers_arm64/mysql.sh",
                        "${path.root}/scripts/installers_arm64/mssql-cmd-tools.sh",
                        "${path.root}/scripts/installers_arm64/sqlpackage.sh",
                        "${path.root}/scripts/installers_arm64/nginx.sh",
                        "${path.root}/scripts/installers_arm64/nvm.sh",
                        "${path.root}/scripts/installers_arm64/nodejs.sh",
                        "${path.root}/scripts/installers_arm64/bazel.sh",
                        "${path.root}/scripts/installers_arm64/oras-cli.sh",
                        "${path.root}/scripts/installers_arm64/php.sh",
                        "${path.root}/scripts/installers_arm64/postgresql.sh",
                        "${path.root}/scripts/installers_arm64/pulumi.sh",
                        "${path.root}/scripts/installers_arm64/ruby.sh",
                        "${path.root}/scripts/installers_arm64/r.sh",
                        "${path.root}/scripts/installers_arm64/rust.sh",
                        "${path.root}/scripts/installers_arm64/julia.sh",
                        "${path.root}/scripts/installers_arm64/sbt.sh",
                        "${path.root}/scripts/installers_arm64/selenium.sh",
                        "${path.root}/scripts/installers_arm64/terraform.sh",
                        "${path.root}/scripts/installers_arm64/packer.sh",
                        "${path.root}/scripts/installers_arm64/vcpkg.sh",
                        "${path.root}/scripts/installers_arm64/dpkg-config.sh",
                        "${path.root}/scripts/installers_arm64/yq.sh",
                        "${path.root}/scripts/installers_arm64/pypy.sh",
                        "${path.root}/scripts/installers_arm64/python.sh",
                        "${path.root}/scripts/installers_arm64/graalvm.sh"
                        ]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} pwsh -f {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/Install-Toolset.ps1", "${path.root}/scripts/installers_arm64/Configure-Toolset.ps1"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/pipx-packages.sh"]
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPTS=${var.helper_script_folder}", "DEBIAN_FRONTEND=noninteractive", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    execute_command  = "/bin/sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/homebrew.sh"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/snap.sh"
  }

  provisioner "shell" {
    execute_command   = "/bin/sh -c '{{ .Vars }} {{ .Path }}'"
    expect_disconnect = true
    scripts           = ["${path.root}/scripts/base/reboot.sh"]
  }

  provisioner "shell" {
    execute_command     = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    pause_before        = "1m0s"
    scripts             = ["${path.root}/scripts/installers_arm64/cleanup.sh"]
    start_retry_timeout = "10m"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "${path.root}/scripts/base/apt-mock-remove.sh"
  }

  provisioner "shell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}"]
    inline           = ["pwsh -File ${var.image_folder}/SoftwareReport/SoftwareReport.Generator.ps1 -OutputDirectory ${var.image_folder}", "pwsh -File ${var.image_folder}/tests/RunAll-Tests.ps1 -OutputDirectory ${var.image_folder}"]
  }

  provisioner "file" {
    destination = "${path.root}/Ubuntu2204-Readme.md"
    direction   = "download"
    source      = "${var.image_folder}/software-report.md"
  }

  provisioner "file" {
    destination = "${path.root}/software-report.json"
    direction   = "download"
    source      = "${var.image_folder}/software-report.json"
  }

  provisioner "shell" {
    environment_vars = ["HELPER_SCRIPT_FOLDER=${var.helper_script_folder}", "INSTALLER_SCRIPT_FOLDER=${var.installer_script_folder}", "IMAGE_FOLDER=${var.image_folder}"]
    execute_command  = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["${path.root}/scripts/installers_arm64/post-deployment.sh"]
  }

  provisioner "shell" {
    environment_vars = ["RUN_VALIDATION=${var.run_validation_diskspace}"]
    scripts          = ["${path.root}/scripts/installers_arm64/validate-disk-space.sh"]
  }

  provisioner "file" {
    destination = "/tmp/"
    source      = "${path.root}/config/ubuntu2204.conf"
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["mkdir -p /etc/vsts", "cp /tmp/ubuntu2204.conf /etc/vsts/machine_instance.conf"]
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    inline          = ["sleep 30", "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"]
  }

}
