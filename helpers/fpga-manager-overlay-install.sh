#!/bin/bash

function error() {
    echo -e "\033[1;31m$@\\033[0m";
}

function highlight() {
    echo -e "\033[1;32m$@\\033[0m";
}

if [ "$EUID" -ne 0 ]; then
    error "You need to run this script as root"
    exit 1
fi

if [ ! -d /sys/kernel/config ]; then
    error "ConfigFS either not compiled in the kernel or not mounted"
    exit 1
fi

modprobe dtbocfg
if [ $? -ne 0 ]; then
    error "Can't load the dtbocfg driver"
    exit 1
fi

if [ ! -d /sys/kernel/config/device-tree/overlays ]; then
    error "Can't find device tree overlays in ConfigFS"
    exit 1
fi

if [ -f /sys/kernel/config/device-tree/overlays/fpga-manager/status ]; then
    highlight "The fpga manager overlay is already installed"
    exit 0
fi

dtc -O dtb -o fpga-manager-overlay.dtbo fpga-manager-overlay.dts
if [ $? -ne 0 ]; then
    error "Can't compile the device overlay file"
    exit 1
fi

if [ ! -f fpga-manager-overlay.dtbo ]; then
    error "The device tree compiler did not produce any output"
    exit 1
fi

mkdir /sys/kernel/config/device-tree/overlays/fpga-manager
if [ $? -ne 0 ]; then
    error "Can't instantiate a new overlay"
    exit 1
fi

cp fpga-manager-overlay.dtbo /sys/kernel/config/device-tree/overlays/fpga-manager/dtbo
if [ $? -ne 0 ]; then
    error "Can't install the overlay"
    exit 1
fi
