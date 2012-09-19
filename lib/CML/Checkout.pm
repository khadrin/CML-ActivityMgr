package CML::Checkout;
use Moose;
use Data::Dumper;
use Carp qw(cluck confess);

use DateTime;
use DateTime::Format::Strptime;
use HTML::Entities;

has '_ua' => (is => 'ro', required => 1);
has '_checkout_row' => (is => 'ro', required => 1);

has 'title' => (is => 'rw');
has 'format' => (is => 'rw');
has 'due_date_orig' => (is => 'rw');
has 'due_date_new' => (is => 'rw');
has 'renew_uri' => (is => 'rw');
has 'flagged' => (is => 'rw', default => 0);

sub BUILD {
    my $self = shift;

    my $ua = $self->_ua; 
    my $base = $ua->base;
    $base =~ s{/[^/]+$}{/};

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
    $renew_uri = decode_entities($renew_uri);
    $renew_uri = $base . $renew_uri if $renew_uri;
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
    my $today = DateTime->today;
    my $days_left = $today->subtract_datetime($self->due_date);

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
    my $self = shift;
    my %p = (noop => 0, @_);

    my $ua = $self->_ua; 
    my $ok = 0;
    $ua->get($self->renew_uri) unless $p{noop};
    my $status = $ua->status;
    if ($status eq '200') {
        my $content = $ua->content;
        my $search_str = 'The new due date for this item is';
        if ($content =~ /$search_str <b>(.{9})<\/b>/s) {
            my $due_date_new = $self->_parse_date_str($1);
            $self->due_date_new($due_date_new);
            $ok = 1;
        }
    }

    return $ok;
}

sub as_hash {
    my $self = shift;
    my $checkout = {
        title => $self->title,
        format => $self->format,
        due_date_new => $self->due_date->strftime("%F"),
        renewable => $self->renewable,
        days_left => $self->days_left,
        was_renewed => $self->was_renewed,
        renew_uri => $self->renew_uri,
    };
    return $checkout;
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

1;
