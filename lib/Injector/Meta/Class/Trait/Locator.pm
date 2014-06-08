package Injector::Meta::Class::Trait::Locator;
use Moose::Role;

use Injector::Meta::Locator;

has locator => (
    is          => 'ro',
    does        => 'Injector::Role::Locator',
    lazy_build  => 1,
    builder     => 'build_locator',
    handles     => 'Injector::Role::Locator',
);

sub build_locator {
    Injector::Meta::Locator->new;
}

1;
