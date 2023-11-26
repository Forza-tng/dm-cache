dm-cache
![](dm-cache.jpg "dm-cache.jpg") Device Mapper Cache, is a Linux kernel feature designed to enhance storage performance by
implementing a block-level cache on a separate cache device.
`dm-cache` is a tool that helps the user setup cache devices.

The goal with dm-cache is to improve random read/write performance of a slow HDD by using a small but fast SSD or NVME device.

The main advantage of dm-cache over [LVM](https://sourceware.org/lvm2/) and [Bcache](https://bcache.evilpiepirate.org/) is that it is possible to setup on devices that already have a filesystem with data on them. Both LVM and Bcache requires unformatted, empty devices, to setup (there are ways to get around, but can be risky).

## Requirements
dm-cache utilises the `dmsetup` utility which usually can be found in [lvm2](https://packages.debian.org/bookworm/lvm2) or [device-mapper](https://pkgs.alpinelinux.org/packages?name=device-mapper&branch=edge&repo=&arch=&maintainer=) packages.

dm-cache requires three devices
-   **origin**: The slow device.
-   **cache**: A fast SSD or NVME device. Can be of any size.
-   **meta**: A small device that holds dm-cache metadata.

The metadata device size depends on how many cache blocks fit on the cache device. With **default** setting it should be a least 0.01% of the cache device size. If the cache device is 50GiB, and a cache block size of 128KiB, a metadata device of 5MiB is enough. Smaller block sizes requires more metadata and memory, while larger block sizes may reduce effectiveness of the cache by storing cold data. Check metadata usage with `cachestats.sh` to ensure you are within limits.

It is important to mount the filesystem on the dm-cache using the
`/dev/mapper/dmname` path and not with the filesystem UUID as is commonly done. This is because the kernel might still see the
UUID from the origin device, and this can cause data loss!

If you\'re using Btrfs, the following message can be seen in the kernel log:
```text
# dmesg
BTRFS warning: duplicate device /dev/sdj1 devid 1 generation 182261 scanned by mount (13706)
```
There is a udev rule that prevents this issue by removing the `/dev/disk/by-uuid/` symlink to the  origin device.

## Documentation
Full documentation is available at https://wiki.tnonline.net/w/Linux/dm-cache

## Cache Statistics
`cachestats.sh` is used to see current stats of the dm-cache device.
```text
# cachestats.sh data2
DEVICE
========
Device-mapper name:       /dev/mapper/data2
Origin size:              9 TiB
Discards:                 no_discard_passdown
CACHE
========
Size / Usage:             100 GiB / 100 GiB (99 %)
Read Hit Rate:            335117403 / 520337199 (64 %)
Write Hit Rate:           24747253 / 31885008 (77 %)
Dirty:                    0 bytes
Block Size:               128 KiB
Promotions / Demotions:   648844 / 648844
Migration Threshold:      1 MiB
Read-Write mode:          rw
Type:                     writeback
Policy:                   smq
Status:                   OK
METADATA
========
Size / Usage:             256 MiB / 10 MiB (3 %)
```