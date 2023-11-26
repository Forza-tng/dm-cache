#!/bin/bash

# cachestats for dm-cache
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright 2023 Forza <forza@tnonline.net>

device_name="$1"

# Declare an associative array to store key-value pairs
declare -A data
declare -i sizess
declare status_output
declare -a dmstatus

# Function to convert bytes to IEC units
to_iec() {
	local bytes kib mib gib tib
	bytes=$1
	kib=$(( (bytes + 512) / 1024 ))
	mib=$(( (kib + 512) / 1024 ))
	gib=$(( (mib + 512) / 1024 ))
	tib=$(( (gib + 512) / 1024 ))
	if [ $tib -gt 0 ]; then
		echo "${tib} TiB"
	elif [ $gib -gt 0 ]; then
		echo "${gib} GiB"
	elif [ $mib -gt 0 ]; then
		echo "${mib} MiB"
	elif [ $kib -gt 0 ]; then
		echo "${kib} KiB"
	else
		echo "${bytes} bytes"
	fi
}

# Get the status output using dmsetup
status_output=$(dmsetup status "$device_name" 2>/dev/null)

# Check if the device exists and has valid output
if [ -n "$status_output" ]; then
	sizess=$(blockdev --getss "/dev/mapper/${device_name}")
	
	# Parse the status information into the associative array
	IFS='/: ' read -r -a dmstatus <<< "$status_output"
	
	## Ouput `dmsetup status` raw data:
	#	for ((i = 0; i < ${#dmstatus[@]}; i += 1)); do
	#		echo \# $i: ${dmstatus["$i"]}
	#	done
	
	# Field order of `dmsetup status <cachedev>`:
	# https://www.kernel.org/doc/html/latest/admin-guide/device-mapper/cache.html
	#
	# <metadata block size> <#used metadata blocks>/<#total metadata blocks>
	# <cache block size> <#used cache blocks>/<#total cache blocks>
	# <#read hits> <#read misses> <#write hits> <#write misses>
	# <#demotions> <#promotions> <#dirty> <#features> <features>*
	# <#core args> <core args>* <policy name> <#policy args> <policy args>*
	# <cache metadata mode>

	data["name"]="$device_name"
	data["origin_start"]=$(( ${dmstatus[0]} * $sizess )) # in sectors
	data["origin_length"]=$(( ${dmstatus[1]} * $sizess )) # in sectors
	data["table_type"]="${dmstatus[2]}"
	data["metadata_block_size"]=$(( ${dmstatus[3]} * $sizess )) # in sectors
	data["used_metadata_blocks"]="${dmstatus[4]}"
	data["total_metadata_blocks"]="${dmstatus[5]}"
	data["cache_block_size"]=$(( ${dmstatus[6]} * $sizess )) # in sectors
	data["used_cache_blocks"]="${dmstatus[7]}"
	data["total_cache_blocks"]="${dmstatus[8]}"
	data["read_hits"]="${dmstatus[9]}"
	data["read_misses"]="${dmstatus[10]}"
	data["write_hits"]="${dmstatus[11]}"
	data["write_misses"]="${dmstatus[12]}"
	data["demotions"]="${dmstatus[13]}"
	data["promotions"]="${dmstatus[14]}"
	data["dirty_cache"]=$(( ${dmstatus[15]} * ${data[cache_block_size]} ))
	if [ "${dmstatus[16]}" = 2 ]; then
		data["cache_type"]="${dmstatus[17]}"
		data["discard_passdown"]="${dmstatus[18]}"
		data["migration_threshold"]=$(( ${dmstatus[21]} * $sizess ))
		data["cache_policy"]="${dmstatus[22]}"
		data["smq_count"]="${dmstatus[23]}"
		data["cache_rw"]="${dmstatus[24]}"
		data["status"]="${dmstatus[25]//-/OK}"
	else
		data["cache_type"]="${dmstatus[17]}"
		data["discard_passdown"]="true"
		data["migration_threshold"]=$(( ${dmstatus[20]} * $sizess ))
		data["cache_policy"]="${dmstatus[21]}"
		data["smq_count"]="${dmstatus[22]}"
		data["cache_rw"]="${dmstatus[23]}"
		data["status"]="${dmstatus[24]//-/OK}"
	fi

# Loop through throuh all fields to list and print their values
#	for field in "${!data[@]}"; do
#		value="${data[$field]}"
#		if [ -n "$value" ]; then
#			echo "$field : $value"
#		else
#			echo "Field '$field' not found."
#		fi
#	done |sort

	# Output defined fields
	printf "DEVICE\n"
	printf "========\n"
	printf "%-*s%s\n" "26" "Device-mapper name: " "/dev/mapper/${data[name]}"
	printf "%-*s%s\n" "26" "Origin size: " "$(to_iec $(( ${data[origin_length]} - ${data[origin_start]} )) )"
	printf "%-*s%s\n" "26" "Discards: " "${data[discard_passdown]}"

	printf "\n"
	printf "CACHE\n"
	printf "========\n"
	printf "%-*s%s\n" "26" "Size / Usage: " "$(to_iec $((${data[total_cache_blocks]} * ${data[cache_block_size]}))) / $(to_iec $(( ${data[used_cache_blocks]} * ${data[cache_block_size]} ))) ($(( 100 * ${data[used_cache_blocks]} / ${data[total_cache_blocks]} )) %)"
	printf "%-*s%s\n" "26" "Read Hit Rate: " "${data[read_hits]} / $((${data[read_misses]} + ${data[read_hits]})) ($(( 100 * ${data[read_hits]} / (${data[read_hits]} + ${data[read_misses]}) )) %)"
	printf "%-*s%s\n" "26" "Write Hit Rate: " "${data[write_hits]} / $((${data[write_misses]} + ${data[write_hits]})) ($(( 100 * ${data[write_hits]} / (${data[write_hits]} + ${data[write_misses]}) )) %)"
	printf "%-*s%s\n" "26" "Dirty: " "$(to_iec ${data[dirty_cache]})"
	printf "%-*s%s\n" "26" "Block Size: " "$(to_iec ${data[cache_block_size]})"
	printf "%-*s%s\n" "26" "Promotions / Demotions: " "${data[promotions]} / ${data[demotions]}"
	printf "%-*s%s\n" "26" "Migration Threshold: " "$(to_iec ${data[migration_threshold]})"
	printf "%-*s%s\n" "26" "Read-Write mode: " "${data[cache_rw]}"
	printf "%-*s%s\n" "26" "Type: " "${data[cache_type]}"
	printf "%-*s%s\n" "26" "Policy: " "${data[cache_policy]}"
	printf "%-*s%s\n" "26" "Status: " "${data[status]}"

	printf "\n"
	printf "METADATA\n"
	printf "========\n"
	printf "%-*s%s\n" "26" "Size / Usage: " "$(to_iec $(( ${data[total_metadata_blocks]} * ${data[metadata_block_size]} ))) / $(to_iec $(( ${data[used_metadata_blocks]} * ${data[metadata_block_size]} ))) ($(( 100 * ${data[used_metadata_blocks]} / ${data[total_metadata_blocks]} )) %)"
else
    echo "Device not found or no valid status output."
fi
