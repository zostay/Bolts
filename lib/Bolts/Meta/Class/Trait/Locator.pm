package Bolts::Meta::Class::Trait::Locator;
use Moose::Role;

use Bolts::Meta::Locator;

has locator => (
    is          => 'rw',
    does        => 'Bolts::Role::Locator',
    lazy_build  => 1,
    builder     => 'build_locator',
    handles     => 'Bolts::Role::Locator',
);

sub build_locator {
    $Bolts::GLOBAL_FALLBACK_META_LOCATOR->new;
}

1;
