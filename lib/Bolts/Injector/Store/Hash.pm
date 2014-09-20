package Bolts::Injector::Store::Hash;
use Moose;

with 'Bolts::Injector';

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }

sub post_inject {
    my ($self, $loc, $value, $hash) = @_;
    $hash->{ $self->name } = $value;
}


1;
