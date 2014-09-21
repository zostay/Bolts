package Bolts::Scope::Prototype;

# ABSTRACT: For artifacts that are constructed at every request

use Moose;

with 'Bolts::Scope';

=head1 DESCRIPTION

This is a lifecycle scope for objects that should be constructed from their blueprints on every aquisition.

=head1 ROLES

=over

=item *

L<Bolts::Scope>

=back

=head1 METHODS

=head2 get

No-op. This will always return C<undef>.

=head2 put

No-op. This will never store anything.

=cut

sub get {}
sub put {}

__PACKAGE__->meta->make_immutable;
