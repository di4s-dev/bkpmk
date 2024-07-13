#!/bin/bash

function databaseDeviceInsert() 
{
	local db=$1 ;
	local user=$2 ;
	local ip=$3 ;
	local port=$4 ;

	sqlite3 "${db}" "INSERT INTO devices(user, ip, port) VALUES('${user}', '${ip}', '${port}')" ;
}

function databaseDeviceDelete() 
{
	local db=$1 ;
	local ip=$2 ;

	sqlite3 "${db}" "DELETE FROM devices WHERE ip = '${ip}'" ;
}

function databaseDeviceExists() 
{
	local db=$1 ;
	local ip=$2 ;

	local count=$( sqlite3 "${db}" "SELECT COUNT(*) FROM devices WHERE ip = '${ip}'" ) ;

	[ $count -ge 1 ] && return 0 ;

	return 1 ; 
}

function databaseDeviceAll() 
{
	local db=$1 ;
	
	sqlite3 "${db}" "SELECT user, ip, port FROM devices ORDER BY ip" ;
}

function databaseVersion() 
{
	local db=$1 ;
	
	sqlite3 "${db}" "SELECT val FROM version" ;
}
