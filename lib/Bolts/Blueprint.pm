package Bolts::Blueprint;
use Moose::Role;

sub get {
    my ($self, $bag, $name, @params) = @_;

    # use Data::Dumper;
    # Carp::cluck( "BLUEPRINT GET[$name]: ", Dumper(\@params));

    $self->builder($bag, $name, @params);
}

requires 'builder';

sub init_meta { }

sub implied_scope { }

1;
