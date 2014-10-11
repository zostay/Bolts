package Bolts::Role::SelfLocator;

# ABSTRACT: Makes a Moose object into a locator

use Moose::Role;

with 'Bolts::Role::RootLocator';

=head1 DESCRIPTION

Any Moose object can turned into a L<Bolts::Role::Locator> easily just by implementing this role.

=head1 ROLES

=over

=item *

L<Bolts::Role::Locator>

=back

=head1 METHODS

=head2 root

Returns the invocant.

=cut

sub root { $_[0] }

1;
