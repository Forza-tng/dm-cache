# dm-cache
Tool to create and manage device-mapper cache devices.

DM-cache, or Device Mapper Cache, is a Linux kernel feature designed to enhance storage performance by implementing a block-level cache on a separate cache device.

The goal with dm-cache is to improve random read/write performance of a slow HDD by using a small but fast SSD or NVME device.

The main advantage of dm-cache over lvmcache and bcache is that it is possible to setup on devices that already have a filesystem with data on them. Both LVM and Bcache requires unformatted, empty devices (there are ways to get around, but can be risky).

## Requirements
dm-cache requires three devices; 
- origin: The slow device.
- cache: A fast SSD or NVME device. Can be of any size.
- meta: A small device that holds dm-cache metadata.

The metadata device size depends on how many cache blocks fit on the cache device. With default setting it should be a least 0.01% of the cache device size. If the cache device is 50GiB, and a cache block size of 128KiB, a metadata device of 5MiB is enough. It is important to have spare space, or dm-cache can become corrupted!

## Setup
- Install `conf.d/dmcache` and `init.d/dmcache`
- Modify `conf.d/dmcache` to suit your setup
- Add a udev rule to block FS UUID device symlinks
- Add dmcache to boot runlevel: `rc-update add dmcache boot`

### Multiple devices
If you have several devices you can simply make a copy of the init.d and conf.d files to a new name. The filenames in init.d and conf.d must be the same.

- `cp /etc/conf.d/dmcache /etc/conf.d/dmcache.new`
- `ln -s /etc/init.d/dmcache /etc/init.d/dmcache.new`
- update `/etc/conf.d/dmcache.new`
- update udev rules
- `rc-service dmcache.new start`
- `rc-update add dmcache.new boot`