#!/bin/bash

OLD_IFS=$IFS
IFS=$'\t\n'
unset boot_entries

while read unstripped_line
do
	# strip DOS line separator \r
	line="${unstripped_line//$'\r'/}"

	if [[ $line =~ ^#.*$ ]]
	then
		if [[ $line =~ ^#1.*$ ]]
		then
			param1=`echo "${line}" | sed -n 's/^#1\o040\([^\o040#]*\).*$/\1/p'`
		fi
		if [[ $line =~ ^#2.*$ ]]
		then
			param2=`echo "${line}" | sed -n 's/^#2\o040\([^\o040#]*\).*$/\1/p'`
		fi
	else
		if [[ -n "${line}" ]]
		then
			boot_entries+=($line)
		else
			boot_entries+=(".")
		fi
	fi

done < .entries.txt
IFS=$OLD_IFS

echo "Parameter #1:"
echo "${param1}"
echo "-------------------"
echo "Parameter #2:"
echo "${param2}"
echo "-------------------"

for printline in "${boot_entries[@]}"
do
	echo "$printline"
done

echo
echo -n "Number of boot entries:"
echo "${#boot_entries[@]}"
echo


#for (( i = 0 ; i < ${#boot_entries[@]}; i++ ))
#do
#	echo "${i}: ${boot_entries[$i]}" 
#done


## delete old bootfiles
for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
do
	rm -rf ../bootfiles/boot.${j}
done


## delete old hashes, remake folder
rm -rf ../bootfiles/grub_switch_hashes
mkdir -p ../bootfiles/grub_switch_hashes


## make new bootfiles
for (( i = 0 ; i < ${#boot_entries[@]}; i++ ))
do
	let "j=i+1"

	# make bootfile folder
	mkdir -p ../bootfiles/boot.${j}

	# make SWITCH.GRB file
	echo -e "grubswitch_sleep_secs='${param1}'\r"       >  ../bootfiles/boot.${j}/SWITCH.GRB
	echo -e "grubswitch_choice_color='${param2}'\r"     >> ../bootfiles/boot.${j}/SWITCH.GRB
	echo -e "grubswitch_choice='${boot_entries[$i]}'\r" >> ../bootfiles/boot.${j}/SWITCH.GRB
 
	cat ../bootfiles/template                           >> ../bootfiles/boot.${j}/SWITCH.GRB


	# make corresponding hash file
	CURR_DIR=`pwd`
	cd ../bootfiles/boot.${j}/
	sha512sum SWITCH.GRB > ../grub_switch_hashes/${j}.sha512
	cd $CURR_DIR


	# TODO: Adjust ownerships if currently root


	# maximum number of bootfiles is 15,
	# even if more entries created in .entries.txt
	if [[ $j = "15" ]]
	then break
	fi
done

# make hashfile for empty SWITCH.GRB case
rm -f SWITCH.GRB ## TODO: check, rename existing
touch SWITCH.GRB ## new and empty
sha512sum SWITCH.GRB > ../bootfiles/grub_switch_hashes/0.sha512
rm -f SWITCH.GRB ## remove again

echo
echo "Bootfiles have been generated."
echo "Either"
echo "a) copy SWITCH.GRB files from the enumerated folders in"
echo "   ../bootfiles to USB drives you want to use as boot choices"
echo " OR"
echo "b) write .entries.txt file to the specialized GRUB Switch"
echo "   USB device. You can use script 2_* for this purpose."
echo
echo "If you want to use hash checking to authenticate boot choices,"
echo "1. remove old hashes with script 5_* (run as root)"
echo " AND"
echo "2. install current hashes with script 6_* (also run as root)"
echo
echo "(if you want no hash checking, run script 5_* anyway (as root)"
echo " to remove old hashes)"
