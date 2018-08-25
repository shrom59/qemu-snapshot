#!/bin/bash

# Configuration variables (change as you wish)
dst="PATH"
vm="$1"
logName="backup.log"
virshbin="sudo /usr/bin/virsh"
qemuimgbin="sudo /usr/bin/qemu-img"
backupname="backup_$vm"

# Combinate previously defined variables for use (don't touch this)
logFile="${dst}/${vm}/${logName}"
backupVmPath="${dst}/${vm}"

#WriteToLog function who will print and log this script output
function writeToLog() {
	echo -e "$(date +%Y/%m/%d) $(date +%H:%M:%S) ${1}" | tee -a "${logFile}"
}

#Create functions to get disks, snapshots convert it and copy it to a destination

function get_dump_xml () {
        writeToLog "Dumping XML for VM $vm"
        sudo virsh dumpxml $vm > $backupVmPath/$vm.xml
        writeToLog "XML for VM $vm dumped and placed at $backupVmPath/$vm.xml"
}

function get_domain_disk () {
		n=0
		for i in `$virshbin domblklist $vm | tail -n+3 | sed -e 's/^\-$//g' | awk '{print $2}'` ; do
			virtual_disks[$n]="$i"
			let "n= $n + 1"
		done
}

function create_snapshot () {
		for disk in ${virtual_disks[*]}
		do
		    writeToLog "Creating snapshot for disk $disk"
			$qemuimgbin snapshot -c $backupname $disk
		    writeToLog "Snapshot $backupname created for disk $disk"
		done
}

function convert_snapshot_qcow2 () {
		for disk in ${virtual_disks[@]}
		do
    		writeToLog "Converting snapshot for disk $disk"
            disktemp=$(echo $disk |cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)
	    	$qemuimgbin convert -f qcow2 -O qcow2 -l $backupname $disk $backupVmPath/$disktemp.qcow2
		    writeToLog "Snapshot for $disk converted placed at $backupVmPath"
		done
}

function delete_snapshot () {
		for disk in ${virtual_disks[@]}
		do
	    	writeToLog "Deleting snapshot $backupname for disk $disk"
		    $qemuimgbin snapshot -d $backupname $disk
	        writeToLog "Snapshot $backupname deleted"
		done
    }

#Checking if we have a VM name which is mandatory
if [ -z $1 ]
then
    echo "We need a VM name here. Exiting."
    exit 1
fi

# Prepare paths at destination
mkdir -p "${dst}" "${backupVmPath}"

# Checking if $dst exist, if yes and if $log sdoesn't exist, will create a new one.
# if not we exit here.
if [ ! -d ${dst} ]
then
    echo The destination path doesn\'t exist, we stop here so.
    exit 1
fi


# Log rotation
if [ -e ${logFile} ]
then
    rm ${logFile}
    touch "${logFile}"
else
    touch "${logFile}"
fi
if [ ! -e ${logFile} ]
then
    writeToLog "The log file isn't created. we stop here so."
    exit 1
else
    writeToLog "A new log file was created"
fi

writeToLog "********************************"
writeToLog "*   Checking $vm VM state     *"
writeToLog "********************************"

testVm=$(sudo virsh list|grep -i ${vm})

if [ ! -z "$testVm" ]
then
    writeToLog "Virtual Machine ${vm} is up, shutting down"
    sudo virsh shutdown $vm
    while [ ! -z "$testVm" ]
    do
        writeToLog "Virtual Machine ${vm} is still up, keep trying in 5 seconds"
        sleep 5
        testVm=$(sudo virsh list|grep -i ${vm})
    done
else
    writeToLog "Virtual Machine ${vm} is already down"
fi

writeToLog "********************************"
writeToLog "*     Backuping $vm disks     *"
writeToLog "********************************"
writeToLog "You are going to backup the $vm vm's disks"
writeToLog "to:    ${backupVmPath}"


# Do the backup
get_dump_xml
get_domain_disk
create_snapshot
convert_snapshot_qcow2
delete_snapshot
