#!/usr/bin/env bash

if [ "$EUID" -eq 0 ]; then
	echo -n "You probably don't want to run this as sudo/root. Continue anyway? (y/N): "
	read -r ans
	if [[ "$ans" != Y* && "$ans" != y* ]]; then
		exit 1
	fi
fi

user=$(logname)
vm=false

sudo --validate

# Bootstrap configuration

echo -n "Is this a VM? (y/N): "
read -r ans

if [[ "$ans" == Y* || "$ans" == y* ]]; then
	vm=true
fi
echo "VM: $vm"

#
# Arch
#

# Upgrade system
sudo pacman -Syu --noconfirm

# Install packages
sudo pacman -S --noconfirm - < packages/arch.txt

# Install packages for non-VM machines
if ! $vm; then
	sudo pacman -S --noconfirm - < packages/arch_not_vm.txt
fi

# Fetch AUR packages (but don't build or install them)
mkdir -p /home/"$user"/git/AUR
cat ./packages/arch_aur.txt | while read -r package; do
	git -C  /home/"$user"/git/AUR/ clone "$package"
done

# i3 config
mkdir -p /home/"$user"/.config/i3
cp ./conf_files/i3.conf /home/"$user"/.config/i3/config

# i3status config
sudo cp ./conf_files/i3status.conf /etc/i3status.conf
# Set interface name in i3status conf (assume first UP interface is correct)
iface=$(ip link | grep -m 1 "state UP" | cut -f 2 -d ':' | xargs)
sudo sed -i "s/ethernet [a-z0-9]* {/ethernet $iface {/" /etc/i3status.conf
sudo sed -i "s/ethernet [a-z0-9]*\"/ethernet $iface\"/" /etc/i3status.conf
# Set correct hwmon for CPU temperature
hwmon=$(find /sys/devices/platform/coretemp.0/hwmon/ -type d | grep -m 1 -E "hwmon[0-9]" | rev | cut -f 1 -d '/' | rev)
sudo sed -i "s/hwmon1/$hwmon/g" /etc/i3status.conf

# vim config
mkdir -p /home/"$user"/.vim/colors
cp ./conf_files/afterglow.vim /home/"$user"/.vim/colors/
cp ./conf_files/vimrc /home/"$user"/.vimrc

# rofi config
mkdir -p /home/"$user"/.config/rofi
cp ./conf_files/rofi.config /home/"$user"/.config/rofi/config

# stterm
mkdir -p /home/"$user"/git
git -C /home/"$user"/git/ clone https://github.com/Lars-Saetaberget/stterm.git
make -C /home/"$user"/git/stterm/ clean
sudo -E make -C /home/"$user"/git/stterm/ install

# scripts
sudo cp ./scripts/* /usr/local/bin/

# iptables
if sudo iptables -S; then
	sudo iptables -C INPUT -j ACCEPT -m conntrack --ctstate ESTABLISHED,RELATED 2> /dev/null || sudo iptables -A INPUT -j ACCEPT -m conntrack --ctstate ESTABLISHED,RELATED
	sudo iptables -C INPUT -j ACCEPT --src localhost 2> /dev/null || sudo iptables -A INPUT -j ACCEPT --src localhost
	sudo iptables -C INPUT -j ACCEPT --proto icmp 2> /dev/null || sudo iptables -A INPUT -j ACCEPT --proto icmp
	sudo iptables -P INPUT DROP
else
	echo "iptables might not be loaded, you need to reboot before iptables rules can be applied"
fi

# bashrc
cp ./conf_files/bashrc /home/"$user"/.bashrc
cp ./conf_files/bash_codes /home/"$user"/.bash_codes
cp ./conf_files/bash_ps1 /home/"$user"/.bash_ps1
cp ./conf_files/bash_alias /home/"$user"/.bash_alias

# git
cp ./conf_files/git.conf /home/"$user"/.gitconfig

# sysctl
sudo sysctl -w vm.swappiness=1
