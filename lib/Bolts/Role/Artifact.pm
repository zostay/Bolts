package Bolts::Role::Artifact;

# ABSTRACT: The role implemented by resolved artifacts

use Moose::Role;

=head1 DESCRIPTION

An artifact can be any kind of object. However, during acquistion, the resolution phase is only performed on objects implementing this role. Resolution allows the artifact to make decisions about how to construct, inject dependencies, and cache the object.

See L<Bolts::Artifact> for the reference implementation of this method. L<Bolts::Artifact::Thunk> provides a second, simpler, and less featureful implementation.

=head1 REQUIRED METHODS

=head2 get

    my $resolved_artifact = $artifact->get($bag, %options);

This method is called during resolution to all the artifact to decide how to resolve the real artifact.

=cut

requires 'get';

=head2 such_that

    $artifact->such_that(
        isa  => $type,
        does => $type,
    );

This applies type constraints to the resolved object. These are invariants that should be applied as soon as the artifact is able to do so.

=cut

requires 'such_that';

1;
