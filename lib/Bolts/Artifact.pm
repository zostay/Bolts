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

subtype 'Bolts::Injector::List',
     as 'ArrayRef',
  where { all { $_->$_does('Bolts::Injector') } @$_ };

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has blueprint => (
    is          => 'ro',
    does        => 'Bolts::Blueprint',
    required    => 1,
);

has scope => (
    is          => 'ro',
    does        => 'Bolts::Scope',
    required    => 1,
);

has infer => (
    is          => 'ro',
    isa         => enum([qw( none parameters dependencies )]),
    required    => 1,
    default     => 'none',
);

has inference_done => (
    reader      => 'is_inference_done',
    writer      => 'inference_is_done',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
    init_arg    => undef,
);

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

has does => (
    accessor    => 'does_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

has isa => (
    accessor    => 'isa_type',
    isa         => 'Moose::Meta::TypeConstraint',
);

no Moose::Util::TypeConstraints;

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

        PARAMETER: for my $inferred (@inferred_parameters) {
            my $key = $inferred->{key};

            next PARAMETER if defined $injectors{ $key };

            my %params = %$inferred;
            my $required = delete $params{required};
            my $via      = delete $params{inject_via};
            my $isa      = delete $params{isa};
            my $does     = delete $params{does};
            my %artifact_params = (
                name     => join(':', $self->name, $key),
                scope    => $meta_loc->acquire('scope', 'prototype'),
            );
            $artifact_params{isa}  = $isa  if defined $isa;
            $artifact_params{does} = $does if defined $does;

            if ($inference_type eq 'parameters') {
                $artifact_params{blueprint} = $meta_loc->acquire('blueprint', 'given', { 
                    required => $required,
                });
            }
            else {
                $artifact_params{blueprint} = $meta_loc->acquire('blueprint', 'acquired', {
                    locator => $loc,
                    path    => [ $key ],
                });
            }

            $params{artifact} = Bolts::Artifact->new(%artifact_params);
            use Data::Dumper;
            warn Dumper($params{artifact});

            my $injector = $meta_loc->acquire('injector', $via, \%params);
            unless (defined $injector) {
                Carp::carp(qq[Unable to acquire an injector for "$via".]);
                next PARAMETER;
            }
                
            $self->add_injector($injector);
        }
    }
}

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

        my %bp_params;
        for my $injector ($self->all_injectors) {
            $injector->pre_inject($bag, %input_params, %bp_params);
        }

        use Data::Dumper;
        warn "$name ", Dumper(\%bp_params);
        $artifact = $blueprint->get($bag, $name, %bp_params);

        for my $injector ($self->all_injectors) {
            $injector->post_inject($bag, %input_params, $artifact);
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
