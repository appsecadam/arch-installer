#!/bin/sh

# Arch Linux Installer by @canihax

ping -c1 google.com >/dev/null 2>&1 || { echo "error no internet connection"; exit; }
hostname="tetsujin"
timezone="America/Los_Angeles"
disk="/dev/sda"
efi="/dev/sda1"
swap="/dev/sda2"
root="/dev/sda3"
swap_space="3GiB"
timedatectl set-ntp true > /dev/null
yes | parted "$disk" mklabel gpt > /dev/null
parted "$disk" mkpart primary fat32 1MiB 261MiB > /dev/null
parted "$disk" mkpart primary linux-swap 261MiB "$swap_space" > /dev/null
parted "$disk" mkpart primary ext4 "$swap_space" 100% > /dev/null
mkfs.fat -F32 "$efi"
mkswap "$swap"
swapon "$swap"
yes | mkfs.ext4 "$root"
mount "$root" /mnt
mkdir -p /mnt/boot
mount "$efi" /mnt/boot
curl -s "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&use_mirror_status=on" \
 sed s/#Server/Server/g > /etc/pacman.d/mirrorlist 
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
echo "root:password" | chpasswd
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
hwclock --systohc

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

echo "$hostname" > /etc/hostname
printf "127.0.1.1\t%s.localdomain\t%s" "$hostname" "$hostname" >> /etc/hosts

pacman --noconfirm --needed -S networkmanager
systemctl enable NetworkManager
systemctl start NetworkManager

partuuid=$(lsblk -o path,partuuid | grep "$root" | awk '{print $2}')
efibootmgr --disk "$disk" --part 1 --create --label "Arch Linux" --loader /vmlinuz-linux --unicode \
    "root=PARTUUID=$partuuid rw initrd=\intel-ucode.img initrd=\initramfs-linux.img" --verbose
