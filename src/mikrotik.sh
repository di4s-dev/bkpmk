#!/bin/bash

function mikrotikTestAccess() 
{
    local user=$1 ;
    local ip=$2 ;    
    local port=$3 ;    
    local privateKey=$4 ;

    local command=':log info "BKP - TESTE ACESSO" ; ' ;

    ssh -o 'PubkeyAcceptedKeyTypes +ssh-rsa' -o BatchMode=yes -i "${privateKey}" ${user}@${ip} "$command" > /dev/null 2>&1  ; 

    [ $? -ne 0 ] && return 1 ;

    return 0;
}

function mikrotikImportKey() 
{
    local user=$1 ; 
    local ip=$2 ;
    local port=$3 ;
    local publicKey=$4 ;
    
    local time=$( date +%s ) ; 
    local tempName="scriptbkp-${user}-${time}.pub" ;


    scp "${publicKey}" ${user}@${ip}:/${tempName}  > /dev/null 2>&1 ;

    [ $? -ne 0 ] && return 1 ;
 
    local command="/user ssh-keys import public-key-file=${tempName} user=${user} ;" ;

    ssh ${user}@${ip} "${command}" > /dev/null 2>&1 ; 

    if [ $? -ne 0 ] ; then 
 
        command="/user ssh-keys import file=${tempName} user=${user} ; " ;

        ssh ${user}@${ip} "${command}" > /dev/null 2>&1 ;

        [ $? -ne 0 ] && return 2 ;
    fi

    mikrotikTestAccess "${user}" "${ip}" "${port}" "${privateKey}" ;

    [ $? -ne 0 ] && return 3 ;

    command="/file remove [find where name=${tempName}]" ;
    
    ssh -o 'PubkeyAcceptedKeyTypes +ssh-rsa' -o BatchMode=yes -i "${privateKey}" ${user}@${ip} "${command}" > /dev/null 2>&1 ;

    return 0 ;
}

function mikrotikBackup() 
{
    local user=$1 ; 
    local ip=$2 ;
    local port=$3 ;
    local privateKey=$4 ;
    local storage=$5 ;
 
    local command=":log info \"BKP - EXECUTANDO .backup\" ; /system backup save name=bkp-${ip} ; " ;

    ssh -o 'PubkeyAcceptedKeyTypes +ssh-rsa' -o BatchMode=yes -i "${privateKey}" ${user}@${ip} "$command" > /dev/null 2>&1 ; 

    local returnn=$?

    command=":log info \"BKP - EXECUTANDO .rsc\" ; /export file=bkp-${ip} ; " ;

    ssh -o 'PubkeyAcceptedKeyTypes +ssh-rsa' -o BatchMode=yes -i "${privateKey}" ${user}@${ip} "$command" > /dev/null 2>&1 ; 

    returnn=$(( $returnn + $? )) ;

    [ $returnn -ne 0 ] && return 2 ; 

    local date=$( date +"%d-%m-%Y-%s" ) ;
    
    local backupDir="${storage}/backup_${ip}_${date}" ;

    local backupDirTarGz="${backupDir}.tar.gz" ;
    
    [ -e "${backupDir}" ] && return 3 ; 

    [ -e "${backupDirTarGz}" ] && return 4 ; 
    
    mkdir "${backupDir}" > /dev/null 2>&1 ;

    [ ! -e "${backupDir}" ] && return 5 ;

    scp -o 'PubkeyAcceptedKeyTypes +ssh-rsa' -o BatchMode=yes -i "${privateKey}" ${user}@${ip}:/bkp-${ip}.backup "${backupDir}" > /dev/null 2>&1 ;

    returnn=$?

    scp -o 'PubkeyAcceptedKeyTypes +ssh-rsa' -o BatchMode=yes -i "${privateKey}" ${user}@${ip}:/bkp-${ip}.rsc "${backupDir}" > /dev/null 2>&1 ;

    returnn=$(( $returnn + $? )) ;

    [ $returnn -ne 0 ] && return 6 ;
   
    tar -czf "${backupDirTarGz}" -C "${backupDir}" . > /dev/null 2>&1 ;

    [ ! -e "${backupDirTarGz}" ] && return 7 ;

    local size=$( du -s "${backupDirTarGz}" | cut -f 1 ) ;

    [ $size -le 0 ] && return 8 ;

    rm -rf "${backupDir}" ;

    return 0 ;
}

