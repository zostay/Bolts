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
        injectors => [
            
        ],
    );

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }

# has skip_undef => (
#     is          => 'ro',
#     isa         => 'Bool',
#     required    => 1,
#     default     => 1,
# );

sub post_inject_value {
    my ($self, $loc, $value, $object) = @_;

    Carp::croak(qq[Can't use setter injection on "$object".])
        unless defined $object and Scalar::Util::blessed($object);

    my $name = $self->name;
    $object->$name($value);
}

__PACKAGE__->meta->make_immutable;

