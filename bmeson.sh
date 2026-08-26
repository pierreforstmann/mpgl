#!/bin/bash
#
# bmeson.sh
#
# build PG from source with postgres account
# with meson
#
#
# -----------------------------------------------
export PGDATA=/var/lib/pgsql/data
export TARGET=/var/lib/pgsql/local
set -x
#
rm -rf build
make distclean
meson setup build --prefix=$TARGET --buildtype=debug -Dcassert=true -Duuid=e2fs -Dssl=openssl -Dtap_tests=enabled  -Dliburing=enabled
cd build
ninja
# 
rm -rf $TARGET
mkdir $TARGET 
#
ninja install
ninja install-test-files
#
export PATH=$TARGET/bin:$PATH
#
pg_ctl stop
rm -rf $PGDATA
initdb 
#
echo "logging_collector = on" > $PGDATA/mypg.conf
echo "log_directory = 'log'" >> $PGDATA/mypg.conf
echo "log_filename = 'pg.log'" >> $PGDATA/mypg.conf
echo "include = 'mypg.conf'" >> $PGDATA/postgresql.conf
#
pg_ctl -D $PGDATA -l logfile start
#
cd ..
# make check
meson test -C build --print-errorlogs --suite setup --suite regress
# make installcheck-world
meson test -C build -q --print-errorlogs --setup running
