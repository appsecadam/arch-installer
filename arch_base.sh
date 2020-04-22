#!/bin/sh

# Arch Linux Installer by @canihax

calculate_swap() {
    total_memory=$(awk 'NR==1 {print int($2 / 1000000)-1}' /proc/meminfo)
    [ "$total_memory" -le 2 ] && echo 1
    [ "$total_memory" -gt 2 ] && [ "$total_memory" -le 6 ] && echo 2
    [ "$total_memory" -gt 6 ] && [ "$total_memory" -le 12 ] && echo 3
    [ "$total_memory" -gt 12 ] && [ "$total_memory" -le 16 ] && echo 4
    [ "$total_memory" -gt 16 ] && [ "$total_memory" -le 24 ] && echo 5
    [ "$total_memory" -gt 24 ] && [ "$total_memory" -le 32 ] && echo 6
    [ "$total_memory" -gt 32 ] && [ "$total_memory" -le 64 ] && echo 8
    [ "$total_memory" -gt 64 ] && [ "$total_memory" -le 128 ] && echo 11
}

ping -c1 google.com >/dev/null 2>&1 || { echo "error no internet connection"; exit; }
hostname="tetsujin"
timezone=$(cat <<EOF | tzselect
2
49
21
1
EOF
)
timedatectl set-ntp true
swap_space="$(calculate_swap)G"
disk=$(lsblk -o path,type | grep disk | awk '{print $1}')
cat <<EOF | fdisk "$disk"
g
n
1

+260M
t
1
n
2

+$swap_space
t
2
19
n
3


w
EOF
efi=$(lsblk -o path,type | grep part | awk 'NR==1 {print $1}')
swap=$(lsblk -o path,type | grep part | awk 'NR==2 {print $1}')
root=$(lsblk -o path,type | grep part | awk 'NR==2 {print $1}')
mkfs.fat -F32 "$efi"
mkswap "$swap"
swapon "$swap"
yes | mkfs.ext4 "$root"
mount "$root" /mnt
mkdir -p /mnt/boot
mount "$efi" /mnt/boot

curl -s "https://www.archlinux.org/mirrorlist/?country=US&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" \
    | sed s/#Server/Server/g > /etc/pacman.d/mirrorlist 
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
passwd
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
