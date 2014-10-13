package Bolts::Injector;

# ABSTRACT: inject options and parameters into artifacts

use Moose::Role;

our @CARP_NOT = qw(
    Bolts::Injector::Parameter::ByName
    Bolts::Artifact
);

=head1 SYNOPSIS

    package MyApp::CustomInjector;
    use Moose;

    with 'Bolts::Injector';

    sub pre_inject_value {
        my ($self, $loc, $value, $param) = @_;
        $param->set($self->key, $value);
    }

    sub post_inject_value {
        my ($self, $loc, $value, $artifact) = @_;
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

=head2 init_locator

If provided with a reference to the meta-locator for the bag to which the injector is going to be attached, the L<blueprint> may be given as initializers.

=cut

has init_locator => (
    is          => 'ro',
    isa         => 'Bolts::Role::Locator',
    weak_ref    => 1,
);

#with 'Bolts::Role::Initializer';

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

Instead of passing the blueprint object in directly, you can provide an initializer in an array reference, similar to what you would pass to C<acquire> to get the blueprint from the meta-locator, e.g.:

    blueprint => bolts_init('blueprint', 'acquire', {
        path => [ 'foo' ],
    }),

If so, you must provide an L</init_locator>.

=cut

has blueprint => (
    is          => 'ro',
    does        => 'Bolts::Blueprint::Role::Injector',
    required    => 1,
    traits      => [ 'Bolts::Initializer' ],
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

=head1 OVERRIDDEN METHODS

=head2 pre_inject_value

    $injector->pre_inject_value($loc, $value, $param);

This method is called first, before the artifact has been constructed by the parent blueprint. 

The C<$loc> provides the context for the injector. It is the bag that contains the artifact being constructed. The C<$value> is the value to be injected. The C<$param> is the value to inject into, which will be passed through to the blueprint for use during construction.

If your injector does not provide any pre-injection, do not implement this method.

=head2 post_inject_value

    $injector->post_inject_value($loc, $value, $artifact);

This method is called after the blueprint has already constructed the object for additional modification. 

The C<$loc> provides the context for the injector. It is the bag that contains the artifact being constructed. The C<$value> is the value to be injected. The C<$artifact> is the constructed artifact to be injected into.

If your injector does not provide any post-injection, do not implement this method.

=cut

# not actually required, we use duck-typing to determine what kind of injection
# to perform.
#requires 'pre_inject_value';
#requires 'post_inject_value';

=head1 METHODS

=head2 pre_inject

   $injector->pre_inject($loc, $options, $param);

Performs the complete process of pre-injection, calling L</pre_inject_value>, if needed.

=cut

sub pre_inject {
    my ($self, $loc, $options, $param) = @_;

    return unless $self->can('pre_inject_value');
    return unless $self->exists($loc, $options);

    my $value = $self->get($loc, $options);
    $self->pre_inject_value($loc, $value, $param);
}

=head2 post_inject

    $injector->post_inject($loc, $options, $artifact);

Performs the complete process of post-injection, calling L</post_inject_value>, if needed.

=cut

sub post_inject {
    my ($self, $loc, $options, $artifact) = @_;

    return unless $self->can('post_inject_value');
    return unless $self->exists($loc, $options);

    my $value = $self->get($loc, $options);
    $self->post_inject_value($loc, $value, $artifact);
}

=head2 exists

    my $exists = $injector->exists($loc, $options);

Returns true if the blueprint reports the value for injection exists. Injection is skipped if it does not exists.

=cut

sub exists {
    my ($self, $loc, $options) = @_;

    my $blueprint = $self->blueprint;
    my $key       = $self->key;

    return $blueprint->exists($loc, $key, %$options);
}

=head2 get

    my $value = $injector->get($loc, $options);

These are used by L</pre_inject> and L</post_inject> to acquire the value to be injected.

=cut

sub get {
    my ($self, $loc, $options) = @_;

    my $blueprint = $self->blueprint;
    my $key       = $self->key;

    my $value = $blueprint->get($loc, $key, %$options);

    my $isa  = $self->isa_type;
    my $does = $self->does_type;

    my $msg;
       $msg   = $isa->validate($value)  if defined $isa;
       $msg //= $does->validate($value) if defined $does;

    Carp::croak(qq[Value for injection at key "$key" has the wrong type: $msg]) if $msg;

    return $value;
}

1;
