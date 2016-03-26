#!/bin/bash
# run experiments in fresh Alice VM 

declare VM_NAME=Alice
declare HOST_RESULTS_DIR=/Users/linda/Shared/usec12
declare HOST_SRC_DIR=/Users/linda/src/DEFIANCE/reports/usec12-storus/eval
declare GUEST_RESULTS_DIR=/home/alice/tmp/usec12-exp
declare GUEST_SRC_DIR=/home/alice/bin
declare GUEST_MACROS_DIR=/home/alice/iMacros/Macros
declare USER=alice
declare PWORD=defiance

# kill any running Alice VM
VM_PID=`ps ax | grep startvm | grep $VM_NAME | cut -d' ' -f1`
if [ -n "$VM_PID" ]; then
    VBoxManage controlvm $VM_NAME poweroff
    sleep 1
    VM_PID=`ps ax | grep startvm | grep $VM_NAME | cut -d' ' -f1`
    if [ -n "$VM_PID" ]; then
	kill -9 $VM_PID  # if poweroff is not effective, use the hammer
    fi
fi
    
# restore Alice VM to snapshot
sleep 1
VBoxManage snapshot $VM_NAME restorecurrent
    
# start Alice VM
sleep 1
VBoxManage startvm $VM_NAME
sleep 10 # let networking kick in

# test shared
VBoxManage showvminfo $VM_NAME
VBoxManage guestcontrol $VM_NAME exec --image "/bin/ls" --username $USER --password $PWORD --verbose --wait-stdout -- -la /media
VBoxManage guestcontrol $VM_NAME exec --image "/bin/ls" --username $USER --password $PWORD --verbose --wait-stdout -- -la /media/sf_transient
#VBoxManage guestcontrol $VM_NAME exec --image "/home/alice/bin/mount_transient.sh" --username $USER --password $PWORD --verbose --wait-stdout
#VBoxManage guestcontrol $VM_NAME exec --image "/bin/ls" --username $USER --password $PWORD --verbose --wait-stdout -- -la /media/sf_transient
#VBoxManage guestcontrol $VM_NAME exec --image $GUEST_SRC_DIR/usec12-exp.sh 	--username $USER --password $PWORD --verbose --wait-stdout -- 	-m $1 -t 30 -d $GUEST_RESULTS_DIR -p $2 -b 128.18.9.71:$3 $GUEST_MACROS_DIR alexa $4
