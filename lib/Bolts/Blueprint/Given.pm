package Bolts::Blueprint::Given;
use Moose;

with 'Bolts::Blueprint';

use Carp ();

has required => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

sub builder { 
    sub {
        my ($self, $bag, $name, %params) = @_;
        return $params{ $name };
    };
}

# sub inline_get {
#     return q[$artifact = $self->_].$name.q[;];
# }

sub implied_scope { 'singleton' }

__PACKAGE__->meta->make_immutable;
