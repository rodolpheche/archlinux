packer {
  required_plugins {
    libvirt = {
      version = ">= 0.5.0"
      source  = "github.com/thomasklein94/libvirt"
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

source "libvirt" "archlinux-liveiso" {
  libvirt_uri = "qemu:///system"
  vcpu   = 4
  memory = 4096
  loader_path = "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
  cpu_mode = "host-passthrough"
  boot_devices = [ "cdrom" ]
  shutdown_mode = "acpi"
  shutdown_timeout = "30s"
  network_address_source = "agent"
  communicator_interface = "factory"

  # https://developer.hashicorp.com/packer/plugins/builders/libvirt#communicators-and-network-interfaces
  communicator {
    communicator         = "ssh"
    ssh_username         = "arch"
    ssh_private_key_file = data.sshkey.install.private_key_path
  }

  network_interface {
    alias  = "factory"
    type   = "bridge"
    bridge = "virbr1"
  }

  volume {
    name        = "archlinux-${uuidv4()}.iso"
    pool        = "isos"
    bus         = "sata"
    device      = "cdrom"
    format      = "raw"

    source {
      type      = "external"
      urls      = ["https://mir.archlinux.fr/iso/latest/archlinux-x86_64.iso"]
      checksum  = "file:https://mir.archlinux.fr/iso/latest/sha256sums.txt"
    }
  }

  volume {
    name        = "cloudinit-${uuidv4()}.iso"
    pool        = "isos"
    bus         = "sata"
    source {
      type = "cloud-init"
      user_data = format("#cloud-config\n%s", jsonencode({
        ssh_authorized_keys = [
          data.sshkey.install.public_key,
        ]
      }))

    }
  }

  volume {
    name        = "archlinux-${formatdate("YYYYMMDD-hhmmssZZZ", timestamp())}"
    alias       = "artifact" // prevents libvirt builder from deleting the volume at the end of the build
    bus         = "virtio"
    pool        = "images"
    capacity    = "50G"
    format      = "qcow2"
  }
}

build {
  sources = ["source.libvirt.archlinux-liveiso"]

  provisioner "ansible" {
    playbook_file = "install.yml"
    host_alias = "libvirt"
    inventory_directory = "inventory"
    user = "arch"
    ssh_authorized_key_file = "/etc/ssh/ssh_host_rsa_key.pub" # just to disable ansible_ssh_private_key_file var default injection
    ansible_env_vars = [
      "ANSIBLE_FORCE_COLOR=1"
    ]
    extra_arguments = [
      "-D",
      "-e ansible_ssh_private_key_file=${data.sshkey.install.private_key_path}",
      "-e ansible_host=${build.Host}",
      "-e ansible_port=${build.Port}"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}
