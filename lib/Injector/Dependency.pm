package Injector::Dependency;
use Moose;

extends 'Injector::Parameter';

has idref => (
    is          => 'ro',
    isa         => 'Str',
);

has ref => (
    is          => 'ro',
    isa         => 'Injector::Artifact',
    weak_ref    => 1,
);

__PACKAGE__->meta->make_immutable;
