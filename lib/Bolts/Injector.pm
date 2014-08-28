package Bolts::Injector;
use Moose::Role;

has key => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has artifact => (
    is          => 'ro',
    does        => 'Bolts::Role::Artifact',
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
    my ($self, $loc, %params) = @_;

    my $artifact = $self->artifact;
    use Data::Dumper;
    warn Dumper($artifact) if $artifact->name eq 'artifact';
    $artifact->such_that({
        does => $self->does_type,
        isa  => $self->isa_type,
    });
    my $value = $self->artifact->get($loc, %params);

    return $value;
}

1;
