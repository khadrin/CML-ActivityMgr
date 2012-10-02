package CML::ActivityMgr;
use Moose;
our $VERSION = '1.00';

=head1 NAME

CML::ActivityMgr - Columbus Metro Library activity manager and auto-renewer.

=head1 VERSION

Version 1.00

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

use CML::CheckoutActivity;

has owner       => (is => 'ro', required => 1);
has card_number => (is => 'ro');
has pin         => (is => 'ro');

has '_activity_html' => (is => 'ro', lazy_build => 1);

sub BUILD {
    my $usage = 'usage: CML::ActivityMgr->new(owner {card_number pin}|{_activity_html})';
    my $self = shift;
    confess $usage unless $self->owner && (($self->card_number && $self->pin) || $self->_activity_html);
}

has 'account_uri' => (
    is => 'ro',
    default => 'http://www.columbuslibrary.org/my_account',
);

has 'webservice_base_uri' => (
    is => 'ro',
    default => 'https://dpweb.columbuslibrary.org/servlet_jsp/MyAccount2/',
);

has checkouts  => (is => 'rw', lazy_build => 1);

has _share_dir => (is => 'rw', lazy_build => 1);
has _tt        => (is => 'rw', lazy_build => 1);
has '_today'   => (is => 'rw', lazy_build => 1);

has '_ua' => (
    is => 'ro',
    lazy => 1,
    default => sub { return WWW::Mechanize->new }
);

sub _build__activity_html {
    my $self = shift;

    my $ua = $self->_ua;
    $ua->get($self->account_uri);

    my $form = $ua->form_name('Login');
    if ($form) {
        $ua->set_fields(
            patronid  => $self->card_number,
            patronpin => $self->pin,
        );
        $ua->click;
    }

    my $status = $ua->status;
    confess "my-account page returned status ($status)"
        unless $status eq '200';
    my $account_html = $ua->content;
    return $account_html;
}

sub _build__today {
    my $self = shift;
    my $today = DateTime->today;
    return $today;
}

sub _build_checkouts {
    my $self = shift;
    my $activity_html = $self->_activity_html;
    my $base = $self->webservice_base_uri;
    my $today = $self->_today;

    my $checkout_activity = CML::CheckoutActivity->new(
        _activity_html => $activity_html,
        _base          => $base,
        _today         => $today,
    );

    my $checkouts = $checkout_activity->checkouts;
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
    my $usage = 'usage: $mgr->renew([days_left] [fake])';
    my $self = shift;
    my %p = (days_left => 0, fake => 0, @_);

    my $ua = $self->_ua;
    my $today = $self->_today;
    my $fake_renew_date = $today->clone->add(days => 14);
    my $fake_renew_str = $fake_renew_date->strftime("%d%b%Y");

    my $n_renewed = 0;
    my $checkouts = $self->checkouts;
    for my $checkout (@$checkouts) {
        if ($checkout->renewable && $checkout->days_left <= $p{days_left}) {
            my $ok = 0;

            my $renew_uri = $checkout->renew_uri;
            my $status = '200';
            unless ($p{fake}) {
                $ua->get($renew_uri);
                $status = $ua->status;
            }
            if ($status eq '200') {
                my $content = "The new due date for this item is <b>$fake_renew_str<\/b>";
                $content = $ua->content unless $p{fake};
                my $search_str = 'The new due date for this item is';
                if ($content =~ /$search_str <b>(.{9})<\/b>/s) {
                    $checkout->renew(new_date_str => $1);
                    $ok = 1;
                }
            }
            $checkout->flagged($ok ? 0 : 1);
        }
    }

    return $n_renewed;
}

sub flag {
    my $usage = 'usage: $mgr->flag([nonrenewable_days_left] [renewable_days_left])';
    my $self = shift;
    my %p = (nonrenewable_days_left => 6, renewable_days_left => 0, @_);

    my $n_flagged = 0;
    my $checkouts = $self->checkouts;
    for my $checkout (@$checkouts) {
        if (!$checkout->renewable && $checkout->days_left <= $p{nonrenewable_days_left}) {
            $checkout->flagged(1);
            ++$n_flagged;
        }

        if ($checkout->renewable && $checkout->days_left <= $p{renewable_days_left}) {
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

    my $checkouts_sorted = [sort {DateTime->compare($a->due_date_orig, $b->due_date_orig)} @$checkouts];

    my $tt_vars = {
        owner => $self->owner,
        checkouts => $checkouts_sorted,
        today => $self->_today->strftime("%F"),
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
