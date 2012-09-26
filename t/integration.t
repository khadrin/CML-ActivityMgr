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

my $checkouts = $activity_mgr->checkouts;
$activity_mgr->flag(nonrenewable_days_left => 6, renewable_days_left => 0);

is($checkouts->[0]->flagged, 1, 'pre-renew: checkout 0 is flagged');
is($checkouts->[0]->was_renewed, 0, 'pre-renew: checkout 0 was not renewed');
is($checkouts->[0]->days_left, 0, 'pre-renew: checkout 0 has 0 days remaining');
is($checkouts->[0]->expired, 1, 'pre-renew: checkout 0 is expired');
is($checkouts->[0]->renewable, 1, 'pre-renew: checkout 0 is renewable');
like($checkouts->[0]->renew_uri, qr/^http/, 'pre-renew: checkout 0 renew_uri starts with http scheme');

is($checkouts->[1]->flagged, 1, 'pre-renew: checkout 1 is flagged');
is($checkouts->[1]->was_renewed, 0, 'pre-renew: checkout 1 was not renewed');
is($checkouts->[1]->days_left, 2, 'pre-renew: checkout 1 has 2 days remaining');
is($checkouts->[1]->expired, 0, 'pre-renew: checkout 1 is not expired');
is($checkouts->[1]->renewable, 0, 'pre-renew: checkout 1 is not renewable');
is($checkouts->[1]->renew_uri, '', 'pre-renew: checkout 1 renew_uri is empty');

is($checkouts->[2]->flagged, 0, 'pre-renew: checkout 2 is not flagged');
is($checkouts->[2]->was_renewed, 0, 'pre-renew: checkout 2 was not renewed');
is($checkouts->[2]->days_left, 4, 'pre-renew: checkout 2 has 4 days remaining');
is($checkouts->[2]->expired, 0, 'pre-renew: checkout 2 is not expired');
is($checkouts->[2]->renewable, 1, 'pre-renew: checkout 2 is renewable');

$activity_mgr->renew(days_left => 0, fake => 1);
$activity_mgr->flag(nonrenewable_days_left => 6, renewable_days_left => 0);

is($checkouts->[0]->flagged, 0, 'post-renew: checkout 0 is not flagged');
is($checkouts->[0]->was_renewed, 1, 'post-renew: checkout 0 was renewed');
is($checkouts->[0]->days_left, 14, 'post-renew: checkout 0 has 14 days remaining');
is($checkouts->[0]->expired, 0, 'post-renew: checkout 0 is not expired');
is($checkouts->[0]->renewable, 1, 'post-renew: checkout 0 is renewable');
like($checkouts->[0]->renew_uri, qr/^http/, 'post-renew: checkout 0 renew_uri starts with http scheme');

is($checkouts->[1]->flagged, 1, 'post-renew: checkout 1 is flagged');
is($checkouts->[1]->was_renewed, 0, 'post-renew: checkout 1 was not renewed');
is($checkouts->[1]->days_left, 2, 'post-renew: checkout 1 has 2 days remaining');
is($checkouts->[1]->expired, 0, 'post-renew: checkout 1 is not expired');
is($checkouts->[1]->renewable, 0, 'post-renew: checkout 1 is not renewable');
is($checkouts->[1]->renew_uri, '', 'post-renew: checkout 1 renew_uri is empty');

is($checkouts->[2]->flagged, 0, 'post-renew: checkout 2 is not flagged');
is($checkouts->[2]->was_renewed, 0, 'post-renew: checkout 2 was not renewed');
is($checkouts->[2]->days_left, 4, 'post-renew: checkout 2 has 4 days remaining');
is($checkouts->[2]->expired, 0, 'post-renew: checkout 2 is not expired');
is($checkouts->[2]->renewable, 1, 'post-renew: checkout 2 is renewable');

done_testing();
