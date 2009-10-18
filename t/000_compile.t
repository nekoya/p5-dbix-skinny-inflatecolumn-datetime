use strict;
use lib './t';
use FindBin::libs;
use Test::More tests => 1;

BEGIN { use_ok 'DBIx::Skinny::InflateColumn::DateTime' }
