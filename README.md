# qemu-snapshot

This script can be used with libvirt and qemu (3.0)
You just ahve to change the "dst" var at the begining of the script. This should contains the destination folder of your backup.

One you did that, you just have to call the script with the name of the vm you want to backup as parameter.

I'm using sudo in my linux environnement, so you can just remove the "sudo" string in "virshbin" and "qemuimgbin" vars if you don't.

This how the script works :

Shutdown the Vms normally using "virsh shutdown" command (prefixed by sudo in my case). It will loop evry 5 second until the VM is not down.
Find the xml file used by libvirt and create a dump of it
Find all the disk of this Vms and store it into an array.
Create a snapshots of each disks.
Convert the disk into the destination file, this tricks will thrink the disk. By default a thin provissionning is used when a virtual disk is created. This way only the real used space will be stored
Delete the snapshot.
