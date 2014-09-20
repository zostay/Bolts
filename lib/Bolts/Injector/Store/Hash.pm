package Bolts::Injector::Store::Hash;

# ABSTRACT: Inject values into a hash

use Moose;

with 'Bolts::Injector';

=head1 SYNOPSIS

    use Bolts;

    my $counter = 0;
    artifact thing => (
        builder => sub { +{} },
        keys => {
            counter => builder { ++$counter },
        },
    );

=head1 DESCRIPTION

This performs injection of a value into a hash.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 ATTRIBUTES

=head2 name

This is the name of the hash key to perform injection upon.

Defaults to the L<Bolts::Injector/key>.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }

=head1 METHODS

=head2 post_inject_value

Performs the injection into a hash by key.

=cut

sub post_inject_value {
    my ($self, $loc, $value, $hash) = @_;
    $hash->{ $self->name } = $value;
}


1;
