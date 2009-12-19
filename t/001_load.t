use strict;
use lib './t';
use FindBin::libs;
use Test::More tests => 2;

BEGIN {
    use_ok 'Mock::DB';
    use_ok 'Mock::Auto';
}
