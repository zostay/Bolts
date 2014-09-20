package Bolts::Locator;

# ABSTRACT: General purpose locator

use Moose;

=head1 SYNOPSIS

    my $some_bag = MyApp::SomeBag->new;
    my $loc = Bolts::Locator->new($some_bag);

    # OR better...
    use Bolts::Util qw( locator_for );
    my $loc = locator_for($some_bag);

=head1 DESCRIPTION

This can be used to wrap any object, array, or hash reference in a L<Bolts::Role::Locator> interface.

=head1 ROLES

=over

=item *

L<Bolts::Role::Locator>

=back

=head1 ATTRIBUTES

=head2 root

This implements L<Bolts::Role::Locator/root> allowing the locator to be applied to any object, array or hash reference.

=cut

has root => (
    is          => 'ro',
    isa         => 'HashRef|ArrayRef|Object',
    required    => 1,
);

with 'Bolts::Role::Locator';

=head1 METHODS

=head2 new

    my $loc = Bolts::Locator->new($bag);
    my $loc = Bolts::Locator->new( root => $bag );

You may call the constructor with only a single argument. In that case, that argument is treated as L</root>.

=cut

override BUILDARGS => sub {
    my $class = shift;
    
    if (@_ == 1) {
        return { root => $_[0] };
    }
    else {
        return super();
    }
};

__PACKAGE__->meta->make_immutable;
