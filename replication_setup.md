## setup node 1 and node 2

```
virt-install --name pg1 --vcpus=2 --memory=2048 --cdrom rhel-8.7-x86_64-boot.iso --disk size=20 --os-variant=rhl8.0
virt-install --name pg2 --vcpus=2 --memory=2048 --cdrom rhel-8.7-x86_64-boot.iso --disk size=20 --os-variant=rhl8.0

pg1:/etc/sysconfig/network-scripts/ifcg-ens3:
IPADDR=192.168.122.51
BOOTPROTO=none
GATEWAY=192.168.122.1

pg2:/etc/sysconfig/network-scripts/ifcg-ens3:
IPADDR=192.168.122.132
BOOTPROTO=none
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
initdb
pg_ctl start

mkdir /var/lib/pgsql/backup
mkdir /var/lib/pgsql/archive

postgresql.conf:
wal_level=replica
archive_mode=on
archive_command='cp %p /var/lib/pgsql/archive/%f'
restore_command='cp /var/lib/pgsql/archive/%f %p'
listen_addresses='*'

pg_hba.conf:
host    replication     all             192.168.122.132/24      trust

pg_ctl stop
pg_ctl start
 
psql -c 'create user repuser replication';

```

## setup standby

```
mkdir /var/lib/pgsql/backup
mkdir /var/lib/pgsql/archive

pg_basebackup -h pg1 -U repuser -X s -D $PGDATA

postgresql.conf:
wal_level=replica
primary_conninfo = 'host=pg1 port=5432 user=repuser'
listen_addresses='*'
archive_mode=on
archive_command='cp %p /var/lib/pgsql/archive/%f'
restore_command='cp /var/lib/pgsql/archive/%f %p'

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
pg_basebackup -h localhost -p 5432 -X s -U repuser -D backup/1708
```

## create table on primary
```
psql -c 'create table t1708(x int);'
```

## WAL switch
```
psql -c 'select pg_switch_wal();'
```

## drop table on primary
```
psql
drop table t1708;
exit
```

## restore primary
```
pg_ctl stop
rm -rf $PGDATA
cp -r backup/1708 $PGDATA

postgresql.conf:
recovery_target_time='2023-04-26 17:09:30'
recovery_target_action=promote

touch $PGDATA/recovery.signal
pg_ctl start
```

## check primary log
```

LOG:  starting PostgreSQL 14.7 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-16), 64-bit
LOG:  listening on IPv4 address "0.0.0.0", port 5432
LOG:  listening on IPv6 address "::", port 5432
LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
LOG:  database system was interrupted; last known up at 2023-04-26 17:08:09 CEST
cp: cannot stat '/var/lib/pgsql/archive/00000002.history': No such file or directory
LOG:  starting point-in-time recovery to 2023-04-26 17:09:30+02
LOG:  restored log file "000000010000000000000005" from archive
LOG:  redo starts at 0/5000028
LOG:  consistent recovery state reached at 0/5000100
database system is ready to accept read-only connections
LOG:  restored log file "000000010000000000000006" from archive
LOG:  restored log file "000000010000000000000007" from archive
LOG:  recovery stopping before commit of transaction 735, time 2023-04-26 17:10:26.080966+02
LOG:  redo done at 0/70003D0 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.06 s
LOG:  last completed transaction was at log time 2023-04-26 17:08:31.203751+02
cp: cannot stat '/var/lib/pgsql/archive/00000002.history': No such file or directory
LOG:  selected new timeline ID: 2
LOG:  archive recovery complete
cp: cannot stat '/var/lib/pgsql/archive/00000001.history': No such file or directory
LOG:  database system is ready to accept connections
ERROR:  requested starting point 0/9000000 on timeline 1 is not in this server's history
DETAIL:  This server's history forked from timeline 1 at 0/70003D0.
STATEMENT:  START_REPLICATION 0/9000000 TIMELINE 1
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

pg_ctl start
```

## check standby log
```
LOG:  starting PostgreSQL 14.7 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 8.5.0 20210514 (Red Hat 8.5.0-16), 64-bit
LOG:  listening on IPv4 address "0.0.0.0", port 5432
LOG:  listening on IPv6 address "::", port 5432
LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
LOG:  database system was interrupted; last known up at 2023-04-26 17:38:44 CEST
LOG:  entering standby mode
LOG:  redo starts at 0/8000028
LOG:  consistent recovery state reached at 0/8000138
LOG:  database system is ready to accept read-only connections
LOG:  started streaming WAL from primary at 0/9000000 on timeline 2
```

## check replication on primary
```
psql
\x
select * from pg_stat_replication;
exit
```

## check replication on standby
```
psql
\x
select * from pg_stat_wal_receiver;
exitt
```
