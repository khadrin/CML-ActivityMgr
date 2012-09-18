package CML::Account;
use Moose;

use WWW::Mechanize;
use HTML::TableContentParser;

use CML::Checkout;

has 'card_number' => (
    is => 'rw',
    required => 1,
);

has 'pin' => (
    is => 'rw',
    required => 1,
);

has 'account_uri' => (
    is => 'ro',
    default => 'http://www.columbuslibrary.org/my_account',
);

has '_account_html' => (is => 'ro', lazy_build => 1);
has '_account_tables' => (is => 'ro', lazy_build => 1);
has 'checkouts' => (is => 'ro', lazy_build => 1);

has '_ua' => (
    is => 'ro',
    lazy => 1,
    default => sub { return WWW::Mechanize->new }
);

has '_table_parser' => (
    is => 'ro',
    lazy => 1,
    default => sub { return HTML::TableContentParser->new }
);

sub _build__account_html {
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

sub _build__account_tables {
    my $self = shift;
    my $table_parser = $self->_table_parser;
    my $account_html = $self->_account_html;
    my $account_tables = $table_parser->parse($account_html);
    return $account_tables;
}

sub _build_checkouts {
    my $self = shift;

    my $ua = $self->_ua;
    my $account_tables = $self->_account_tables;
    my ($checkout_tables) = grep { $_->{id} eq 'check_outs' } @$account_tables;
    my @checkout_rows = grep { exists $_->{cells} } @{$checkout_tables->{rows}};

    my @checkouts = ();
    for my $row (@checkout_rows) {
        my $checkout = CML::Checkout->new(_ua => $ua, _checkout_row => $row);
        push @checkouts, $checkout;
    }

    return \@checkouts;
}

1;
