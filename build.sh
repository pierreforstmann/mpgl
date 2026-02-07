#!/bin/bash
#
# build.sh
#
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
mkdir target
make install
#
pg_ctl stop
rm -rf $PGDATA
initdb -m oracle
pg_ctl -D /home/ivory/data -l logfile start
createdb ivory
