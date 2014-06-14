package Bolts::Meta::Locator;
use Moose;

with qw( Bolts::Role::Locator );

use Bolts::Artifact;
use Bolts::Bag;

use Bolts::Blueprint::Built;
use Bolts::Blueprint::Factory;
use Bolts::Blueprint::Given;
use Bolts::Blueprint::Literal;

use Bolts::Scope::Prototype;
use Bolts::Scope::Singleton;

sub root { $_[0] }

# AKA Eating our own dog food, albeit without any sugar to make it go down
# easier.

has blueprint => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_blueprint {
    my $self = shift;

    my $prototype = $self->scope->prototype;

    return Bolts::Bag->create(
        package  => 'Bolts::Meta::Locator::Blueprint',
        contents => {
            given => Bolts::Artifact->new(
                name      => 'given',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Blueprint::Given',
                ),
                scope     => $prototype,
                infer     => 'parameters',
            ),
            literal => Bolts::Artifact->new(
                name      => 'literal',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Blueprint::Literal',
                ),
                scope     => $prototype,
                infer     => 'parameters',
            ),
            built => Bolts::Artifact->new(
                name      => 'built',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Blueprint::Literal',
                ),
                scope     => $prototype,
                infer     => 'parameters',
            ),
            factory => Bolts::Artifact->new(
                name      => 'factory',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Blueprint::Factory',
                ),
                scope     => $prototype,
                infer     => 'parameters',
            ),
        },
        such_that_each => {
            does => 'Bolts::Blueprint',
        },
    );
}

has inference => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_inference {
    my $self = shift;

    my $singleton = $self->scope->singleton;

    return Bolts::Bag->create(
        package => 'Bolts::Meta::Locator::Inference',
        contents => {
            moose => Bolts::Artifact->new(
                name      => 'moose',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Inference::Moose',
                ),
                scope     => $singleton,
            ),
        },
    );
}

has injector => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_injector {
    my $self = shift;

    my $singleton = $self->scope->singleton;

    my $parameter_name = Bolts::Artifact->new(
        name      => 'parameter_name',
        blueprint => Bolts::Blueprint::Factory->new(
            class => 'Bolts::Injector::ParameterName',
        ),
        scope     => $singleton,
    );

    return Bolts::Bag->create(
        package  => 'Bolts::Meta::Locator::Injector',
        contents => {
            parameter_name => $parameter_name,
            parameter_position => Bolts::Artifact->new(
                name      => 'parameter_position',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Injector::ParameterPosition',
                ),
                scope     => $singleton,
            ),
            setter => Bolts::Artifact->new(
                name      => 'setter',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Injector::ParameterPosition',
                ),
                scope     => $singleton,
            ),
            store => Bolts::Artifact->new(
                name      => 'store',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Injector::Store',
                ),
                scope     => $singleton,
            ),
        },
        such_that_each => {
            does => 'Bolts::Injector',
        },
    );
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

    return Bolts::Bag->create(
        package  => 'Bolts::Meta::Locator::Scope',
        contents => {
            _ => $prototype_artifact,
            prototype => $prototype_artifact,
            singleton => Bolts::Artifact->new(
                name      => 'singleton',
                blueprint => Bolts::Blueprint::Literal->new(
                    value => $singleton,
                ),
                scope     => $singleton,
            ),
        },
        such_that_each => {
            does => 'Bolts::Scope',
        },
    );
}

1;
