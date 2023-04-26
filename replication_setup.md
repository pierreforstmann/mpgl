#setup node 1 and 2

```
virt-install --name pg<n> --vcpus=2 --memory=2048 --cdrom /home/pierre/Downloads/rhel-8.7-x86_64-boot.iso --disk size=20 --os-variant=rhl8.0

/etc/sysconfig/network-scripts/ifcg-ens3:
IPADDR=92.168.122.<m>
BOOTPRONO=none
GATEWAY=192.168.122.1

reboot
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
dnf -qy module disable postgresql

/usr/pgsql-14/bin/postgresql-14-setup initdb
pg_ctl start

```

