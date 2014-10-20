package Bolts::Blueprint::ParentBag;

# ABSTRACT: Retrieve the artifact's parent as the artifact

use Moose;

with 'Bolts::Blueprint::Role::Injector';

=head1 SYNOPSIS

    use Bolts;

    # Using the usual sugar...
    artifact thing => (
        ...
        parameters => {
            parent => self,
        },
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        ...
        injectors => [
            $meta->locator->acquire('injector', 'parameter_name', {
                key       => 'parent',
                blueprint => $meta->locator->acquire('blueprint', 'parent_bag'),
            }),
        ],
    );

=head1 DESCRIPTION

This is a blueprint for grabing the parent itself as the artifact.

B<Warning:> If you cache this object with a scope, like "singleton", your application will leak memory. This may create a very difficult to track loop of references.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint::Role::Injector>

=back

=head1 METHODS

=head2 builder

This grabs the parent bag and returns it.

=cut

sub builder {
    my ($self, $bag, $name, %params) = @_;
    return $bag;
}

=head2 exists

Always returns true.

=cut

sub exists { 1 }

__PACKAGE__->meta->make_immutable;
