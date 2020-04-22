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

pacman -Sy --noconfirm --needed networkmanager efibootmgr grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="archlinux" && grub-mkconfig -o /boot/grub/grub.cfg
exit