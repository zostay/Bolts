package Injector::Scope::Prototype;
use Moose;

with 'Injector::Scope';

sub init_meta {}
sub get {}
sub put {}

__PACKAGE__->meta->make_immutable;
