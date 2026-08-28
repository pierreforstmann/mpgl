# HOWTO add a new TAP test

Create a new directory:

```
mkdir src/test/tap
```
Create a Makefile in ```src/test/tap```:

```
#-------------------------------------------------------------------------
#
# Makefile for src/test/tap
#
# Portions Copyright (c) 1996-2026, PostgreSQL Global Development Group
# Portions Copyright (c) 1994, Regents of the University of California
#
# src/test/tap/Makefile
#
#-------------------------------------------------------------------------

subdir = src/test/tap
top_builddir = ../../..
include $(top_builddir)/src/Makefile.global

check:
	$(prove_check)

installcheck:
	$(prove_installcheck)

clean distclean:
	rm -rf tmp_check
```

Create corresponding `t` directory:

```
mkdir src/test/tap/t
```
In ```t``` directory create perl script ```001_basic_test.pl̀``` :

```
use strict;
use warnings FATAL => 'all';
use PostgreSQL::Test::Cluster;
use PostgreSQL::Test::Utils;
use Test::More;

# 1. Initialize a new PostgreSQL test cluster node
my $node = PostgreSQL::Test::Cluster->new('primary_node');
$node->init;

# 2. Start the database cluster
$node->start;

# 3. Run a query against the cluster using safe_psql
my $result = $node->safe_psql('postgres', 'SELECT 42;');

# 4. Assert the result using Test::More
is($result, '42', 'SELECT 42 returns 42 successfully');

# 5. Clean up and stop the cluster
$node->stop('fast');

# Finish testing
done_testing();
```

Run the test with ```make check```. Output should end with:
```
 +++ tap check in src/test/tap +++
t/001_basic_test.pl .. ok   
All tests successful.
Files=1, Tests=1,  1 wallclock secs ( 0.01 usr  0.01 sys +  0.06 cusr  0.11 csys =  0.19 CPU)
Result: PASS
```






