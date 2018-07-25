# Start VM with
# VirtualBox: vagrant up --provider virtualbox
# VMWare: vagrant up --provider vmware_workstation

Vagrant.configure("2") do |config|
  config.vm.box = "bento/fedora-27"
  config.ssh.insert_key = false
  
  config.vm.provider "vmware_workstation" do |v|
    v.gui = true
    #v.vmx["memsize"]  = 16384
    v.vmx["memsize"]  = 4096
    v.vmx["numvcpus"]  = 8
    v.vmx["vhv.enable"]  = "TRUE"
    v.linked_clone = false
  end
  
  config.vm.provider "virtualbox" do |v|
    v.gui = true
    #v.memory = 16384
    v.memory = 4096
    v.cpus = 8
    v.customize ["modifyvm", :id, "--vram", "96"]
    v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    v.customize ["modifyvm", :id, "--accelerate3d", "on"]
  end

  config.vm.provision :shell, inline: <<-SHELL

    printf "Machine created.\n"
    
    printf "\nVariant 1: Virtual Box with or without proxy\n"
    printf "1. If a proxy is used, configure the proxy in ansible/defaults/main.yaml\n"
    printf "2. If not, set use_proxy_for_bootstrap = false and proxy.activate = false in ansible/defaults/main.yaml\n"
    printf "3. Please use 'vagrant ssh', login with vagrant/vagrant and execute '/vagrant/provision.sh'.\n\n"

    printf "\nVariant 2: VMWare without proxy\n"
    printf "(dnf cannot use proxy servers with NTLM)\n"
    printf "1. Set use_proxy_for_bootstrap = false and proxy.activate = false in ansible/defaults/main.yaml\n"
    printf "2. If you need the transparent proxy later, set proxy.install = true in ansible/defaults/main.yaml.\n"
    printf "3. Please use 'vagrant ssh', login with vagrant/vagrant and execute '/vagrant/provision.sh'.\n\n"
    printf "4. If you need the transparent proxy, execute the following after the installation:\n"
    printf "   sudo systemctl enable squid && systemctl start squid\n"
    
    printf "\nVariant 3: volume mount is not possible or you have a vm not provisioned with Vagrant\n"
    printf "Execute the following with root or a user with sudo privileges (if proxy is required export https_proxy before)\n"
    printf "curl -L https://raw.githubusercontent.com/sbueringer/workstation/master/provision.sh -o provision.sh && sudo chmod +x provision.sh && ./provision.sh\n\n"
  SHELL

  # Enable to mount a host directory
  # config.vm.synced_folder "<local path>", "<mount path>"
end
