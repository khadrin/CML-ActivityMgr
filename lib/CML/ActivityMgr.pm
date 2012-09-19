package CML::ActivityMgr;
use Moose;

use strict;
use warnings;

use Data::Dumper;
use Carp qw(cluck confess);

use DateTime;
use File::ShareDir qw(dist_dir);
use Cwd;

use Email::MIME::Kit;

use CML::Account;

has 'owner'       => (is => 'rw', required => 1);
has 'card_number' => (is => 'rw', required => 1);
has 'pin'         => (is => 'rw', required => 1);

has '_account' => (is => 'rw', lazy_build => 1);
has 'checkouts' => (is => 'rw', lazy_build => 1);

sub _build__account {
    my $self = shift;

    my $account = CML::Account->new(card_number => $self->card_number, pin => $self->pin);
    return $account;
}

sub _build_checkouts {
    my $self = shift;
    my $account = $self->_account;

    my $checkouts = $account->checkouts;
    return $checkouts;
}

sub renew {
    my $usage = 'usage: $mgr->renew([days_left] [noop])';
    my $self = shift;
    my %p = (days_left => 1, noop => 0, @_);

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
    my %p = (days_left => 7, @_);

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

sub activity_email {
    my $usage = 'usage: $mgr->activity_email';
    my $self = shift;

    my $checkouts = $self->checkouts;

    my $checkouts_sorted = [sort {DateTime->compare($a->due_date, $b->due_date)} @$checkouts];
    my $tt_vars = { checkouts => $checkouts_sorted };


    my $share_dir = getcwd;
    eval {
        $share_dir = dist_dir('CML-ActivityMgr')
    };
    warn $@ if $@;
    
    my $kit = Email::MIME::Kit->new({source => "$share_dir/mkits/activity"});
    my $email = $kit->assemble($tt_vars);
    return $email;
}

=head1 NAME

CML::ActivityMgr - The great new CML::ActivityMgr!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use CML::ActivityMgr;

    my $foo = CML::ActivityMgr->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Stephen J. Smith, C<< <sjs at khadrin.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cml-activitymgr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CML-ActivityMgr>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CML::ActivityMgr


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CML-ActivityMgr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CML-ActivityMgr>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CML-ActivityMgr>

=item * Search CPAN

L<http://search.cpan.org/dist/CML-ActivityMgr/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Stephen J. Smith.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CML::ActivityMgr
