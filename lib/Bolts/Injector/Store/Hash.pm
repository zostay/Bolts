package Bolts::Injector::Store::Hash;
use Moose;

with 'Bolts::Injector';

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }

sub pre_inject { }

sub post_inject {
    my ($self, $loc, %in_params, $object) = @_;

    my $value = $self->get($loc, %in_params);
    $object->{ $self->name } = $value;
}


1;
