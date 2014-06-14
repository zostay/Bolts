package Bolts::Blueprint;
use Moose::Role;

# has name => (
#     is          => 'ro',
#     isa         => 'Str',
#     required    => 1,
# );

has factory => (
    is          => 'ro',
    isa         => 'CodeRef',
    lazy_build  => 1,
    builder     => 'builder',
    traits      => [ 'Code' ],
    handles     => {
        'get' => 'execute_method',
    },
);

requires 'init_meta';
requires 'builder';
# requires 'inline_get';

sub implied_scope { }

1;
