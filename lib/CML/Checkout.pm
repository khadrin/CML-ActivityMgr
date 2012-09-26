package CML::Checkout;
use Moose;
use Data::Dumper;
use Carp qw(cluck confess);

use DateTime;
use DateTime::Format::Strptime;
use HTML::Entities;

has '_checkout_row' => (is => 'ro', required => 1);
has '_base'         => (is => 'ro', required => 0);
has '_today' => (is => 'rw', lazy_build => 1);

has 'title' => (is => 'rw');
has 'format' => (is => 'rw');
has 'due_date_orig' => (is => 'rw');
has 'due_date_new' => (is => 'rw');
has 'renew_uri' => (is => 'rw');
has 'flagged' => (is => 'rw', default => 0);

sub BUILD {
    my $self = shift;

    my $row = $self->_checkout_row;

    $self->title($row->{cells}[1]{data});
    $self->format($row->{cells}[2]{data});

    my $due_date_str = $row->{cells}[3]{data};
    my $due_date = $self->_parse_date_str($due_date_str);
    $self->due_date_orig($due_date);

    my $actions = $row->{cells}[5]{data};
    my $renew_uri = '';
    if ($actions =~ /href="(Renew.jsp[^"]+)"/s) {
        $renew_uri = $1;
    }
    # decode entities in renewal_uri or can't renew
    if ($renew_uri) {
        $renew_uri = decode_entities($renew_uri);
        $renew_uri = $self->_base . $renew_uri;
    }
    $self->renew_uri($renew_uri);
}

sub due_date {
    my $self = shift;
    return $self->due_date_new ? $self->due_date_new : $self->due_date_orig;
}

sub was_renewed {
    my $self = shift;
    return $self->due_date_new ? 1 : 0;
}

sub days_left {
    my $self = shift;
    my $today = $self->_today;
    my $days_left = $self->due_date->subtract_datetime($today);

    return $days_left->delta_days;
}

sub expired {
    my $self = shift;
    return ($self->days_left <= 0) ? 1 : 0;
}

sub renewable {
    my $self = shift;
    my $renewable = $self->renew_uri ? 1 : 0;
    return $renewable;
}

sub renew {
    my $usage = 'usage: $checkout->renew(new_date_str)';
    my $self = shift;
    my %p = @_;
    confess $usage unless $p{new_date_str};

    my $due_date_new = $self->_parse_date_str($p{new_date_str});
    $self->due_date_new($due_date_new);
}

sub _parse_date_str {
    my $self = shift;
    my $date_str = shift;

    my $date_parser = DateTime::Format::Strptime->new(
        pattern => '%d%B%Y',
    );
    my $date = $date_parser->parse_datetime($date_str);
    return $date;
}

sub _build__today {
    my $self = shift;
    my $today = $self->_today;
    return $today;
}

1;
