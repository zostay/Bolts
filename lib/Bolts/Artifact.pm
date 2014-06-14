package Bolts::Artifact;
use Moose;

with 'Bolts::Role::Artifact';

use Carp ();
use Moose::Util::TypeConstraints;
use Scalar::Util qw( weaken );

subtype 'Bolts::Parameter::List',
     as 'ArrayRef[Bolts::Parameter]';

subtype 'Bolts::Dependency::List',
     as 'ArrayRef[Bolts::Dependency]';

coerce 'Bolts::Parameter::List',
  from 'HashRef[HashRef]',
   via { 
        my $h = $_;
        map { 
            Bolts::Parameter->new(
                name => $_, 
                %{ $h->{$_} },
            ) 
        } keys %$h;
       };

coerce 'Bolts::Parameter::List',
  from 'ArrayRef[HashRef]',
   via {
        my $a = $_;
        map { 
            Bolts::Parameter->new(
                position => $_,
                %{ $a->[$_] },
            )
        } keys @$a;
       };

coerce 'Bolts::Dependency::List',
  from 'HashRef[HashRef]',
   via {
        my $h = $_;
        map { 
            Bolts::Dependency->new(
                name => $_, 
                %{ $h->{$_} },
            ) 
        } keys %$h;
       };

coerce 'Bolts::Dependency::List',
  from 'ArrayRef[HashRef]',
   via {
        my $a = $_;
        map { 
            Bolts::Dependency->new(
                position => $_,
                %{ $a->[$_] },
            )
        } keys @$a;
       };

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

has dependencies => (
    is          => 'ro',
    isa         => 'Bolts::Dependency::List',
    required    => 1,
    coerce      => 1,
    default     => sub { [] },
);

has parameters => (
    is          => 'ro',
    isa         => 'Bolts::Parameter::List',
    required    => 1,
    coerce      => 1,
    default     => sub { [] },
);

has must_do => (
    is          => 'rw',
    isa         => 'Moose::Meta::TypeConstraint',
);

has must_be_a => (
    is          => 'rw',
    isa         => 'Moose::Meta::TypeConstraint',
);

no Moose::Util::TypeConstraints;

sub such_that {
    my ($self, $such_that) = @_;

    # TODO Should probably do something special if on of the must_* are already
    # set. Maybe make sure the new things are compatible with the old? Maybe
    # setup a type union? Maybe croak? Maybe just carp? I don't know.

    $self->must_do($such_that->{does})  if defined $such_that->{does};
    $self->must_be_a($such_that->{isa}) if defined $such_that->{isa};
}

sub init_meta {
    my ($self, $meta, $name) = @_;

    $self->blueprint->init_meta($meta, $name);
    $self->scope->init_meta($meta, $name);

    # Add the actual artifact factory method
    $self->add_method($name => sub { $self });

    # # Add the actual artifact factory method
    # $meta->add_method($name => sub {
    #     my ($bag, %params) = @_;
    #     return $self->get($bag, %params);
    # });
}

sub get {
    my ($self, $bag, %input_params) = @_;
    
    my $name      = $self->name;
    my $blueprint = $self->blueprint;
    my $scope     = $self->scope;

    my $dependencies = $self->dependencies;
    my $parameters   = $self->parameters;

    my $artifact;

    # Load the artifact from the scope unless the blueprint implies scope
    $artifact = $scope->get($bag, $name)
        unless $blueprint->implied_scope;

    # The scope does not have it, so load it again from blueprints
    if (not defined $artifact) {

        $artifact = $blueprint->get($bag, $name, %params);

        Carp::croak("unable to build artifact $name from blueprint")
            unless defined $artifact;

        # Add the item into the scope for possible reuse from cache
        $scope->put($bag, $name, $artifact);
    }

    # TODO This would be a much more helpful check to apply ahead of time in
    # cases where we can. Possibly some sort of such_that check on the
    # blueprints to be handled when such checks can be sensibly handled
    # ahead of time.

    my $isa = $self->must_be_a;
    $isa->assert_valid($artifact) if defined $isa;

    my $does = $self->must_do;
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
