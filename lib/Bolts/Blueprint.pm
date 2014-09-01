package Bolts::Blueprint;
use Moose::Role;

sub get {
    my ($self, $bag, $name, @params) = @_;

    $self->builder($bag, $name, @params);
}

requires 'builder';

sub init_meta { }

sub implied_scope { }

1;
