package Bolts::Artifact;

# ABSTRACT: Tools for resolving an artifact value

use Moose;

with 'Bolts::Role::Artifact';

use Bolts::Util qw( locator_for meta_locator_for );
use Carp ();
use List::MoreUtils qw( all );
use Moose::Util::TypeConstraints;
use Safe::Isa;
use Scalar::Util qw( weaken );

=head1 SYNOPSIS

    use Bolts;
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        name         => 'key',
        blueprint    => $meta->acquire('blueprint', 'factory', {
            class => 'MyApp::Thing',
        }),
        scope        => $meta->acquire('scope', 'singleton'),
        infer        => 'dependencies',
        dependencies => {
            foo => parameter {
                isa => 'Str',
            },
            bar => value 42,
        },
    );

=head1 DESCRIPTION

This is the primary implementation of L<Bolts::Role::Artifact> with all the features described in L<Bolts>, including blueprint, scope, inferrence, injection, etc.

=head1 ROLES

=over

=item *

L<Bolts::Role::Artifact>

=back

=head1 ATTRIBUTES

=head2 name

B<Required.> This sets the name of the artifact that is being created. This is passed through as part of scope resolution (L<Bolts::Scope>) and blueprint construction (L<Bolts::Blueprint>).

=cut

subtype 'Bolts::Injector::List',
     as 'ArrayRef',
  where { all { $_->$_does('Bolts::Injector') } @$_ };

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 blueprint

B<Required.> This sets the L<Bolts::Blueprint> used to construct the artifact.

=cut

has blueprint => (
    is          => 'ro',
    does        => 'Bolts::Blueprint',
    required    => 1,
);

=head2 scope

B<Required.> This sets the L<Bolts::Scope> used to manage the object's lifecycle.

=cut

has scope => (
    is          => 'ro',
    does        => 'Bolts::Scope',
    required    => 1,
);

=head2 infer

This is a setting that tells the artifact what kind of inferrence to perform when inferring injectors from the blueprint. This may e set to one of the following:

=over

=item none

B<Default.> When this is set, no inferrence is performed. The injectors will be defined according to L</dependencies> only.

=item parameters

This option tells the artifact to infer the injection using parameters. When the object is acquired and resolved, the caller will need to pass through any parameters needed for building the object.

=item dependencies

This option tells the artifact to infer the injection using acquired artifacts. The acquisition will happen from the bag containing the artifact with paths matching the name of the parameter.

B<Caution:> The way this work is likely to be customizeable in the future and the default behavior may differ.

=back

=cut

has infer => (
    is          => 'ro',
    isa         => enum([qw( none parameters dependencies )]),
    required    => 1,
    default     => 'none',
);

=head2 inference_done

This is an internal setting, which has a reader method named C<is_inference_done> and a writer named C<inference_is_done>. Do not use the writer directly unless you know what you are doing. You cannot set this attribute during construction.

Normally, this is a true value after the automatic inference of injectors has been completed and false before.

=cut 

has inference_done => (
    reader      => 'is_inference_done',
    writer      => 'inference_is_done',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
    init_arg    => undef,
);

=head2 injectors

This is an array of L<Bolts::Injector>s, which are used to inject values into or after the construction process. Anything set here will take precedent over inferrence.

=cut

has injectors => (
    is          => 'ro',
    isa         => 'Bolts::Injector::List',
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        all_injectors => 'elements',
        add_injector  => 'push',
    },
);

=head2 does

This is used to control the role the artifact constructed must impement. Usually, this is not set directly, but set by the bag instead as an additional control on bag contents.

=cut

has does => (
    accessor    => 'does_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

=head2 isa

This is used to control the type of the constructed artifact. Usually, this is not set directly, but set by the bag instead as an additional control on bag contents.

=cut

has isa => (
    accessor    => 'isa_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

no Moose::Util::TypeConstraints;

=head1 METHODS

=head2 infer_injectors

This performs the inference of L</injectors> based upon the L</infer> setting. This is called automatically when the artifact is resolved.

=cut

sub infer_injectors {
    my ($self, $bag) = @_;

    # use Data::Dumper;
    # warn Dumper($self);
    # $self->inference_is_done(1);

    my $loc      = locator_for($bag);
    my $meta_loc = meta_locator_for($bag);

    # Use inferences to collect the list of injectors
    if ($self->infer ne 'none') {
        my $inference_type = $self->infer;

        my $inferences = $meta_loc->acquire_all('inference');
        my %injectors = map { $_->key => $_ } $self->all_injectors;

        my @inferred_parameters;
        for my $inference (@$inferences) {
            push @inferred_parameters, 
                $inference->infer($self->blueprint);
        }

        # use Data::Dumper;
        # warn 'INFERRED: ', Dumper(\@inferred_parameters);

        PARAMETER: for my $inferred (@inferred_parameters) {
            my $key = $inferred->{key};

            next PARAMETER if defined $injectors{ $key };

            my %params = %$inferred;
            my $required = delete $params{required};
            my $via      = delete $params{inject_via};

            my $blueprint;
            if ($inference_type eq 'parameters') {
                $blueprint = $meta_loc->acquire('blueprint', 'given', { 
                    required => $required,
                });
            }
            else {
                $blueprint = $meta_loc->acquire('blueprint', 'acquired', {
                    locator => $loc,
                    path    => [ $key ],
                });
            }

            $params{blueprint} = $blueprint;

            my $injector = $meta_loc->acquire('injector', $via, \%params);
            unless (defined $injector) {
                Carp::carp(qq[Unable to acquire an injector for "$via".]);
                next PARAMETER;
            }
                
            $self->add_injector($injector);
        }
    }
}

=head2 such_that

This is a helper for setting L</does> and L</isa>. The bag that contains the artifact normally calls this to enforce type constriants on the artifact.

=cut

sub such_that {
    my ($self, $such_that) = @_;

    # TODO Should probably do something special if on of the must_* are already
    # set. Maybe make sure the new things are compatible with the old? Maybe
    # setup a type union? Maybe croak? Maybe just carp? I don't know.

    $self->does_type($such_that->{does}) if defined $such_that->{does};
    $self->isa_type($such_that->{isa})   if defined $such_that->{isa};
}

# sub init_meta {
#     my ($self, $meta, $name) = @_;
# 
#     $self->blueprint->init_meta($meta, $name);
#     $self->scope->init_meta($meta, $name);
# 
#     # Add the actual artifact factory method
#     $meta->add_method($name => sub { $self });
# 
#     # # Add the actual artifact factory method
#     # $meta->add_method($name => sub {
#     #     my ($bag, %params) = @_;
#     #     return $self->get($bag, %params);
#     # });
# }

=head2 get

This is called during the resolution phase of L<Bolts::Role::Locator> to either retrieve the object from the L</scope> or construct a new object according to the L</blueprint>.

=cut

sub get {
    my ($self, $bag, %input_params) = @_;

    $self->infer_injectors($bag) unless $self->is_inference_done;

    my $name      = $self->name;
    my $blueprint = $self->blueprint;
    my $scope     = $self->scope;

    my $artifact;

    # Load the artifact from the scope unless the blueprint implies scope
    $artifact = $scope->get($bag, $name)
        unless $blueprint->implied_scope;

    # The scope does not have it, so load it again from blueprints
    if (not defined $artifact) {

        my @bp_params;
        for my $injector ($self->all_injectors) {
            $injector->pre_inject($bag, \%input_params, \@bp_params);
        }

        $artifact = $blueprint->get($bag, $name, @bp_params);

        for my $injector ($self->all_injectors) {
            $injector->post_inject($bag, \%input_params, $artifact);
        }

        # Carp::croak("unable to build artifact $name from blueprint")
        #     unless defined $artifact;

        # Add the item into the scope for possible reuse from cache
        $scope->put($bag, $name, $artifact)
            unless $blueprint->implied_scope;
    }

    # TODO This would be a much more helpful check to apply ahead of time in
    # cases where we can. Possibly some sort of such_that check on the
    # blueprints to be handled when such checks can be sensibly handled
    # ahead of time.

    my $isa = $self->isa_type;
    $isa->assert_valid($artifact) if defined $isa;

    my $does = $self->does_type;
    $does->assert_valid($artifact) if defined $does;

    return $artifact;
}

# sub inline_get {
#     my $blueprint_inline = $self->blueprint->inline_get;
#     my $scope_inline     = $self->scope->inline_scope;
# 
#     return q[
#         my ($self, $bag, %params) = @_;
#         my $artifact;
# 
#         ].$scope_inline.q[
# 
#         if (not defined $artifact) {
#             ].$blueprint_inline.q[
#         }
# 
#         return $artifact;
#     ];
# }

__PACKAGE__->meta->make_immutable;
