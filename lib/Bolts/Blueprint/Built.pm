package Bolts::Blueprint::Built;
use Moose;

with 'Bolts::Blueprint';

use Carp ();

has builder => (
    isa         => 'CodeRef',
    reader      => 'the_builder',
);

sub builder {
    my ($self) = @_;

    my $builder = $self->the_builder;
    return sub {
        my ($self, $bag, $name, @params) = @_;
        $builder->($bag, @params);
    };
}

__PACKAGE__->meta->make_immutable;
