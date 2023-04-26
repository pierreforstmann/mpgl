## setup node 1 and node 2

```
virt-install --name pg<n> --vcpus=2 --memory=2048 --cdrom rhel-8.7-x86_64-boot.iso --disk size=20 --os-variant=rhl8.0

/etc/sysconfig/network-scripts/ifcg-ens3:
IPADDR=192.168.122.<m>
BOOTPRONO=none
GATEWAY=192.168.122.1

reboot

systemctl stop firewalld
systemctl disable firewalld

dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql
dnf install -y postgresql14-server

```

## setup primary

```
/usr/pgsql-14/bin/postgresql-14-setup initdb
pg_ctl start

mkdir /var/lib/pgsql/backup
mkdir /var/lib/pgsql/archive

postgresql.conf:
wal_level=replica
archive_mode=on
archive_command='cp %p /var/lib/pgsql/archive/%f'
listen_addresses='*'

pg_hba.conf:
host    replication     all             192.168.122.<m>/24      trust

pg_ctl stop
pg_ctl start
 
psql
create user repuser replication;
exit

```

## setup standby

```
pg_basebackup -h pg1 -U repuser -X s -D $PGDATA

postgresql.conf:
wal_level=replica
primary_conninfo = 'host=pg1 port=5432 user=repuser'
listen_addresses='*'

touch $PGDATA/standby.signal
pg_ctl stop
pg_ctl start
```

## check standby log
```
LOG:  entering standby mode
LOG:  redo starts at 0/B000028
LOG:  consistent recovery state reached at 0/B000138
LOG:  database system is ready to accept read-only connections
LOG:  started streaming WAL from primary at 0/C000000 on timeline 1
```

## backup primary
```
pg_basebackup -h localhost -p 5432 -X s -U repuser -D backup/HHMM
```

## create table on primary
```
psql
create table tHH1MM1(x int);
exit
```

## backup primary
```
pg_basebackup -h localhost -p 5432 -X s -U repuser -D backup/HH2MM2
```

## drop table on primary
```
psql
drop table tHH1MM1;
exit
```

## restore primary
```
pg_ctl stop
cp -r backup/HH2MM2 $PGDATA
pg_ctl start
```

## check primary log
```
LOG:  starting PostgreSQL 14.7 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-16), 64-bit
LOG:  listening on IPv4 address "0.0.0.0", port 5432
LOG:  listening on IPv6 address "::", port 5432
LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
LOG:  database system was interrupted; last known up at ...
LOG:  redo starts at 0/D000028
LOG:  consistent recovery state reached at 0/D000100
LOG:  redo done at 0/D000100 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
LOG:  database system is ready to accept connections
ERROR:  requested starting point 0/F000000 is ahead of the WAL flush position of this server 0/E0000A0
STATEMENT:  START_REPLICATION 0/F000000 TIMELINE 1
```

## rebuild standby

```
pg_ctl stop
rm -rf $PGDATA
pg_basebackup -h pg1 -U repuser -X s -D $PGDATA
touch $PGDATA/standby.signal


postgresql.conf:
listen_addresses='*'
wal_level=replica
primary_conninfo = 'host=pg1 port=5432 user=repuser'
#archive_mode=on
#"archive_command='cp %p /var/lib/pgsql/archive/%f'

pg_ctl start
```
