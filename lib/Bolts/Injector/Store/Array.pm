package Bolts::Injector::Store::Array;

# ABSTRACT: Inject dependencies into array artifacts

use Moose;

with 'Bolts::Injector';

=head1 SYNOPSIS

    artifact thing1 => (
        builder => sub { [] },
        indexes => [
            0 => value 'first',
            2 => value 'third',
            9 => value 'tenth',
        ],
    );

    my $counter = 0;
    artifact thing2 => (
        builder => sub { [ 'foo', 'bar' ] },
        push => [ value 'baz', builder { ++$counter } ],
    );

=head1 DESCRIPTION

Inject values into an array during resolution by index or just push.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 ATTRIBUTES

=head2 position

If this attribute is set to a number, then the injection will happen at that index. If it is not set, this injector performs a push instead.

=cut

has position => (
    is          => 'ro',
    isa         => 'Int',
    predicate   => 'has_position',
);

=head1 METHODS

=head2 post_inject_value

Performs the injection of values into an array by index or push.

=cut

sub post_inject_value {
    my ($self, $loc, $value, $array) = @_;
    if ($self->has_position) {
        $array->[ $self->position ] = $value;
    }
    else {
        push @{ $array }, $value;
    }
}

__PACKAGE__->meta->make_immutable;
