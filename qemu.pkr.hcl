packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
    sshkey = {
      version = ">= 1.0.1"
      source = "github.com/ivoronin/sshkey"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

data "sshkey" "install" {
}

source "qemu" "archlinux-liveiso" {
  headless = "true"
  vm_name = "archlinux.qcow"
  cpus = 4
  memory = 4096
  disk_size = "50000"
  firmware = "/usr/share/edk2-ovmf/x64/OVMF.fd"
  iso_url = "https://mir.archlinux.fr/iso/latest/archlinux-x86_64.iso"
  iso_checksum = "file:https://mir.archlinux.fr/iso/latest/sha256sums.txt"
  ssh_username = "root"
  ssh_private_key_file = data.sshkey.install.private_key_path
  ssh_wait_timeout = "60m"
  boot_wait = "3s"
  boot_key_interval = "10ms"
  boot_command = [
    "<enter>",
    "<wait60>",
    "echo '${data.sshkey.install.public_key}' > ~/.ssh/authorized_keys",
    "<enter>"
  ]
  shutdown_command = "shutdown -P now"
  output_directory = "dist"
}

build {
  sources = ["source.qemu.archlinux-liveiso"]

  provisioner "ansible" {
    playbook_file = "install.yml"
    host_alias = "qemu"
    inventory_directory = "inventory"
    user = "root"
    # disable private key file packer management
    ssh_authorized_key_file = "/etc/ssh/ssh_host_rsa_key.pub"
    ansible_env_vars = [
      "ANSIBLE_FORCE_COLOR=1"
    ]
    extra_arguments = [
      "-D",
      "-e ansible_ssh_private_key_file=${data.sshkey.install.private_key_path}",
      "-e ansible_port=${build.Port}"
    ]
  }
}
