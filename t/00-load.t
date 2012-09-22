#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'CML::ActivityMgr' ) || print "Bail out!\n";
    use_ok( 'CML::Account' ) || print "Bail out!\n";
    use_ok( 'CML::Checkout' ) || print "Bail out!\n";
}

#diag( "Testing CML::ActivityMgr $CML::ActivityMgr::VERSION, Perl $], $^X" );
