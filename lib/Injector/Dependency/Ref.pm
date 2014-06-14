package Injector::Dependency::Ref;
use Moose;

extends 'Injector::Dependency';

has ref => (
    is          => 'ro',
    isa         => 'Injector::Artifact',
    required    => 1,
    weak_ref    => 1,
);

sub get_value {
    my ($self, $bag) = @_;
    return $self->ref->get($bag);
};

__PACKAGE__->meta->make_immutable;
