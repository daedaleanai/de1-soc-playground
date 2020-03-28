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

if [ $# -ne 1 ]; then
    error "You need to specify the firmware file to upload to the device"
    exit 1
fi

if [ ! -f /sys/kernel/config/device-tree/overlays/fpga-manager/status ]; then
    error "The fpga manager overlay is not installed"
    exit 1
fi

if [ ! -d /lib/firmware ]; then
    mkdir /lib/firmware
fi

if [ ! -f $1 ]; then
    error "The firmware file \"$1\" does not exist"
    exit 1
fi

cp $1 /lib/firmware/fpga-payload.rbf
if [ $? -ne 0 ]; then
    error "Unable to copy \"$1\" to /lib/firmware/fpga-payload.rbf"
    exit 1
fi

echo 0 > /sys/kernel/config/device-tree/overlays/fpga-manager/status
if [ $? -ne 0 ]; then
    error "Unable to disable the fpga manager overlay"
    exit 1
fi

echo 1 > /sys/kernel/config/device-tree/overlays/fpga-manager/status
if [ $? -ne 0 ]; then
    error "Unable to re-enable the fpga manager overlay"
    exit 1
fi
