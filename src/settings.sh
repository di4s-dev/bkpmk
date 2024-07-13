#!/bin/bash

function settingsGetConfig()
{
    local file=$1 ;
    local key=$2 ;

    cat "${file}" | jq -r "${key}" 2> /dev/null;

    return $? ;
}

function settingsGetDB()
{
    local file=$1 ;

    local db=$( settingsGetConfig "${file}" ".DB" ) ;

    [ $? -ne 0 ] && return 1 ;

    [ "${db}" == "null" ] && return 2 ;

    echo "${db}" ;

    return 0 ; 
}

function settingsGetStorage()
{
    local file=$1 ;

    local storage=$( settingsGetConfig "${file}" ".storage" ) ;

    [ $? -ne 0 ] && return 1 ;

    [ "${storage}" == "null" ] && return 2 ;

    echo "${storage}" ;

    return 0 ; 
}

function settingsGetPublicKey()
{
    local file=$1 ;

    local publicKey=$( settingsGetConfig "${file}" ".publicKey" ) ;

    [ $? -ne 0 ] && return 1 ;

    [ "${publicKey}" == "null" ] && return 2 ;

    echo "${publicKey}" ;

    return 0 ; 
}

function settingsGetPrivateKey()
{
    local file=$1 ;

    local privateKey=$( settingsGetConfig "${file}" ".privateKey" ) ;

    [ $? -ne 0 ] && return 1 ;

    [ "${privateKey}" == "null" ] && return 2 ;

    echo "${privateKey}" ;

    return 0 ; 
}

function settingsGetKeep()
{
    local file=$1 ;

    local keep=$( settingsGetConfig "${file}" ".keep" ) ;

    [ $? -ne 0 ] && return 1 ;

    [ "${keep}" == "null" ] && return 2 ;

    echo "${keep}" ;

    return 0 ; 
}

function settingsGetVersion()
{
    echo '0.0.1' ;
}
