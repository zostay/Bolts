package Bolts::Role::SelfLocator;

# ABSTRACT: Makes a Moose object into a locator

use Moose::Role;

with 'Bolts::Role::Locator';

=head1 DESCRIPTION

Any Moose object can turned into a L<Bolts::Role::Locator> easily just by implementing this role.

=head1 METHODS

=head2 root

Returns the invocant.

=cut

sub root { $_[0] }

1;
