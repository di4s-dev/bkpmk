#!/bin/bash

readonly DIR="$( dirname $0 )" ;

readonly SETTINGS_FILE=${DIR}/../config/settings.json ;

source ${DIR}/settings.sh ;
source ${DIR}/utils.sh ;
source ${DIR}/database.sh ;
source ${DIR}/mikrotik.sh ;

function addDevice() 
{
    local user=$3 ;
    local ip=$4 ;
    local port=$5 ;


    local db=$( settingsGetDB "${SETTINGS_FILE}" ) ;
   
    testDB "${db}" ; 

    [ $? -ne 0 ] && echo "'DB' inválido" && return 1 ;


    local privateKey=$( settingsGetPrivateKey "${SETTINGS_FILE}" ) ;

    [ $? -ne 0 ] && echo "'PrivateKey' não encontrado" && return 2 ;
    
    utilsIsValidPrivateKey "${privateKey}" ;

    [ $? -ne 0 ] && echo "'PrivateKey' é inválido" && return 2 ;

    
    utilsIsValidUser "${user}" ;

    [ $? -ne 0 ] && echo "'Usuário' é inválido" && return 3 ;


    utilsIsValidIP "${ip}" ;

    [ $? -ne 0 ] && echo "'IP' é inválido" && return 4 ;


    utilsIsValidPort "${port}" ;

    [ $? -ne 0 ] && echo "'Porta' é inválida" && return 5 ;


    databaseDeviceExists "${db}" "${ip}" ; 

    [ $? -eq 0 ] && echo "Já existe um device com o IP ${ip}" && return 6 ;


    mikrotikTestAccess "${user}" "${ip}" "${port}" "${privateKey}" ;

    if [ $? -ne 0 ] ; then 

        echo "Não foi possível acessar o device, tentando enviar e importar a chave pública" ;

        local publicKey=$( settingsGetPublicKey "${SETTINGS_FILE}" ) ;
   
        [ $? -ne 0 ] && echo "'PubKey' não encontrado" && return 7 ;

        utilsIsValidPublicKey "${publicKey}" ;

        [ $? -ne 0 ] && echo "'PublicKey' é inválida. Use ssh-rsa" && return 8 ;

        mikrotikImportKey "${user}" "${ip}" "${port}" "${publicKey}" ;

        [ $? -ne 0 ] && echo "A chave não foi importada, verifique o device antes de tentar novamente" && return 9 ;
    fi

    databaseDeviceInsert "${db}" "${user}" "${ip}" "${port}" ;
    
    [ $? -ne 0 ] && echo "Não foi possível atualizar o DB" && return 10 ;

    echo "O device foi adicionado com sucesso" ;

    return 0 ;
}

function listDevices() 
{
    local db=$( settingsGetDB "${SETTINGS_FILE}" ) ;
   
    testDB "${db}" ; 

    [ $? -ne 0 ] && echo "'DB' é inválido" && return 1 ;

    databaseDeviceAll "${db}" ;
    
    return 0 ;
}

function removeDevice() 
{
    local ip=$3 ;

    local db=$( settingsGetDB "${SETTINGS_FILE}" ) ;
   
    testDB "${db}" ; 

    [ $? -ne 0 ] && echo "'DB' inválido" && return 1 ;

    utilsIsValidIP "${ip}" ;

    [ $? -ne 0 ] && echo "IP inválido" && return 2 ;


    databaseDeviceExists "${db}" "${ip}" ;

    [ $? -ne 0 ] && echo "Nenhum device com o IP ${ip} foi encontrado" && return 3 ;

    databaseDeviceDelete "${db}" "${ip}" ;
    
    [ $? -ne 0 ] && echo "Não foi possível atualizar o DB" && return 4 ;
    
    echo "O device foi removido com sucesso" ;

    return 0 ;
}

function executeBackup()
{
    local user='' ;
    local ip='' ; 
    local port='' ;

    local db=$( settingsGetDB "${SETTINGS_FILE}" ) ;
   
    testDB "${db}" ; 

    [ $? -ne 0 ] && echo "'DB' é inválido" && return 1 ;

    
    local storage=$( settingsGetStorage "${SETTINGS_FILE}" ) ;
   
    [ $? -ne 0 ] && echo "'Storage' não encontrado" && return 2 ;
    [ ! -d "${storage}" ] && echo "'Storage' não encontrado" && return 2 ;


    local keep=$( settingsGetKeep "${SETTINGS_FILE}" ) ;
   
    [ $? -ne 0 ] && echo "'Keep' não encontrado" && return 2 ;

    utilsIsValidKeep "${keep}" ;

    [ $? -ne 0 ] && echo "'Keep' é inválido" && return 2 ;


    local privateKey=$( settingsGetPrivateKey "${SETTINGS_FILE}" ) ;

    [ $? -ne 0 ] && echo "'PrivateKey' não encontrado" && return 3 ;
    
    utilsIsValidPrivateKey "${privateKey}" ;

    [ $? -ne 0 ] && echo "'PrivateKey' é inválido" && return 3 ;


    local devices=$( databaseDeviceAll "${db}" );

    [ $? -ne 0 ] && echo "Não foi possível acessar a lista de devices" && return 3 ;

    local device='' ;

    for device in $devices ; do

        user=$( echo "${device}" | cut -d '|' -f 1 );
        ip=$( echo "${device}" | cut -d '|' -f 2 );
    	port=$( echo "${device}" | cut -d '|' -f 3 );


    	utilsIsValidUser "${user}" ;

    	[ $? -ne 0 ] && continue ;

    	
	    utilsIsValidIP "${ip}" ;

    	[ $? -ne 0 ] && continue ;

    	
        utilsIsValidPort "${port}" ;

    	[ $? -ne 0 ] && continue ;

        
        mikrotikBackup "${user}" "${ip}" "${port}" "${privateKey}" "${storage}" ;
 
        if [ $? -ne 0 ] ; then 
                
            echo "Falha: ${ip}" ;

            continue ;
        fi

        echo "Realizado backup: ${ip}" ;

    	local count=$( ls -1t "${storage}"/backup*"${ip}"*.tar.gz | wc -l ) ;

        if [ $count -gt $keep ] ; then 

            local last=$( ls -1t "${storage}"/backup*"${ip}"*.tar.gz | tail -1 ) ;

            rm -f "${last}" ; 
	    fi
    done 
}

function executeHelp()
{
	echo 'bkpmk device add {user} {ip} {port}' ;
	echo 'bkpmk device list  ' ;
	echo 'bkpmk device remove {ip}  ' ;
	echo '' ;
	echo 'Executa o backup para todos os devices: ' ;
	echo 'bkmk backup ' ;
	echo '' ;
}

function executeDevice()
{
	local method=$2 ;

	case $method in
        add)
            addDevice $@ ;
            ;;

	    list) 
            listDevices ;
            ;;
        
	    remove) 
            removeDevice $@ ;
            ;;
	
	    *) executeHelp ;;
        esac
}

function testDB()
{
    local db=$1 ;
 
    [ -z "${db}" ] && return 1 ;
    
    [ ! -e "${db}" ] && return 2 ;

    local dbVersion=$( databaseVersion "${db}" ) ;
    local settingsVersion=$( settingsGetVersion ) ;

    [ "${dbVersion}" != "${settingsVersion}" ] && return 3 ;

    return 0 ;
}

function main()
{
	local option=$1 ;

    [ $( id -u ) -eq 0 ] && echo 'Não execute como root' && return 99 ;

	case $option in
        device) 
            executeDevice $@ ; 
            ;;
        
      	backup) 
            executeBackup ;
            ;;
      	   
	    *) 
            executeHelp ;
            ;;
    esac
}

main $@ ; 

