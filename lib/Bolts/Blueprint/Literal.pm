package Bolts::Blueprint::Literal;

# ABSTRACT: A blueprint that points to a literal value

use Moose;

with 'Bolts::Blueprint::Role::Injector';

use Carp ();

=head1 SYNOPSIS

    use Bolts;

    # The usual sugar
    artifact thing1 => 42;
    artifact thing2 => ( value => 42 );
    artifact thing3 => (
        value => [ 'this', 'is', 'an', 'example' ],
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        name      => 'thing',
        blueprint => $meta->locator->acquire('blueprint', 'literal', {
            value => 42,
        },
        scope     => $meta->locator->acquire('scope', '_'),
    );

=head1 DESCRIPTION

Provides a blueprint that points to a single value. This is best used for scalars, strings, and numbers, but could be used for references. 

B<Caveat.> In the case of references, the same reference is returned every time so the contents of that reference might be modified by anyone that acquires it. This may be desirable in your application, but there's the warning in case it is not.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint::Role::Injector>

=back

=head1 ATTRIBUTES

=head2 value

This is the literal value to return when this blueprint is resolved. This can be anything you can assign to a scalar variable, including references to arrays and hash (see the caveat above).

=cut

has value => (
    is          => 'ro',
    required    => 1,
);

=head1 METHODS

=head2 builder

Returns the L</value>.

=cut

sub builder {
    my ($self) = @_;
    $self->value;
}

=head2 exists

Always returns true.

=cut

sub exists { 1 }

=head2 implied_scope

This is set. A literal blueprint value acts like a global singleton.

=cut

sub implied_scope { 'singleton' }

__PACKAGE__->meta->make_immutable;
