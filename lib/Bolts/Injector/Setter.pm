package Bolts::Injector::Setter;
use Moose;

with 'Bolts::Injector';

use Carp ();
use Scalar::Util;

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }

sub pre_inject { }

sub post_inject {
    my ($self, $loc, %in_params, $object) = @_;

    Carp::croak(qq[Can't use setter injection on "$object".])
        unless defined $object and Scalar::Util::blessed($object);

    my $value = $self->get($loc, %in_params);
    my $name = $self->name;
    $object->$name($value);
}

__PACKAGE__->meta->make_immutable;

