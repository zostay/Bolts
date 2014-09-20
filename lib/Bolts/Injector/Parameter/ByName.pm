package Bolts::Injector::Parameter::ByName;

# ABSTRACT: Inject parameters by name during construction

use Moose;

with 'Bolts::Injector';

=head1 SYNOPSIS

    use Bolts;

    artifact thing => (
        class => 'MyApp::Thing',
        parameters => {
            foo => dep('other_thing'),
        },
    );

=head1 DESCRIPTION

Inject parameters by name during construction.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 ATTRIBUTES

=head2 name

This is the name of the parameter to set in the call to the constructor.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }

=head1 METHODS

=head2 pre_inject_value

Performs the pre-injection by named parameter.

=cut

sub pre_inject_value {
    my ($self, $loc, $value, $params) = @_;
    push @{ $params }, $self->name, $value;
}

__PACKAGE__->meta->make_immutable;
