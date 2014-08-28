package Bolts::Blueprint::Literal;
use Moose;

with 'Bolts::Blueprint';

use Carp ();

has value => (
    is          => 'ro',
    required    => 1,
);

sub builder {
    my ($self) = @_;

    my $value = $self->value;
    sub { $value };
}

sub implied_scope { 'singleton' }

__PACKAGE__->meta->make_immutable;