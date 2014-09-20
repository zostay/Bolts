package Bolts::Injector::Store::Array;
use Moose;

with 'Bolts::Injector';

has position => (
    is          => 'ro',
    isa         => 'Maybe[Int]',
    predicate   => 'has_position',
);

sub pre_inject { }

sub post_inject {
    my ($self, $loc, $value, $array) = @_;
    if ($self->has_position) {
        $array->[ $self->position ] = $value;
    }
    else {
        push @{ $array }, $value;
    }
}

__PACKAGE__->meta->make_immutable;
