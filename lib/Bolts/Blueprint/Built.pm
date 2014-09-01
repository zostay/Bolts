package Bolts::Blueprint::Built;
use Moose;

with 'Bolts::Blueprint';

use Carp ();

has builder => (
    isa         => 'CodeRef',
    reader      => 'the_builder',
    traits      => [ 'Code' ],
    handles     => {
        'call_builder' => 'execute_method',
    },
);

sub builder {
    my ($self, $bag, $name, @params) = @_;
    $self->call_builder($bag, @params);
}

__PACKAGE__->meta->make_immutable;
