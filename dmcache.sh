#!/bin/bash

# dm-cache
# A helper program to setup and manage device-mapper
# cache devices.
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright 2023 Forza <forza@tnonline.net>

dmname="data"
origindev="/dev/disk/by-partuuid/ac0ae9b1-8e32-4e33-b641-998bc0298d14" # use stable device ID, not FS UUID
metadev="/dev/vg_800g/lv_cache_usb_backup_meta"
cachedev="/dev/vg_800g/lv_cache_usb_backup_cache"
blocksize="256" # dm-cache block size in sectors
cachemode="writethrough" # writethrough, writeback, passthrough
policy="default"

dmsetup info "${dmname}" >/dev/null && echo "\"${dmname}\" already exists!" ; exit 1

if [ -e "${origindev}" ] && [ -e "${metadev}" ] && [ -e "${cachedev}" ]; then
	echo "Creating dm-cache device \"/dev/mapper/${dmname}\""
	dmsetup create "${dmname}" --table "0 $(blockdev --getsz ${origindev}) cache ${metadev} ${cachedev} ${origindev} ${blocksize} 1 ${cachemode} ${policy} 0" || echo "Something went wrong. Check dmesg."
else
	echo "Can't find all required devices"
fi

