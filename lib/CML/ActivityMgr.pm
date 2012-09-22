package CML::ActivityMgr;
use Moose;
our $VERSION = '0.05';

=head1 NAME

CML::ActivityMgr - Columbus Metro Library activity manager and auto-renewer.

=head1 VERSION

Version 0.05

=cut

use strict;
use warnings;

use Data::Dumper;
use Carp qw(cluck confess);

use DateTime;
use File::ShareDir qw(dist_dir);
use Cwd;
use Template;
use Email::MIME::CreateHTML;

use CML::Account;

has owner       => (is => 'rw', required => 1);
has card_number => (is => 'rw', required => 1);
has pin         => (is => 'rw', required => 1);

has _account   => (is => 'rw', lazy_build => 1);
has checkouts  => (is => 'rw', lazy_build => 1);

has _share_dir => (is => 'rw', lazy_build => 1);
has _tt        => (is => 'rw', lazy_build => 1);
has '_today'   => (is => 'rw', lazy_build => 1);

sub _build__today {
    my $self = shift;
    my $today = DateTime->today;
    return $today;
}

sub _build__account {
    my $self = shift;

    my $account = CML::Account->new(
        card_number => $self->card_number,
        pin => $self->pin,
        _today => $self->_today
    );
    return $account;
}

sub _build_checkouts {
    my $self = shift;
    my $account = $self->_account;

    my $checkouts = $account->checkouts;
    return $checkouts;
}

sub _build__share_dir {
    my $share_dir = getcwd;
    eval {
        $share_dir = dist_dir('CML-ActivityMgr')
    };
    warn $@ if $@;
    return $share_dir;
}

sub _build__tt {
    my $self = shift;
    my $share_dir = $self->_share_dir;

    my $tt = Template->new(INCLUDE_PATH => "$share_dir/templates");
    return $tt;
}

sub renew {
    my $usage = 'usage: $mgr->renew([days_left] [noop])';
    my $self = shift;
    my %p = (days_left => 0, noop => 0, @_);

    my $n_renewed = 0;
    my $checkouts = $self->checkouts;
    for my $checkout (@$checkouts) {
        if ($checkout->renewable && $checkout->days_left <= $p{days_left}) {
            my $ok = $checkout->renew(noop => $p{noop});
            $checkout->flagged(1) unless $ok;
        }
    }

    return $n_renewed;
}

sub flag_nonrenewable {
    my $usage = 'usage: $mgr->flag_nonrenewable([days_left])';
    my $self = shift;
    my %p = (days_left => 6, @_);

    my $n_flagged = 0;
    my $checkouts = $self->checkouts;
    for my $checkout (@$checkouts) {
        if (!$checkout->renewable && $checkout->days_left <= $p{days_left}) {
            $checkout->flagged(1);
            ++$n_flagged;
        }
    }

    return $n_flagged;
}

sub activity_report {
    my $usage = 'usage: $mgr->report';
    my $self = shift;

    my $tt = $self->_tt;
    my $share_dir = $self->_share_dir;
    my $checkouts = $self->checkouts;

    my $checkouts_sorted = [sort {DateTime->compare($a->due_date, $b->due_date)} @$checkouts];

    my $tt_vars = {
        owner => $self->owner,
        checkouts => $checkouts_sorted,
        today => DateTime->today->strftime("%F"),
    };

    my $report = '';
    $tt->process('activity_report.tt.html', $tt_vars, \$report)
        or confess($tt->error);

    return $report;
}

sub activity_email {
    my $usage = 'usage: $mgr->activity_email';
    my $self = shift;

    my $html = $self->activity_report;

    my $subject = '[CML] Account Activity for ' . $self->owner;
    my $email = Email::MIME->create_html(
        header => [ Subject => $subject ],
        body => $html,
    );
    return $email;
}

=head1 SYNOPSIS

Renews library books and emails a report.

    cml-activity-mgr

=head1 AUTHOR

Stephen J. Smith, C<< <sjs at khadrin.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CML::ActivityMgr

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stephen J. Smith.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of CML::ActivityMgr
