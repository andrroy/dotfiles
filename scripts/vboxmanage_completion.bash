#!/usr/bin/bash
# 
# Attempt at autocompletion script for vboxmanage. This scripts assumes an 
# alias between VBoxManage and vboxmanaage.
#
# Copyright (c) 2012  Thomas Malt <thomas@malt.no>
#

alias vboxmanage="VBoxManage"

complete -F _vboxmanage vboxmanage

# export VBOXMANAGE_NIC_TYPES

_vboxmanage() {
    local cur prev opts

    COMPREPLY=()

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # echo "cur: |$cur|"
    # echo "prev: |$prev|"

    case $prev in 
	-v|--version)
	    return 0
	    ;;

	-l|--long)
	    opts=$(__vboxmanage_list "long")
	    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
	    return 0	    
	    ;;
	--nic[1-8])
	    # This is part of modifyvm subcommand
	    opts=$(__vboxmanage_nic_types)
	    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
	    ;;
	startvm|list)
	    opts=$(__vboxmanage_$prev)
	    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
	    return 0	    
	    ;;	
	--type)
	    COMPREPLY=($(compgen -W "gui headless" -- ${cur}))
	    return 0
	    ;;
	gui|headless)
	    # Done. no more completion possible
	    return 0
	    ;;
	vboxmanage)
            # In case current is complete command we return emmideatly.
	    case $cur in
		startvm|list|controlvm|showvminfo|modifyvm)
		    COMPREPLY=($(compgen -W "$cur "))
		    return 0
		    ;;
	    esac
	    
	    # echo "Got vboxmanage"
	    opts=$(__vboxmanage_default)
	    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
	    return 0
	    ;;
	-q|--nologo)
	    opts=$(__vboxmanage_default)
	    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
	    return 0
	    ;;
	controlvm|showvminfo|modifyvm)
	    opts=$(__vboxmanage_list_vms)
	    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
	    return 0
	    ;;
	vrde|setlinkstate*)
	    # vrde is a complete subcommand of controlvm
	    opts="on off"
	    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
	    return 0
	    ;;
    esac

    for VM in $(__vboxmanage_list_vms); do
	if [ "$VM" == "$prev" ]; then
	    pprev=${COMP_WORDS[COMP_CWORD-2]}
	    # echo "previous: $pprev"
	    case $pprev in
		startvm)
 		    opts="--type"	    
		    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
		    return 0
		    ;;
		controlvm)
		    opts=$(__vboxmanage_controlvm $VM)
		    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
		    return 0;
		    ;;
		showvminfo)
		    opts="--details --machinereadable --log"
		    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
		    return 0;
		    ;;
		modifyvm)
		    opts=$(__vboxmanage_modifyvm)
		    COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
		    return 0
		    ;;
	    esac
	fi
    done

    # echo "Got to end withoug completion"
}


_vboxmanage_realopts() {
    echo $( \
	vboxmanage | grep -i vboxmanage| \
	cut -d' ' -f2 | \
	grep '\[' | \
	tr -s '[\[\]\|]' ' ' \
    ) 
    echo " "
}

__vboxmanage_nic_types() {
    echo $( \
	vboxmanage | \
	grep ' nic<' | \
	sed 's/.*nic<1-N> \([a-z\|]*\).*/\1/' | tr '|' ' ' \
    )
}

__vboxmanage_startvm() {
    RUNNING=$(vboxmanage list runningvms | cut -d' ' -f1 | tr -d '"')
    TOTAL=$(vboxmanage list vms | cut -d' ' -f1 | tr -d '"')

    AVAILABLE=""
    for VM in $TOTAL; do
	MATCH=0;
	for RUN in $RUNNING "x"; do
	    if [ "$VM" == "$RUN" ]; then
		MATCH=1
	    fi
	done
	(( $MATCH == 0 )) && AVAILABLE="$AVAILABLE $VM "
    done
    echo $AVAILABLE
}

__vboxmanage_list() {
    INPUT=$(vboxmanage list | tr -s '[\[\]\|\n]' ' ' | cut -d' ' -f4-)
    
    PRUNED=""
    if [ "$1" == "long" ]; then
	for WORD in $INPUT; do
	    [ "$WORD" == "-l" ] && continue;
	    [ "$WORD" == "--long" ] && continue;
	    
	    PRUNED="$PRUNED $WORD"
	done
    else 
	PRUNED=$INPUT
    fi

    echo $PRUNED
}


__vboxmanage_list_vms() {
    VMS=""
    if [ "x$1" == "x" ]; then
	SEPARATOR=" "
    else
	SEPARATOR=$1
    fi
    
    for VM in $(vboxmanage list vms | cut -d' ' -f1 | tr -d '"'); do
	[ "$VMS" != "" ] && VMS="${VMS}${SEPARATOR}"
	VMS="${VMS}${VM}"
    done

    echo $VMS
}

__vboxmanage_list_runningvms() {
    VMS=""
    if [ "$1" == "" ]; then
	SEPARATOR=" "
    else
	SEPARATOR=$1
    fi
    
    for VM in $(vboxmanage list runningvms | cut -d' ' -f1 | tr -d '"'); do
	[ "$VMS" != "" ] && VMS="${VMS}${SEPARATOR}"
	VMS="${VMS}${VM}"
    done

    echo $VMS

}

__vboxmanage_controlvm() {
    echo "pause resume reset poweroff savestate acpipowerbutton"
    echo "acpisleepbutton keyboardputscancode guestmemoryballoon"
    echo "gueststatisticsinterval usbattach usbdetach vrde vrdeport"
    echo "vrdeproperty vrdevideochannelquality setvideomodehint"
    echo "screenshotpng setcredentials teleport plugcpu unplugcpu"
    echo "cpuexecutioncap"
    
    # setlinkstate<1-N> 
    activenics=$(__vboxmanage_showvminfo_active_nics $1)
    for nic in $(echo "${activenics}" | tr -d 'nic'); do
	echo "setlinkstate${nic}"
    done

    # nic<1-N> null|nat|bridged|intnet|hostonly|generic
    #                                      [<devicename>] |
                          # nictrace<1-N> on|off
                          #   nictracefile<1-N> <filename>
                          #   nicproperty<1-N> name=[value]
                          #   natpf<1-N> [<rulename>],tcp|udp,[<hostip>],
                          #                 <hostport>,[<guestip>],<guestport>
                          #   natpf<1-N> delete <rulename>

}

__vboxmanage_modifyvm() {
    options=$(\
        vboxmanage modifyvm | \
        grep '\[--' | \
	grep -v '\[--nic<' | \
        sed 's/ *\[--\([a-z]*\).*/--\1/' \
    );
    # Exceptions
    for i in {1..8}; do
	options="$options --nic${i}"
    done
    echo $options
}

__vboxmanage_showvminfo_active_nics() {
    nics=$(vboxmanage showvminfo $1 --machinereadable | \
           awk '/^nic/ && ! /none/' | \
	   awk '{ split($1, names, "="); print names[1] }' \
    );
    echo $nics
}

__vboxmanage_default() {
    realopts=$(_vboxmanage_realopts)
    opts=$realopts$(vboxmanage | grep -i vboxmanage | cut -d' ' -f2 | grep -v '\[' | sort | uniq)
    pruned=""

    # echo ""
    # echo "DEBUG: cur: $cur, prev: $prev"
    # echo "DEBUG: default: |$p1|$p2|$p3|$p4|"
    case ${cur} in
 	-*)
	    echo $opts
 	    # COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
 	    return 0
 	    ;;
    esac;

    for WORD in $opts; do
	MATCH=0
	for OPT in ${COMP_WORDS[@]}; do
		    # opts=$(echo ${opts} | grep -v $OPT);
	    if [ "$OPT" == "$WORD" ]; then
		MATCH=1
		break;
	    fi
	    if [ "$OPT" == "-v" ] && [ "$WORD" == "--version" ]; then
		MATCH=1
		break;
	    fi
	    if [ "$OPT" == "--version" ] && [ "$WORD" == "-v" ]; then
		MATCH=1
		break;
	    fi
	    if [ "$OPT" == "-q" ] && [ "$WORD" == "--nologo" ]; then
		MATCH=1
		break;
	    fi
	    if [ "$OPT" == "--nologo" ] && [ "$WORD" == "-q" ]; then
		MATCH=1
		break;
	    fi
	done
	(( $MATCH == 1 )) && continue;
	pruned="$pruned $WORD"
	
    done
    
    # COMPREPLY=($(compgen -W "${pruned}" -- ${cur}))
    echo $pruned
    return 0
}

