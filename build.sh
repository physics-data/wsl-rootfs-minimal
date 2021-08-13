#!/bin/bash

set -e

ROOTFS=./rootfs
USERNAME=debian
SUITE=bullseye

BUILD_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/debian"
EXTRA_PKGS=$(awk '{print $1}' packages.txt | paste -s -d " " -)
EXCLUDED_PKGS=$(awk '{print $1}' excluded.txt | paste -s -d, -)
PYPI_PKGS=$(awk '{print $1}' requirements.txt | paste -s -d " " -)

echo "Extra packages: $EXTRA_PKGS"
echo "Excluded packages: $EXCLUDED_PKGS"

sudo rm -rf "$ROOTFS"

sudo debootstrap --include=gnupg,locales,tzdata --exclude=$EXCLUDED_PKGS --components=main,contrib,non-free "$SUITE" "$ROOTFS" "$BUILD_MIRROR"

in-root(){
    sudo chroot "$ROOTFS" "$@"
}

as-user(){
    sudo chroot "$ROOTFS" sudo -H -u "$USERNAME" "$@"
}

in-root-put() {
    in-root tee "$1" > /dev/null
}

# bind mount in chroot
for i in sys proc; do
    sudo mount --bind /$i "$ROOTFS/$i"
done

# pre-config
in-root debconf-set-selections <<EOF
locales	locales/locales_to_be_generated	multiselect	en_US.UTF-8 UTF-8, zh_CN.UTF-8 UTF-8
locales	locales/default_environment_locale	select	en_US.UTF-8
tzdata	tzdata/Areas	select	Asia
tzdata	tzdata/Zones/Asia	select	Shanghai
EOF

in-root rm -f "/etc/locale.gen"
in-root ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
in-root dpkg-reconfigure --frontend noninteractive locales < /dev/null
in-root dpkg-reconfigure --frontend noninteractive tzdata < /dev/null

# apt config
in-root-put /etc/apt/sources.list << EOF
deb $BUILD_MIRROR $SUITE main contrib non-free
deb $BUILD_MIRROR $SUITE-backports main contrib non-free
deb $BUILD_MIRROR-security $SUITE-security main
deb $BUILD_MIRROR $SUITE-updates main contrib non-free
EOF

# install extra packages
in-root apt-get update
in-root apt-get --no-install-recommends -y install $EXTRA_PKGS
in-root apt-get -y dist-upgrade

# WSL config
in-root-put /etc/wsl.conf << EOF
[user]
default=debian
EOF

in-root-put /etc/hostname << EOF
debian
EOF

echo "127.0.1.1 debian" | in-root tee -a /etc/hosts > /dev/null

# bootstrap user
in-root useradd -m -s /bin/bash $USERNAME
in-root usermod -G sudo -a $USERNAME
echo "$USERNAME:$USERNAME" | in-root chpasswd
as-user python3 -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
as-user python3 -m pip install --user $PYPI_PKGS

# clean up
in-root apt-get clean
in-root apt-get check
in-root rm -rf var/cache/*
sudo umount $ROOTFS/proc $ROOTFS/sys

# build image
echo "Done bootstrapping system"
sudo tar -cf ./rootfs.tar -C $ROOTFS .
sha256sum rootfs.tar | tee rootfs.tar.sha256
zip -9 rootfs.tar.zip rootfs.tar

