package Bolts::Scope::Prototype;
use Moose;

with 'Bolts::Scope';

sub get {}
sub put {}

__PACKAGE__->meta->make_immutable;
