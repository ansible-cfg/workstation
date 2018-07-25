# Install Nvidia drivers

sudo dnf update -y

reboot

https://www.if-not-true-then-false.com/2015/fedora-nvidia-guide/#nvidia-install

## Fedora 27/26/25/24/23/22 ##
dnf install kernel-devel kernel-headers gcc dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig


echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf

Append "rd.driver.blacklist=nouveau" to GRUB_CMDLINE_LINUX

## BIOS ##
grub2-mkconfig -o /boot/grub2/grub.cfg

## Fedora 27/26/25/24/23/22 ##
dnf remove xorg-x11-drv-nouveau

## Backup old initramfs nouveau image ##
mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r)-nouveau.img
 
## Create new initramfs image ##
dracut /boot/initramfs-$(uname -r).img $(uname -r)

systemctl set-default multi-user.target

reboot

sudo su 

run installer

/home/fedora/NVIDIA-Linux-*.run

systemctl set-default graphical.target

reboot

dnf install -y vdpauinfo libva-vdpau-driver libva-utils

# VLC

sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y vlc

# Steam

sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y steam
