package Bolts::Blueprint::BuiltInjector;
use Moose;

with 'Bolts::Blueprint::Role::Injector';

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
    my ($self, $bag, $name, %params) = @_;
    $self->call_builder($bag, %params);
}

__PACKAGE__->meta->make_immutable;