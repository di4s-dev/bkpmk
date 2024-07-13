#!/bin/bash

function utilsIsValidPort() 
{
    local port="$1" ; 

    [[ "${port}" =~ [^0-9] ]] && return 1 ; 

    [ $port -lt 1 ] && return 2 ;
    [ $port -gt 65535 ] && return 3 ;

    return 0 ;
}

function utilsIsValidUser()
{
    local user="$1" ;

    [[ ! "${user}" =~ ^[a-z0-9][a-z0-9\.\_\-]{1,}[a-z0-9]$ ]] && return 1 ; 

    return 0 ;
}

function utilsIsValidIP()
{
    local ip="$1" ;

    [[ ! "${ip}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && return 1 ; 

    local octets=$( echo "${ip}" | tr '.' ' ' ) ;
	
    for o in $octets ; do

    	[ $o -gt 255 ] && return 2 ;	    
    done ;

    return 0 ;
}

function utilsIsValidPublicKey()
{
    local publicKey="$1" ;

    [ ! -e "${publicKey}" ] && return 1 ;

    cat "${publicKey}" | grep "ssh-rsa" > /dev/null ;

    [ $? -ne 0 ] && return 2 ;

    return 0 ;
}

function utilsIsValidPrivateKey()
{
    local privateKey="$1" ;

    [ ! -e "${privateKey}" ] && return 1 ;

    cat "${privateKey}" | grep "OPENSSH PRIVATE KEY" > /dev/null ;

    [ $? -ne 0 ] && return 2 ;

    return 0 ;
}

function utilsIsValidKeep() 
{
    local keep="$1" ; 

    [[ "${keep}" =~ [^0-9] ]] && return 1 ; 

    [ $keep -lt 2 ] && return 2 ;
    [ $keep -gt 30 ] && return 3 ;

    return 0 ;
}

