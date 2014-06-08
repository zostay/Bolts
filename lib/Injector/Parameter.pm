package Injector::Parameter;
use Moose;

has key => (
    is          => 'ro',
    isa         => 'Str|Int',
);

has inject_via => (
    is          => 'ro',
    does        => 'Injector::Injector',
    required    => 1,
);

has isa => (
    is          => 'ro',
    isa         => 'Moose::Meta::TypeConstraint',
);

has optional => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has does => (
    is          => 'ro',
    isa         => 'Moose::Meta::TypeConstraint::Role',
);

__PACKAGE__->meta->make_immutable;
