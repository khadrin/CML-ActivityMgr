package CML::CheckoutActivity;
use Moose;

use WWW::Mechanize;
use HTML::TableContentParser;

use CML::Checkout;

has '_activity_html' => (is => 'ro', required => 1);
has '_base'          => (is => 'ro', required => 0);
has '_today'         => (is => 'ro', lazy_build => 1);

has '_activity_tables' => (is => 'ro', lazy_build => 1);
has 'checkouts' => (is => 'ro', lazy_build => 1);

has '_table_parser' => (
    is => 'ro',
    lazy => 1,
    default => sub { return HTML::TableContentParser->new }
);

sub _build__activity_tables {
    my $self = shift;
    my $table_parser = $self->_table_parser;
    my $activity_html = $self->_activity_html;
    my $activity_tables = $table_parser->parse($activity_html);
    return $activity_tables;
}

sub _build_checkouts {
    my $self = shift;

    my $today = $self->_today;
    my $activity_tables = $self->_activity_tables;
    my ($checkout_tables) = grep { $_->{id} eq 'check_outs' } @$activity_tables;
    my @checkout_rows = grep { exists $_->{cells} } @{$checkout_tables->{rows}};

    my @checkouts = ();
    for my $row (@checkout_rows) {
        my $checkout = CML::Checkout->new(
            _checkout_row => $row,
            _today => $today,
            _base => $self->_base,
        );
        push @checkouts, $checkout;
    }

    return \@checkouts;
}

sub _build__today {
    my $self = shift;
    my $today = $self->_today;
    return $today;
}

1;
