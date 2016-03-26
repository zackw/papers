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

doRun() 
{
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
    
    # start Alice VM and experiment
    sleep 1
    VBoxManage startvm $VM_NAME
    sleep 10 # let networking kick in
    VBoxManage guestcontrol $VM_NAME exec --image $GUEST_SRC_DIR/usec12-exp.sh \
	--username $USER --password $PWORD --verbose --wait-stdout -- \
	-m $1 -t 30 -d $GUEST_RESULTS_DIR -p $2 -b 128.18.9.71:$3 $GUEST_MACROS_DIR alexa $4
}

doCopy()
{ # copy latest scripts to Alice VM; TODO: doesn't work!
    VM_PID=`ps ax | grep startvm | grep $VM_NAME | cut -d' ' -f1`
    if [ -z "$VM_PID" ]; then
	VBoxManage startvm $VM_NAME
	sleep 1
    fi
    for script in usec12-exp.sh generate-iMacro.sh; do
	VBoxManage guestcontrol $VM_NAME copyto $HOST_SRC_DIR/$script $GUEST_SRC_DIR --username $USER --password $PWORD --verbose
    done
}

for run in {1..1}; do
    for site in {2..2}; do
	for mode in {2..3}; do
	    # see if this run already exists
	    ls $HOST_RESULTS_DIR/alexa/m${mode}/site${site}-r${run}* &> /dev/null
	    if [ $? ]; then	    
		PORT=8888
		if [ "$mode" -eq 3 ]; then
		    PORT=8080
		fi
		doRun $mode site${site}-r${run}- $PORT $site
	    fi
	done
    done
done
