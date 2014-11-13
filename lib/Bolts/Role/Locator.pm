package Bolts::Role::Locator;

# ABSTRACT: Interface for locating artifacts in a bag

use Moose::Role;

=head1 DESCRIPTION

This is the interface that any locator must implement. A locator's primary job is to provide a way to find artifacts within a bag or selection of bags. This performs the acquisition and resolution process.

The reference implementation of this interface is found in L<Bolts::Role::RootLocator>.

=head1 REQUIRED METHODS

=head2 acquire

    my $artifact = $loc->acquire(@path, \%options);

Given a C<@path> of symbol names to traverse, this goes through each artifact in turn, resolves it, if necessary, and then continues to the next path component.

The final argument, C<\%options>, is optional. It must be a reference to a hash to pass through to the final component to aid with resolution.

When complete, the complete, resolved artifact found is returned.

=cut

requires 'acquire';

=head2 acquire_all

    my @artifacts = @{ $loc->acquire_all(@path, \%options) };

This is similar to L<acquire>, but if the last bag is a reference to an array, then all the artifacts within that bag are acquired, resolved, and returned as a reference to an array.

The final argument is optional. As with L</acquire>, it is must be a hash reference and is passed to each of the artifacts during their resolution.

If the last item found at the path is not an array, it returns an empty list.

=cut

requires 'acquire_all';

=head2 resolve

    my $resolved_artifact = $loc->resolve($bag, $artifact, \%options);

After the artifact has been found, this method resolves the a partial artifact implementing the L<Bolts::Role::Artifact> and turns it into the complete artifact.

This method is called during each step of acquisition to resolve the artifact (which might be a bag) at each step, including the final step. The given C<%options> are required. They are derefenced and passed to the L<Bolts::Role::Artifact/get> method, if the artifact being resolved implements L<Bolts::Role::Artifact>.

=cut

requires 'resolve';

=head2 get

    my $artifact = $log->get($component);

Given a single symbol name as the path component to find during acquisition it returns the partial artifact for it. This artifact is incomplete and still needs to be resolved.

=cut

requires 'get';

1;
