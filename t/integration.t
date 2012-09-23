#!/usr/bin/perl

use Test::More;

use DateTime;
use File::Slurp;

use CML::ActivityMgr;

my $activity_html = read_file('t/data/my-account-activity.html');
my $today = DateTime->from_epoch(epoch => 1348272000); # 2012-09-22

my $activity_mgr = CML::ActivityMgr->new(
    owner => 'Stephen',
    _activity_html => $activity_html,
    _today => $today,
);

print $activity_mgr->activity_report;
