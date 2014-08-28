package Bolts::Locator;
use Moose;

has root => (
    is          => 'ro',
    isa         => 'HashRef|ArrayRef|Object',
    required    => 1,
);

with 'Bolts::Role::Locator';

override BUILDARGS => sub {
    my $class = shift;
    
    if (@_ == 1) {
        return { root => $_[0] };
    }
    else {
        return super();
    }
};

__PACKAGE__->meta->make_immutable;
