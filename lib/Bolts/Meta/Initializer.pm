package Bolts::Meta::Initializer;

# ABSTRACT: Store a path and parameters for acquisition

use Moose;

=head1 DESCRIPTION

Describes an initializer, which is just a path and set of parameters used to make a call to L<Bolts::Role::Locator/acquire> within a L<Bolts::Role::Initializer> for any attributed tagged with the C<Bolts::Initializer> trait.

=head1 ATTRIBUTES

=head2 path

This is the path that is passed into the constructor.

=cut

has path => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    traits      => [ 'Array' ],
    handles     => { list_path => 'elements' },
);

=head2 parameters

This is a reference to the hash of parameters passsed into the constructor (or an empty hash if none was passed).

=cut

has parameters => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

=head1 METHODS

=head2 new

    my $init = Bolts::Meta::Initailizer->new(@path, \%parameters);

The C<BUILDARGS> for this object has been modified so that the constructor takes arguments in the same form as L<Bolts::Role::Locator/acquire>.

=cut

sub BUILDARGS {
    my ($self, @path) = @_;

    my $parameters = {};
    if (@path > 1 and ref $path[-1]) {
        $parameters = pop @path;
    }

    return {
        path       => \@path,
        parameters => $parameters,
    };
}

=head2 get

    my (@path, \%parameters) = $init->get;

Returns the contents of this object in a form that can be passed directly on to L<Bolts::Role::Locator/acquire>.

=cut

sub get {
    my $self = shift;
    return ($self->list_path, $self->parameters);
}

__PACKAGE__->meta->make_immutable;
