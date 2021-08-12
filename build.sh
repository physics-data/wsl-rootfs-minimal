#!/bin/bash

set -e

ROOTFS=./rootfs
USERNAME=debian

EXTRA=$(awk '{print $1}' packages.txt | paste -s -d, -)
EXCLUDED=$(awk '{print $1}' excluded.txt | paste -s -d, -)

echo "Extra packages: $EXTRA"
echo "Excluded packages: $EXCLUDED"

rm -rf "$ROOTFS"

debootstrap --include=$EXTRA --exclude=$EXCLUDED bullseye "$ROOTFS"

in-root(){
    chroot "$ROOTFS" "$@"
}

as-user(){
    chroot "$ROOTFS" sudo -H -u "$USERNAME" "$@"
}

in-root-put() {
    in-root tee "$1" > /dev/null
}

# generate config files
in-root-put /etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-security main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-updates main contrib non-free
EOF

in-root-put /etc/wsl.conf << EOF
[user]
default=debian
EOF

# bootstrap user
in-root useradd -m -s /bin/bash $USERNAME
in-root usermod -G sudo -a $USERNAME
echo "$USERNAME:$USERNAME" | in-root chpasswd
as-user python3 -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
cat requirements.txt | as-user python3 -m pip install --user -r /dev/stdin
echo 'export PATH="$PATH:$HOME/.local/bin"' | as-user cat >> /home/$USER/.bashrc

# clean cache
in-root rm -rf ./rootfs/var/cache/*

# build image
tar -cf ./rootfs.tar -C ./rootfs .
sha256sum rootfs.tar > rootfs.tar.sha256
zip -9 rootfs.tar.zip rootfs.tar
