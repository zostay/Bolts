package Bolts::Scope::Prototype;
use Moose;

with 'Bolts::Scope';

sub init_meta {}
sub get {}
sub put {}

__PACKAGE__->meta->make_immutable;
