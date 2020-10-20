#!/bin/bash

declare InvalidParameter=0

while (($# > 0)) 
	do
	declare Option="$1"
	case $Option in
		--transfer-list)
			shift
			if test -f "$1" 
				then
				declare TransferList=$1
				shift
			else
				echo "Error: Transfer list file \"$1\" does not exist"
				InvalidParameter=1
			fi
		;;
		--data-file)
			shift
			if test -f "$1" 
				then
				declare DataFile=$1
				shift
			else
				echo "Error: Data file \"$1\" does not exist"
				InvalidParameter=1
			fi
		;;
		--output-file)
			shift
			if test -f "$1" 
				then
				echo "Error: Output file \"$1\" does already exist"
				InvalidParameter=1
			else
				declare OutputFile=$1
			fi
		;;
		*)
			shift
			echo "Unknown argument \"$1\", ignoring"
		;;
	esac
done

if [ -z "$TransferList" ] 
	then
	echo "Error: No transfer list specified"
	InvalidParameter=1
fi
if [ -z "$DataFile" ] 
	then
	echo "Error: No data file specified"
	InvalidParameter=1
fi
if [ -z "$OutputFile" ] 
	then
	declare OutputFile="${DataFile}.img"
fi

if [ $InvalidParameter -eq 1 ]
	then
	exit 1
fi

declare TransferListVersion=$(sed -n '1p' "$TransferList")

if [[ ! $TransferListVersion =~ ^[0-9]+$ ]]
	then
	echo "Error: Invalid Version \"$TransferListVersion\""
	exit 1
fi

declare NewBlocks=$(sed -n '2p' "$TransferList")

if [[ ! $NewBlocks =~ ^[0-9]+$ ]]
	then
	echo "Error: Invalid Version \"$NewBlocks\""
	exit 1
fi

declare CommandList
if [ $TransferListVersion -ge 2 ]
	then
	CommandList=$(sed -n '5,$p' "$TransferList")
else
	CommandList=$(sed -n '3,$p' "$TransferList")
fi

declare -a Commands
declare -a Rangesets

MaxFileSize=0

while IFS= read -r line
	do
	Temp=($line)
	Cmd="${Temp[0]}"
	if [ "$Cmd" == "new" ] || [ "$Cmd" == "zero" ] || [ "$Cmd" == "erase" ]
		then
		Commands=("${Commands[@]}" "${Temp[0]}")
		Range="${Temp[1]}"
		if [[ ! $Range =~ ^[0-9]+(,[0-9]+,[0-9]+)+$ ]]
			then
			echo "Error: Invalid rangeset \"$Range\""
			exit 1
		fi
		IFS=',' read -r -a Rangeset <<< "$Range"
		if [ ! $((Rangeset[0])) -eq $((${#Rangeset[@]}-1)) ]
			then
			echo "Error: Invalid rangeset \"$Range\""
			exit 1
		fi
		Rangesets=("${Rangesets[@]}" "$Range")
		for(( i=0; i<=${Rangeset[0]}; i++ ))
			do
			if [ $((${Rangeset[$i]})) -gt $(($MaxFileSize)) ]
				then
				MaxFileSize=${Rangeset[$i]}
			fi
		done
	elif [[ ! $Cmd =~ ^[0-9]+$ ]]
		then
		echo "Error: Found invalid command \"$Cmd\""
		exit 1
	fi
done < <(printf '%s\n' "$CommandList")

if ! (dd of="$OutputFile" if=/dev/zero bs=4096c count=$MaxFileSize conv=notrunc) > /dev/null 2>&1
	then
	echo "Error: Can not open output file"
	rm "$OutputFile"
	exit 1
fi

BlocksRead=0
for (( i=0; i<${#Commands[@]}; i++))
	do
	Cmd=${Commands[$i]}
	case "$Cmd" in
		"new")
			IFS=',' read -r -a Rangeset <<< "${Rangesets[$i]}"
			for (( j=1; j<=${Rangeset[0]}; j+=2 ))
				do
				Begin=${Rangeset[$j]}
				End=${Rangeset[$j+1]}
				Count=$(($End-$Begin))
				echo "Copying $Count blocks into position $Begin"
				if ! (dd if="$DataFile" of="$OutputFile" seek=$Begin skip=$BlocksRead conv=notrunc bs=4K count=$Count) > /dev/null 2>&1
					then
					echo "Error: Failed to write to output file"
					rm "$OutputFile"
					exit 1
				fi
				BlocksRead=$(($BlocksRead+$Count))
			done
		;;
		*)
			echo "Skipping command \"$Cmd\""
		;;
	esac
done