package Bolts::Blueprint::Factory;

# ABSTRACT: Build an artifact by calling a class method on a class

use Moose;

with 'Bolts::Blueprint';

use Class::Load ();

=head1 SYNOPSIS

    use Bolts;

    # Using the usual sugar...
    artifact thing1 => ( # construct via MyApp::Thing->new(...)
        class => 'MyApp::Thing',
    );

    artifact thing2 => ( # construct via MyApp::Thing->load_standard_thing(...)
        class  => 'MyApp::Thing',
        method => 'load_standard_thing',
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        name      => 'thing',
        blueprint => $meta->locator->acquire('blueprint', 'factory', {
            class  => 'MyApp::Thing',
            method => 'new',
        }),
        scope     => $meta->locator->acquire('scope', '_'),
    );

=head1 DESCRIPTION

Most applications of Bolts will make a great deal of use of this. It allows you to use a class name and a class method name to construct an object. This is the most straightforward way of constructing things and the way most easily inferred from.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint>

=back

=head1 ATTRIBUTES
        
=head2 class

B<Required.> This is the name of the class to call the L</method> upon. This class will also be automatically loaded if it hasn't been loaded into the current Perl interpreter yet.

=cut

has class => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 method

This is the method to call on the L</class>. Defaults to "new".

=cut

has method => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'new',
);

=head1 METHODS

=head2 builder

Loads the L</class> if it has not yet been loaded. Then calls the L</method> on it, passing through to the constructor whatever parameters were configured during pre-injection.

=cut

sub builder {
    my ($self, $bag, $name, @params) = @_;

    my $class = $self->class;
    my $method = $self->method;

    Class::Load::load_class($class);

    return $class->$method(@params);
}

__PACKAGE__->meta->make_immutable;
