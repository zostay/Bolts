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
    my ($self, $loc, $in_params, $object) = @_;

    my $value = $self->get($loc, $in_params);
    if ($self->has_position) {
        $object->[ $self->position ] = $value;
    else {
        push @{ $object }, $value;
    }
}

__PACKAGE__->meta->make_immutable;
