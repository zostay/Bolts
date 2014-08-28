package Bolts::Artifact::Thunk;
use Moose;

has thunk => (
    is          => 'ro',
    isa         => 'CodeRef',
    traits      => [ 'Code' ],
    handles     => {
        'get' => 'execute_method',
    },
);

# TODO Fix this. Make it do something rather than ignore the check.
sub such_that { }

with 'Bolts::Role::Artifact';

__PACKAGE__->meta->make_immutable;
