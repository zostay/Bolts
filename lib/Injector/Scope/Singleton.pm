package Injector::Scope::Singleton;
use Moose;

with 'Injector::Scope';

sub init_meta {
    my ($self, $meta, $name) = @_;

    $meta->add_attribute($name =>
        accessor => "__sc_singleton_$name",
        init_arg => undef,
    );
}

sub get {
    my ($self, $bag, $name) = @_;

    my $get_instance = "__sc_singleton_$name";
    return $bag->get_instance;
}

sub put {
    my ($self, $bag, $name) = @_;

    my $put_instance = "__sc_singleton_$name";
    return $bag->$put_instance;
}

__PACKAGE__->meta->make_immutable;
