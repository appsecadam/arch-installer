#!/bin/sh

echo "root:password" | chpasswd
ln -sf "/usr/share/zoneinfo/America/Los_Angeles" /etc/localtime
hwclock --systohc

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
locale-gen

hostname="tetsujin"
echo "$hostname" > /etc/hostname
printf "127.0.1.1\t%s.localdomain\t%s" "$hostname" "$hostname" >> /etc/hosts

pacman --noconfirm --needed -S networkmanager
pacman -Sy --noconfirm efibootmgr
partuuid=$(lsblk -o path,partuuid | grep "/dev/sda3" | awk '{print $2}')
efibootmgr --disk "/dev/sda1" --part 1 --create --label "Arch Linux" --loader /vmlinuz-linux --unicode \
    "root=PARTUUID=$partuuid rw initrd=\intel-ucode.img initrd=\initramfs-linux.img" --verbose
exit