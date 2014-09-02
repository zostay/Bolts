package Bolts::Injector;
use Moose::Role;

has key => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has blueprint => (
    is          => 'ro',
    does        => 'Bolts::Blueprint::Role::Injector',
    required    => 1,
);

has does => (
    accessor    => 'does_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

has isa => (
    accessor    => 'isa_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

requires 'pre_inject';
requires 'post_inject';

sub get {
    my ($self, $loc, $params) = @_;

    my $blueprint = $self->blueprint;
    my $key       = $self->key;

    my $value = $self->blueprint->get($loc, $key, %$params);

    my $isa = $self->isa_type;
    $isa->assert_valid($value) if defined $isa;

    my $does = $self->does_type;
    $does->assert_valid($value) if defined $does;

    return $value;
}

1;
