package Injector::Role::SelfLocator;
use Moose::Role;

with 'Injector::Role::Locator';

sub root { $_[0] }

1;
