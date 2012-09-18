#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'CML::ActivityMgr' ) || print "Bail out!\n";
}

diag( "Testing CML::ActivityMgr $CML::ActivityMgr::VERSION, Perl $], $^X" );
