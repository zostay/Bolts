package Bolts::Scope::Singleton;

# ABSTRACT: For artifacts that are reused for the lifetime of the bag

use Moose;

use Hash::Util::FieldHash 'fieldhash';

with 'Bolts::Scope';

fieldhash my %singleton;

=head1 DESCRIPTION

This scope does not define a true singleton, but a singleton for the lifetime of the bag it is associated with, which might be the same thing.

=head1 ROLES

=over

=item *

L<Bolts::Scope>

=back

=head1 METHODS

=head2 get

If the named artifact has ever been stored for this bag, it will be returned by this method.

=head2 put

Puts the named artifact into the singleton cache for the bag. Once there, it will stay there for as long as the object exists.

=cut

sub get {
    my ($self, $bag, $name) = @_;

    return unless defined $singleton{$bag};
    return unless defined $singleton{$bag}{$name};
    return $singleton{$bag}{$name};
}

sub put {
    my ($self, $bag, $name, $artifact) = @_;

    $singleton{$bag} = {} unless defined $singleton{$bag};
    $singleton{$bag}{$name} = $artifact;
    return;
}

=head1 CAVEAT

B<Warning:> This currently uses an inside-out hash for caching, which is never destroyed. That's a pretty terrible memory leak that needs to be corrected.

=cut

__PACKAGE__->meta->make_immutable;
