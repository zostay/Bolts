package Bolts::Injector;

# ABSTRACT: inject options and parameters into artifacts

use Moose::Role;

=head1 SYNOPSIS

    package MyApp::CustomInjector;
    use Moose;

    with 'Bolts::Injector';

    sub pre_inject {
        my ($self, $loc, $in_params, $out_params) = @_;

        my $value = $self->get($loc, $in_params);

        $out_params->set($self->key, $value);
    }

    sub post_inject {
        my ($self, $loc, $in_params, $artifact) = @_;

        my $value = $self->get($loc, $in_params);

        $artifact->set($self->key, $value);
    }

=head1 DESCRIPTION

Defines the interface that injectors use to inject dependencies into an artifact
being resolved. While the locator finds the object for the caller and the
blueprint determines how to construct the artifact, the injector helps the
blueprint by passing through any parameters or settings needed to complete the
construction.

This is done in two phases, with most injectors only implementing one of them:

=over

=item 1.

B<Pre-injection.> Allows the injector to configure the parameters sent through
to blueprint's builder method, such as might be needed when constructing a new
object.

=item 2.

B<Post-injection.> This phase gives the injector access to the newly constructed
but partially incomplete object to perform additional actions on the object,
such as calling methods to set additional attributes or activate state on the
object.

=back

This role provides the tools necessary to allow the injection implementations to
focus only on the injection process without worrying about the value being
injected.

=head1 ATTRIBUTES

=head2 key

This is the key used to desribe what the injector is injecting. This might be a parameter name, an array index, or method name (or any other descriptive string).

=cut

has key => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 blueprint

This is the blueprint that defines how the value being injected will be constructed. So, not only is the injector part of the process of construction, but it has its own blueprint for constructing the value needed to perform the injection.

All the injector needs to worry about is the L</get> method, which handles the process of getting and validating the value for you.

=cut

has blueprint => (
    is          => 'ro',
    does        => 'Bolts::Blueprint::Role::Injector',
    required    => 1,
);

=head2 does

This is a type constraint describing what value is expected for injection. This is checked within L</get>.

=cut

has does => (
    accessor    => 'does_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

=head2 isa

This is a type constraint describing what value is expected for injection. This is checked within L</get>.

=cut

has isa => (
    accessor    => 'isa_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

=head1 REQUIRED METHODS

=head2 pre_inject

    $injector->pre_inject($loc, $in_params, $out_params);

This method is called first, before the artifact has been constructed by the parent blueprint. 

The first two arguments provide the context for the artifact being constructed. The first is the L<Bolts::Role::Locator> rooted at the bag the artifact belongs to and the second is the input options given by the caller during acquisition. You don't need to examine either of these directly. Instead, call L</get>:

    my $value = $injector->get($loc, $in_params);

That C<$value> is the important bit you need. Once you have the C<$value>, inject that value by modifying C<$out_params> with it, which will eventually be passed on the parent blueprint.

If your injector does not provide any pre-injection, implement this with an empty sub-routine:

    sub pre_inject { }

=head2 post_inject

    $injector->post_inject($loc, $in_params, $artifact);

This method is called after the blueprint has already constructed the object for additional modification. 

The first two arguments provide the context for the artifact being constructed. The first is the L<Bolts::Role::Locator> rooted at the bag the artifact belongs to and the second is the input options given by the caller during acquisition. You don't need to examine either of these directly. Instead, call L</get>:

    my $value = $injector->get($loc, $in_params);

That C<$value> is the important bit you need. Once you have the C<$value>, inject that value by modifying C<$artifact> with it.

If your injector does not provide any post-injection, implement this with an empty sub-routine:

    sub post_inject { }

=cut

requires 'pre_inject';
requires 'post_inject';

=head1 METHODS

=head2 get

    my $value = $injector->get($loc, $in_params);

These are used by L</pre_inject> and L</post_inject> to acquire the value to be injected.

=cut

sub get {
    my ($self, $loc, $params) = @_;

    my $blueprint = $self->blueprint;
    my $key       = $self->key;

    my $value = $self->blueprint->get($loc, $key, %$params);

    my $isa = $self->isa_type;
    $isa->assert_valid($value) if defined $isa;

    my $does = $self->does_type;
    $does->assert_valid($value) if defined $does;

    return $value;
}

1;
