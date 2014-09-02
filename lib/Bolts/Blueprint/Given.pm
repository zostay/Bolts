package Bolts::Blueprint::Given;
use Moose;

with 'Bolts::Blueprint::Role::Injector';

use Carp ();

has required => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

sub builder { 
    my ($self, $bag, $name, %params) = @_;

    Carp::croak("Missing required parameter $name")
        if $self->required and not exists $params{ $name };

    return unless exists $params{ $name };

    return $params{ $name };
}

# sub inline_get {
#     return q[$artifact = $self->_].$name.q[;];
# }

sub implied_scope { 'singleton' }

__PACKAGE__->meta->make_immutable;
