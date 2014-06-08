package Injector::Blueprint::Literal;
use Moose;

with 'Injector::Blueprint';

use Carp ();

has value => (
    is          => 'ro',
    required    => 1,
);

sub init_meta { }

sub builder {
    my ($self) = @_;

    my $value = $self->value;
    sub { $value };
}

sub implied_scope { 'singleton' }
__PACKAGE__->meta->make_immutable;
