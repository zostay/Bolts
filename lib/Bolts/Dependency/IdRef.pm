package Bolts::Dependency::IdRef;
use Moose;

extends 'Bolts::Dependency';

has idref => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    predicate   => 'has_idref',
);

sub get_value {
    my ($self, $bag) = @_;
    return $bag->acquire($self->idref);
};

__PACKAGE__->meta->make_immutable;