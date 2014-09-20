package Bolts::Injector::Setter;

# ABSTRACT: Inject by calling a setter method with a value

use Moose;

with 'Bolts::Injector';

use Carp ();
use Scalar::Util;

=head1 SYNOPSIS

    use Bolts;

    artifact thing => (
        class => 'MyApp::Thing',
        setters => {
            set_foo => dep('other_thing'),
        },
    );

=head1 DESCRIPTION

This controls injection by setter, which causes a method to be called on the constructed artifact with the value to be injected.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 ATTRIBUTES

=head2 name

This is the name of the method to call during injection. It defaults to L<Bolts::Injector/key>.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }

=head1 METHODS

=head2 post_inject_value

Performs the injection into the setter.

=cut

sub post_inject_value {
    my ($self, $loc, $value, $object) = @_;

    Carp::croak(qq[Can't use setter injection on "$object".])
        unless defined $object and Scalar::Util::blessed($object);

    my $name = $self->name;
    $object->$name($value);
}

__PACKAGE__->meta->make_immutable;

