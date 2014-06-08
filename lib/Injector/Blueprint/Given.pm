package Injector::Blueprint::Given;
use Moose;

with 'Injector::Blueprint';

use Carp ();

has required => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

sub init_meta {
    my ($self, $meta, $name) = @_;

    $meta->add_attribute($name =>
        accessor => "__bp_given_$name",
        init_arg => $name,
    );
}

sub builder { 
    sub {
        my ($self, $bag, $name, @params) = @_;
        my $get_given_value = "__bp_given_$name";
        return $bag->$get_given_value;
    };
}

# sub inline_get {
#     return q[$artifact = $self->_].$name.q[;];
# }

sub implied_scope { 'singleton' }

__PACKAGE__->meta->make_immutable;
