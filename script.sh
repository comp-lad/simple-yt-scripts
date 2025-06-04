#!/bin/bash

# Fetching hardware info
cpu_vendor=$(lscpu | grep "Vendor ID:" | awk -F ': +' '{print$2}')
cpu_architecture=$(lscpu | grep "Architecture:" | awk -F ': +' '{print $2}')

# Check if the cpu is supported by the script
if [[ "$cpu_architecture" = "x86_64" && ("$cpu_vendor" = "GenuineIntel" || "$cpu_vendor" = "AuthenticAMD") ]]; then
	echo "Your CPU vendor is : $cpu_vendor"
	echo "You CPU architecture : $cpu_architecture"
	echo -en "\nAll the parameters are set, shall we continue? [y/n] "
	read final_permission
	
	# Acting upon user's will
	if [[ $final_permission = y || $final_permission = Y ]]; then		
		#Fetching Virtual Boxes
		mapfile -t vm_names < <(vboxmanage list vms | awk -F '"' '{print $2}')

		# Check if any VMs were found
		if [ ${#vm_names[@]} -eq 0 ]; then
		    echo "No VirtualBox VMs found."
		    exit 0
		fi
		
		# Display the numbered list to the user
		echo "Available VirtualBox VMs:"
		for i in "${!vm_names[@]}"; do
		    echo "$((i+1)). ${vm_names[i]}"
		done
		
		# Prompt the user for their selection
		read -p "Enter the number of the VM you want to select: " vm_selection
		
		# Input validation
		if ! [[ "$vm_selection" =~ ^[0-9]+$ ]]; then
		    echo "Invalid input. Please enter a valid number."
		    exit 1
		fi
		
		# Adjust to 0-based index for array
		selected_index=$((vm_selection - 1))
		
		# Check if the number is within the valid range
		if (( selected_index < 0 || selected_index >= ${#vm_names[@]} )); then
		    echo "Invalid VM number. Please select a number from the list."
		    exit 1
		fi
		
		# Get the actual VM name using the selected index
		selected_vm_name="${vm_names[selected_index]}"
		echo "You selected VM: $selected_vm_name"
		echo "The selected VM is being tweaked to run MAC os..."
		
		# Working upon the VM 
  		set -e
		VBoxManage modifyvm "$selected_vm_name" --boot1 disk --boot2 dvd --boot3 none --boot4 none
		VBoxManage modifyvm "$selected_vm_name" --firmware efi
		VBoxManage modifyvm "$selected_vm_name" --chipset ich9
		VBoxManage modifyvm "$selected_vm_name" --vram 256
		VBoxManage modifyvm "$selected_vm_name" --accelerate3d on
		VBoxManage modifyvm "$selected_vm_name" --usb on
		VBoxManage modifyvm "$selected_vm_name" --usbehci off 
		VBoxManage modifyvm "$selected_vm_name" --usbxhci on
		if [ $cpu_vendor = GenuineIntel ]; then
			VBoxManage modifyvm "$selected_vm_name" --cpuidset 00000001 000106e5 00100800 0098e3fd bfebfbff
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "iMac19,3"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Iloveapple"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 0
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/TM/TSCMode" "RealTSCOffset"
                        echo "The VM is tweaked successfully."
                        echo "Starting VM"
		
		elif [ $cpu_vendor = AuthenticAMD ]; then
			VBoxManage modifyvm "$selected_vm_name" --cpuidset 00000001 000106e5 00100800 0098e3fd bfebfbff
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/efi/0/Config/DmiSystemProduct" "iMac19,3"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/efi/0/Config/DmiSystemVersion" "1.0"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/efi/0/Config/DmiBoardProduct" "Iloveapple"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/smc/0/Config/DeviceKey" "ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/Devices/smc/0/Config/GetKeyFromRealSMC" 0
			VBoxManage modifyvm "$selected_vm_name" --cpu-profile "Intel Core i7-6700K"
			VBoxManage setextradata "$selected_vm_name" "VBoxInternal/TM/TSCMode" "RealTSCOffset"
			echo "The VM is tweaked successfully."
                        echo "Starting VM"
		fi
  		if [ $? -ne 0 ]; then
    			echo "Something error occurred. error $?"
       		fi
	elif [[ $final_permission = n || $final_permission = N ]]; then 
		echo "Interrupted by the user"
		exit 0
	else 
		echo "Invalid Input"
		exit 
	fi

elif [ $cpu_architecture != x84_64 ]; then
	echo "This script can not run in non-64 bit systems"
	exit
elif [ $cpu_vendor != GenuineIntel && $cpu_vendor != AuthenticAMD ]; then
	echo "This script can not run on $cpu_vendor cpu"
	exit
fi

