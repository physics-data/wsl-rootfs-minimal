#!/bin/bash

set -e

EXTRA=$(awk '{print $1}' packages.txt | paste -s -d, -)
EXCLUDED=$(awk '{print $1}' excluded.txt | paste -s -d, -)

echo "Extra packages: $EXTRA"
echo "Excluded packages: $EXCLUDED"

rm -rf ./rootfs

debootstrap --include=$EXTRA --exclude=$EXCLUDED bullseye ./rootfs

cat > ./rootfs/etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-backports main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-security main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian bullseye-updates main contrib non-free
EOF

cat >> ./rootfs/root/.bashrc << EOF
GATEWAY=\$(ip r | grep "^default" | awk '{ print $3 }')
export DISPLAY=\$GATEWAY:0
EOF

chroot ./rootfs << EOF
useradd -m -s /bin/bash physics-data
usermod -G sudo -a physics-data

echo "physics-data:deadly-solar-laser" | chpasswd
pip3 install wheel matplotlib h5py pandas scipy numpy pillow
EOF

rm -rf ./rootfs/var/cache/*

tar -cf ./rootfs.tar -C ./rootfs .
sha256sum rootfs.tar > rootfs.tar.sha256
zip -9 rootfs.tar.zip rootfs.tar
