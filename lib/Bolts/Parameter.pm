package Bolts::Parameter;
use Moose;

use Carp ();

has key => (
    is          => 'ro',
    isa         => 'Str|Int',
);

has inject_via => (
    is          => 'ro',
    does        => 'Bolts::Injector',
    required    => 1,
);

has isa => (
    reader      => 'isa_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

has optional => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has does => (
    reader      => 'does_type',
    isa         => 'Moose::Meta::TypeConstraint::Role',
);

sub get {
    my ($self, $bag, %params) = @_;

    my $key = $self->key;

    Carp::croak(qq[required parameter "$key" is missing])
        unless $self->optional or defined $params{ $self->key };

    my $value = $params{ $self->key };

    my @constraints = grep { defined } ($self->isa_type, $self->does_type);
    for my $constraint (@constraints) {
        my $error = $constraint->validate($value);
        Carp::croak(qq[parameter "$key" fails validation: $error])
            if defined $error;
    }

    return $params{ $self->key };
}

__PACKAGE__->meta->make_immutable;
