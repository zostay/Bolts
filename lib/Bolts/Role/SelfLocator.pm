package Bolts::Role::SelfLocator;
use Moose::Role;

with 'Bolts::Role::Locator';

sub root { $_[0] }

1;
