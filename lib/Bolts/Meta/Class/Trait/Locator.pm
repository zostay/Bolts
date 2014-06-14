package Bolts::Meta::Class::Trait::Locator;
use Moose::Role;

use Bolts::Meta::Locator;

has locator => (
    is          => 'ro',
    does        => 'Bolts::Role::Locator',
    lazy_build  => 1,
    builder     => 'build_locator',
    handles     => 'Bolts::Role::Locator',
);

sub build_locator {
    Bolts::Meta::Locator->new;
}

1;
