## setup node 1 and node 2

```
virt-install --name pg<n> --vcpus=2 --memory=2048 --cdrom rhel-8.7-x86_64-boot.iso --disk size=20 --os-variant=rhl8.0

/etc/sysconfig/network-scripts/ifcg-ens3:
IPADDR=92.168.122.<m>
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
  
