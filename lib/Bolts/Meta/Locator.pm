package Bolts::Meta::Locator;
use Moose;

with qw( Bolts::Role::Locator );

use Bolts::Artifact;
use Bolts::Artifact::Thunk;
use Bolts::Bag;

use Bolts::Blueprint::Built;
use Bolts::Blueprint::Factory;
use Bolts::Blueprint::Given;
use Bolts::Blueprint::Literal;

use Bolts::Injector::Parameter::ByName;

use Bolts::Scope::Prototype;
use Bolts::Scope::Singleton;

use Class::Load;

sub root { $_[0] }

has blueprint => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_blueprint {
    my $self = shift;

    my $bp = Bolts::Bag->start_bag(
        package      => 'Bolts::Meta::Locator::Blueprint',
        meta_locator => $self,
        such_that_each => {
            does => 'Bolts::Blueprint',
        },
    );

    return $bp->name->new if $bp->is_finished_bag;

    $bp->add_artifact(
        acquired => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Acquired');
                Bolts::Blueprint::Acquired->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        given => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Given');
                Bolts::Blueprint::Given->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        literal => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Literal');
                Bolts::Blueprint::Literal->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        built => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Built');
                Bolts::Blueprint::Built->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        built_injector => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::BuiltInjector');
                Bolts::Blueprint::BuiltInjector->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        factory => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Factory');
                Bolts::Blueprint::Factory->new(%o);
            },
        ),
    );

    $bp->finish_bag;

    return $bp->name->new;
}

has inference => (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy_build  => 1,
);

sub _build_inference {
    my $self = shift;

    my $singleton = $self->scope->singleton->get($self->scope);

    return [
        Bolts::Artifact->new(
            name      => 'moose',
            blueprint => Bolts::Blueprint::Factory->new(
                class => 'Bolts::Inference::Moose',
            ),
            scope     => $singleton,
        ),
    ];
}

has injector => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_injector {
    my $self = shift;

    my $prototype = $self->scope->prototype->get($self->scope);

    my $parameter_name = Bolts::Artifact->new(
        name      => 'parameter_name',
        blueprint => Bolts::Blueprint::Factory->new(
            class => 'Bolts::Injector::Parameter::ByName',
        ),
        scope     => $prototype,
        injectors => [
            Bolts::Injector::Parameter::ByName->new(
                key      => 'key',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 1,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'blueprint',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 1,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'does',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 0,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'isa',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 0,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'name',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 0,
                ),
            ),
        ],
    );

    my $bag = Bolts::Bag->start_bag(
        package        => 'Bolts::Meta::Locator::Injector',
        meta_locator   => $self,
        such_that_each => {
            does => 'Bolts::Injector',
        },
    );

    return $bag->name->new if $bag->is_finished_bag;

    $bag->add_artifact( parameter_name => $parameter_name );
    
    $bag->add_artifact(
        parameter_position => Bolts::Artifact->new(
            name      => 'parameter_position',
            blueprint => Bolts::Blueprint::Factory->new(
                class => 'Bolts::Injector::Parameter::ByPosition',
            ),
            infer     => 'options',
            scope     => $prototype,
        ),
    );

    $bag->add_artifact(
        setter => Bolts::Artifact->new(
            name      => 'setter',
            blueprint => Bolts::Blueprint::Factory->new(
                class => 'Bolts::Injector::Setter',
            ),
            infer     => 'options',
            scope     => $prototype,
        ),
    );

    $bag->add_artifact(
        store => Bolts::Artifact->new(
            name      => 'store',
            blueprint => Bolts::Blueprint::Factory->new(
                class => 'Bolts::Injector::Store',
            ),
            infer     => 'options',
            scope     => $prototype,
        ),
    );

    $bag->finish_bag;

    return $bag->name->new;
}

has scope => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_scope {
    my $self = shift;

    my $singleton = Bolts::Scope::Singleton->new;
    my $prototype = Bolts::Scope::Prototype->new;

    my $prototype_artifact = Bolts::Artifact->new(
        name      => 'prototype',
        blueprint => Bolts::Blueprint::Literal->new(
            value => $prototype,
        ),
        scope     => $singleton,
    );

    my $bag = Bolts::Bag->start_bag(
        package        => 'Bolts::Meta::Locator::Scope',
        meta_locator   => $self,
        such_that_each => {
            does => 'Bolts::Scope',
        },
    );

    return $bag->name->new if $bag->is_finished_bag;

    $bag->add_artifact(_         => $prototype_artifact);
    $bag->add_artifact(prototype => $prototype_artifact);

    $bag->add_artifact(
        singleton => Bolts::Artifact->new(
            name      => 'singleton',
            blueprint => Bolts::Blueprint::Literal->new(
                value => $singleton,
            ),
            scope     => $singleton,
        ),
    );

    return $bag->name->new;
}

1;
