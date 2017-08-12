#[option] remote
#passwd && systemctl start sshd
#[option] wipefs
# wipefs -a /dev/sda
#[1-gpt/efi]
#parted /dev/sda -s -a optimal mklabel gpt mkpart primary 300m 100% mkpart primary 1m 300m && \
#           mkfs.ext4 /dev/sda1 && mount /dev/sda1 /mnt && mkdir -p /mnt/boot/EFI && \
#           mkfs.fat -F32 /dev/sda2 && mount /dev/sda2 /mnt/boot/EFI
#[1-mbr/bios]
#parted /dev/sda -s -a optimal mklabel msdos mkpart primary 1m 100% && \
#           mkfs.ext4 /dev/sda1 && mount /dev/sda1 /mnt
#[2-pacman]
sed -i -e '/163/! s/^Server/#Server/' /etc/pacman.d/mirrorlist && pacstrap /mnt base
#[2-rsync]
#rsync -azAXH --delete --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/lost+found"} root@10.0.0.1:/ /mnt
#[3-config]
genfstab -U -p /mnt > /mnt/etc/fstab
arch-chroot /mnt
mkinitcpio -p linux --noconfirm

echo LANG=zh_CN.UTF-8 > /etc/locale.conf && echo KEYMAP=us > /etc/vconsole.conf && echo arch > /etc/hostname && \
          sed -i -e 's/^#\(en_US.UTF-8\|zh_CN.UTF-8\|zh_CN.GBK\)/\1/' /etc/locale.gen && locale-gen && \
          ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#[4-efi]
#pacman -S grub efibootmgr && \
#           grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=grub && \
#           grub-mkconfig -o /boot/grub/grub.cfg
#[4-bios]
pacman -S grub os-prober && \
           grub-install --target=i386-pc /dev/sda && \
           grub-mkconfig -o /boot/grub/grub.cfg
		       
#[option] tools
pacman -S base-devel net-tools vim emacs git tmux cscope ctags htop nmap tcpdump socat tree curl wget wput rsync sudo zsh dhcpcd ntp openssh iw wpa_supplicant dialog && \
           sed -i -e 's/^#\s*\(%wheel.*NOPASSWD.*\)/\1/' /etc/sudoers && \
           sed -i -e 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/sshd_config && \
           sed -i -e 's/^#KillUserProcesses.*/KillUserProcesses=no/' /etc/systemd/logind.conf && \
           chsh -s /usr/bin/zsh && \
           systemctl enable dhcpcd ntpd sshd && \
           wifi-menu   
#[option] kde
pacman -S xorg plasma konsole dolphin fcitx wqy-zenhei wqy-microhei adobe-source-han-sans-cn-fonts && \
           sed -i -e 's/^Current=/Current=breeze/' /etc/sddm.conf && \
           echo -e 'export GTK_IM_MODULE=fcitx\nexport QT_IM_MODULE=fcitx\nexport XMODIFIERS="@im=fcitx"' > ~/.xprofile && \
           systemctl enable sddm NetworkManager
#[option] swap
fallocate -l 4G /swap && chmod 600 /swap && mkswap /swap && swapon /swap && echo '/swap none swap defaults 0 0' >> /etc/fstab
#[option] user
useradd -m -G wheel -s /usr/bin/zsh -p asas tomic
#[option] samba
pacman -S samba && systemctl enable smbd && pdbedit -a -u tomic
passwd && exit
umount -R /mnt && reboot