package Injector::Meta::Locator;
use Moose;

with qw( Injector::Role::Locator );

use Injector::Artifact;
use Injector::Bag;

use Injector::Blueprint::Built;
use Injector::Blueprint::Factory;
use Injector::Blueprint::Given;
use Injector::Blueprint::Literal;

use Injector::Scope::Prototype;
use Injector::Scope::Singleton;

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

    return Injector::Bag->create(
        package  => 'Injector::Meta::Locator::Blueprint',
        contents => {
            given => Injector::Artifact->new(
                name      => 'given',
                blueprint => Injector::Blueprint::Factory->new(
                    class => 'Injector::Blueprint::Given',
                ),
                scope     => $prototype,
                infer     => 'parameters',
            ),
            literal => Injector::Artifact->new(
                name      => 'literal',
                blueprint => Injector::Blueprint::Factory->new(
                    class => 'Injector::Blueprint::Literal',
                ),
                scope     => $prototype,
                infer     => 'parameters',
            ),
            built => Injector::Artifact->new(
                name      => 'built',
                blueprint => Injector::Blueprint::Factory->new(
                    class => 'Injector::Blueprint::Literal',
                ),
                scope     => $prototype,
                infer     => 'parameters',
            ),
            factory => Injector::Artifact->new(
                name      => 'factory',
                blueprint => Injector::Blueprint::Factory->new(
                    class => 'Injector::Blueprint::Factory',
                ),
                scope     => $prototype,
                infer     => 'parameters',
            ),
        },
        such_that_each => {
            does => 'Injector::Blueprint',
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

    my $parameter_name = Injector::Artifact->new(
        name      => 'parameter_name',
        blueprint => Injector::Blueprint::Factory->new(
            class => 'Injector::Injector::ParameterName',
        ),
        scope     => $singleton,
    );

    return Injector::Bag->create(
        package  => 'Injector::Meta::Locator::Injector',
        contents => {
            _ => $parameter_name,
            parameter_name => $parameter_name,
            parameter_position => Injector::Artifact->new(
                name      => 'parameter_position',
                blueprint => Injector::Blueprint::Factory->new(
                    class => 'Injector::Injector::ParameterPosition',
                ),
                scope     => $singleton,
            ),
            setter => Injector::Artifact->new(
                name      => 'setter',
                blueprint => Injector::Blueprint::Factory->new(
                    class => 'Injector::Injector::ParameterPosition',
                ),
                scope     => $singleton,
            ),
            store => Injector::Artifact->new(
                name      => 'store',
                blueprint => Injector::Blueprint::Factory->new(
                    class => 'Injector::Injector::Store',
                ),
                scope     => $singleton,
            ),
        },
        such_that_each => {
            does => 'Injector::Injector',
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

    my $singleton = Injector::Scope::Singleton->new;
    my $prototype = Injector::Scope::Prototype->new;

    my $prototype_artifact = Injector::Artifact->new(
        name      => 'prototype',
        blueprint => Injector::Blueprint::Literal->new(
            value => $prototype,
        ),
        scope     => $singleton,
    );

    return Injector::Bag->create(
        package  => 'Injector::Meta::Locator::Scope',
        contents => {
            _ => $prototype_artifact,
            prototype => $prototype_artifact,
            singleton => Injector::Artifact->new(
                name      => 'singleton',
                blueprint => Injector::Blueprint::Literal->new(
                    value => $singleton,
                ),
                scope     => $singleton,
            ),
        },
        such_that_each => {
            does => 'Injector::Scope',
        },
    );
}

1;
