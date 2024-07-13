create table devices (
    id integer primary key autoincrement,
    user varchar(50) not null,
    ip varchar(40) not null unique,
    port integer not null
);

create table version (
    id integer primary key autoincrement,
    version varchar(10) not null
);

insert into version(version) values ('0.0.1');

