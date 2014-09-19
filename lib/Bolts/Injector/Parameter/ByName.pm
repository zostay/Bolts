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

=head2 skip_undef

If set, the parameter won't be set if the value is undef. Defaults to true.

=cut

has skip_undef => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 1,
);

sub _build_name { $_[0]->key }

=head1 METHODS

=head2 pre_inject

Performs the pre-injection by named parameter.

=cut

sub pre_inject {
    my ($self, $loc, $in_params, $out_params) = @_;

    my $value = $self->get($loc, $in_params);

    return if $self->skip_undef and not defined $value;

    push @{ $out_params }, $self->name, $value;
}

=head2 post_inject

Noop.

=cut

sub post_inject { }

__PACKAGE__->meta->make_immutable;
