#!/bin/bash
#
# build.sh
#
# build IvorySQL from source with 'ivory' account
#
# -----------------------------------------------
export PGDATA=/home/ivory/data
export TARGET=/home/ivory/local
set -x
#
cd ~/IvorySQL
make clean
 ./configure --prefix=$TARGET --enable-debug --with-uuid=e2fs
make
make check
make oracle-check
#
rm -rf $TARGET
mkdir $TARGET 
make install
#
pg_ctl stop
rm -rf $PGDATA
initdb -m oracle
pg_ctl -D $PGDATA -l logfile start
createdb ivory
