package Bolts::Blueprint::Acquired;
use Moose;

with 'Bolts::Blueprint';

use Bolts::Util qw( locator_for );

has locator => (
    is          => 'ro',
    does        => 'Bolts::Role::Locator',
    predicate   => 'has_locator',
);

has path => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    predicate   => 'has_path',
    traits      => [ 'Array' ],
    handles     => {
        full_path => 'elements',
    },
);

sub builder {
    sub {
        my ($self, $bag, $name, @params) = @_;

        my @path = $self->has_path ? $self->full_path : $name;
        
        if ($self->has_locator) {
            return $self->locator->acquire(@path);
        }
        else {
            return locator_for($bag)->acquire(@path);
        }
    };
}

__PACKAGE__->meta->make_immutable;
