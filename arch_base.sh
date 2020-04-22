#!/bin/sh

# Arch Linux Installer by @canihax

ping -c1 google.com >/dev/null 2>&1 || { echo "error no internet connection"; exit; }
disk="/dev/sda"
efi="/dev/sda1"
swap="/dev/sda2"
root="/dev/sda3"
swap_space="3GiB"
timedatectl set-ntp true
yes | parted "$disk" mklabel gpt
yes | parted "$disk" mkpart primary fat32 1MiB 261MiB
yes | parted "$disk" mkpart primary linux-swap 261MiB "$swap_space"
yes | parted "$disk" mkpart primary ext4 "$swap_space" 100%
mkfs.fat -F32 "$efi"
mkswap "$swap"
swapon "$swap"
yes | mkfs.ext4 "$root"
mount "$root" /mnt
mkdir -p /mnt/boot
mount "$efi" /mnt/boot
curl -s "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=off" \
| sed s/#Server/Server/g > /etc/pacman.d/mirrorlist 
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab 
mv chroot.sh > /mnt/chroot.sh
arch-chroot /mnt sh chroot.sh
shutdown -r +1
