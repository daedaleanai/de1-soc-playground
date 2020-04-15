
DE1-SoC Playground
==================

This repository explores system creation with the DE1-SoC from first principles
to the extent possible. While it uses Quartus Prime and various closed software
components provided by it, it aims to avoid any other binary blobs. The
emphasis is on repeatability, control over what is happening, and as much
process transparency as possible.

Setting up Quartus Prime
------------------------

Quartus Prime installs into a single directory. The useful binaries, however,
are scattered throughout its installation tree. Set the PATH environment
variable to the following to make sure that all the Makefiles in this repository
work:

    export PATH=$PATH:/path/to/quartus-prime-lite/19.1/quartus/bin
    export PATH=$PATH:/path/to/quartus-prime-lite/19.1/quartus/sopc_builder/bin
    export PATH=$PATH:/path/to/quartus-prime-lite/19.1/embedded/host_tools/altera/preloadergen/

Furthermore, the Qsys installation seems to be broken by default in version 19.1
in that it cannot find some of the Perl libraries it installs. It is necessary
to set the `PERL5LIB` path manually:

    export PERL5LIB=/path/to/quartus-prime-lite/19.1/quartus/linux64/perl/lib/

Linux on the HPS part of the system
-----------------------------------

The Cyclone V device powering the DE1-SoC is a system on a chip that consists of
two parts - a hard processor system (HPS) and an FPGA. Both parts have disjoint
sets of peripherals connected directly to them. The material in this repository
assumes that the HPS part of the chip will run Linux. Linux and Linux-based
programs will, in turn, drive the communication with the hardware implemented in
the FPGA fabric.

The HPS is powered by a dual-core ARM Cortex-A9 CPU. This system may be
configured in a variety of different ways as far a the pinout, attached DRAM,
PLLs, and active IP blocks are concerned. This configuration is usually
performed by the first stage bootloader before it passes the control over to the
operating system. It is possible to write the code performing this configuration
by hand, but by far the easiest way is to define the system properties in Qsys
and let it generate the relevant source files. Doing this is necessary even when
there is nothing implemented in the FPGA fabric.

### SD Card ###

It is necessary to create a DOS disklabel with at least two partitions: one for
the Linux root filesystem, and one for the bootloader payload. The bootloader
partition needs to start at the 2048th block and needs to have its Id set to a2,
50MB should be more than enough. The details of the Linux partition setup do not
matter much, as long as it is big enough to hold the root file system. Source:
[the RocketBoards wiki][rb1].

    ]==> sudo fdisk /dev/mmcblk0

    Command (m for help): p
    Disk /dev/mmcblk0: 59.49 GiB, 63864569856 bytes, 124735488 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0x100fee9a

    Device         Boot  Start       End   Sectors  Size Id Type
    /dev/mmcblk0p1      104448 124735487 124631040 59.4G 83 Linux
    /dev/mmcblk0p2        2048    104447    102400   50M a2 unknown

    Partition table entries are not in disk order.

### The root filesystem ###

Debian-provided bootstrapping program called `qemu-debootstrap` is the easiest
way to create a new Debian installation for a different architecture. The shell
snippet below shows how to do it in a way compatible with this board. The Debian
`armhf` port supports a 32-bit ARMv7 CPUs with hardware floating-point support.

    ]==> mkfs.ext4 /dev/mmcblk0p1
    ]==> mount /dev/mmcblk0p1 /mnt
    ]==> qemu-debootstrap --include=u-boot-tools,mc,initramfs-tools,network-manager,openssh-server --arch=armhf testing /mnt/ http://mirror.init7.net/debian/

For the system to work correctly, the `fstab` file needs to contain the
filesystem configuration of the target, and the system's hostname needs to be
unique. The `PARTUUID`s for all the partitions in a system are obtainable by
running the `blkid` command. It is also useful to specify additional package
repositories in the `soruces.list` file.

    ]==> cat /etc/fstab 
    PARTUUID=100fee9a-01  /               ext4    defaults,noatime  0       1
    ]==> cat /etc/hostname 
    cyclone
    ]==> cat /etc/apt/sources.list
    deb http://mirror.init7.net/debian/ testing main contrib non-free
    deb-src http://mirror.init7.net/debian/ testing main contrib non-free
    deb http://security.debian.org testing-security main contrib non-free
    deb-src http://security.debian.org testing-security main contrib non-free

The final step is to set up the user accounts:

    ]==> chroot /mnt/ /usr/bin/qemu-arm-static /bin/bash
    ]==> useradd -m username
    ]==> passwd username
    ]==> passwd root
    ]==> exit

### U-boot ###

As explained above, u-boot needs to apply the pin multiplexer and other settings
derived from the system design before the operating system can take over the
management of the hardware. For this exercise, we will use the design from
`01-hps-only/hw` directory in this repository. The first step is to synthesize
this system:

    ]==> cd /repo/path/01-hps-only/hw
    ]==> make


The mainline u-boot version typically works fine with the soc-fpga systems:

    ]==> git clone https://github.com/u-boot/u-boot.git
    ]==> cd u-boot
    ]==> git checkout v2020.04
    ]==> ./arch/arm/mach-socfpga/qts-filter.sh cyclone5 /repo/path/01-hps-only/hw /repo/path/01-hps-only/hw/spl ./board/altera/cyclone5-socdk/qts/ 
    ]==> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- socfpga_cyclone5_defconfig
    ]==> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j12
    ]==> dd if=u-boot-with-spl.sfp of=/dev/mmcblk0p2

The `qts-filter.sh` script copies the following header files from your system
definition to u-boot: `iocsr_config.h`, `pinmux_config.h`, `pll_config.h`,
`sdram_config.h`.

### The Linux kernel ###

The mainline kernel works just fine. It is necessary to enable `configfs` in
menuconfig. This functionality makes it possible to re-program the FPGA fabric
without rebooting the Linux system running in the HPS. The relevant setting is:
`File systems > Pseudo filesystems > Userspace-driven configuration filesystem`.

    ]==> wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.6.4.tar.xz
    ]==> tar xf linux-5.6.4.tar.xz
    ]==> cd linux-5.6.4
    ]==> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- socfpga_defconfig
    ]==> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
    ]==> make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j12 bindeb-pkg

To install the kernel, copy the resulting Debian packages to the target root
filesystem and run `dpkg` in chroot:

    ]==> cp ../*.deb /mnt
    ]==> chroot /mnt/ /usr/bin/qemu-arm-static /bin/bash
    ]==> dpkg -i *linux*deb
    ]==> exit

The final step is to tell the bootloader how to load the operating system.
U-boot will look for a configuration file in the root of the filesystem. Here
is what should be in it:

    ]==> cat /boot.cmd
    setenv bootargs 'root=/dev/mmcblk0p1 rw rootwait earlyprintk console=ttyS0,115200n8'
    load mmc 0:1 ${kernel_addr_r} /boot/vmlinuz-5.6.4
    load mmc 0:1 ${fdt_addr_r} /usr/lib/linux-image-5.6.4/socfpga_cyclone5_socdk.dtb
    load mmc 0:1 ${ramdisk_addr_r} /boot/uinitrd.img-5.6.4
    bootz ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}

The bootloader needs to load the kernel image, the ramdisk, and the device tree
to RAM, and then run the kernel from there. U-Boot expects to have the
configuration file and the ramdisk image in a particular format. Here is the
recipe to convert them:

    ]==> mkimage -A arm -O linux -T script -C none -n "Initial u-boot script" -d /boot.cmd /boot.scr
    ]==> mkimage -A arm -O linux -T ramdisk -C gzip -d /boot/initrd.img-5.6.4 /boot/uinitrd.img-5.6.4

### Programming the FPGA fabric ###

U-Boot can program the FPGA fabric at boot time according to the following
parameters in the `boot.cmd` script:

```
load mmc 0:1 0x2000000 /lib/firmware/fpga-payload.rbf
fpga load 0 0x2000000 ${filesize}
bridge enable
```

Alternatively, the Linux kernel provides equivalent functionality through its
FPGA manager module. This functionality is not generally exposed to the
userspace without additional drivers. The one described below makes it possible
to use device-tree overlays to program the fabric. The resulting Debian package
needs to be installed in the target system.

    ]==> git clone --recursive --depth=1 -b v0.0.7 git://github.com/ikwzm/dtbocfg-kmod-dpkg
    ]==> cd dtbocfg-kmod-dpkg
    ]==> fakeroot debian/rules arch=arm deb_arch=armhf kernel_release=5.6.4 kernel_src_dir=/path/to/kernel/src/linux-5.6.4 binary

This repository contains convenient helper scripts that compile the overlay and
load a binary image to the device:

    ]==> sudo ./fpga-manager-overlay-install.sh
    ]==> sudo ./fpga-upload-firmware.sh fpga-payload.rbf


[rb1]: https://rocketboards.org/foswiki/Documentation/BuildingBootloader#C._Prepare_SD_Card_Image
