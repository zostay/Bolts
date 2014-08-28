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

    my $bp = Bolts::Bag->create_or_reuse(
        package  => 'Bolts::Meta::Locator::Blueprint',
        contents => {
            acquired => Bolts::Artifact::Thunk->new(
                thunk => sub {
                    my ($self, $bag, %o) = @_;
                    Class::Load::load_class('Bolts::Blueprint::Acquired');
                    Bolts::Blueprint::Acquired->new(%o);
                },
            ),
            given => Bolts::Artifact::Thunk->new(
                thunk => sub {
                    my ($self, $bag, %o) = @_;
                    Class::Load::load_class('Bolts::Blueprint::Given');
                    Bolts::Blueprint::Given->new(%o);
                },
            ),
            literal => Bolts::Artifact::Thunk->new(
                thunk => sub {
                    my ($self, $bag, %o) = @_;
                    Class::Load::load_class('Bolts::Blueprint::Literal');
                    Bolts::Blueprint::Literal->new(%o);
                },
            ),
            built => Bolts::Artifact::Thunk->new(
                thunk => sub {
                    my ($self, $bag, %o) = @_;
                    Class::Load::load_class('Bolts::Blueprint::Built');
                    Bolts::Blueprint::Built->new(%o);
                },
            ),
            factory => Bolts::Artifact::Thunk->new(
                thunk => sub {
                    my ($self, $bag, %o) = @_;
                    Class::Load::load_class('Bolts::Blueprint::Factory');
                    Bolts::Blueprint::Factory->new(%o);
                },
            ),
        },
        such_that_each => {
            does => 'Bolts::Blueprint',
        },
    );
    return $bp;
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

    my $singleton = $self->scope->singleton->get($self->scope);

    my $parameter_name = Bolts::Artifact->new(
        name      => 'parameter_name',
        blueprint => Bolts::Blueprint::Factory->new(
            class => 'Bolts::Injector::Parameter::ByName',
        ),
        scope     => $singleton,
        injectors => [
            Bolts::Injector::Parameter::ByName->new(
                key      => 'key',
                artifact => Bolts::Artifact->new(
                    name => 'key',
                    blueprint => Bolts::Blueprint::Given->new(
                        required => 1,
                    ),
                    scope     => $singleton,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'artifact',
                artifact => Bolts::Artifact->new(
                    name => 'artifact',
                    blueprint => Bolts::Blueprint::Given->new(
                        required => 1,
                    ),
                    scope     => $singleton,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'does',
                artifact => Bolts::Artifact->new(
                    name => 'does',
                    blueprint => Bolts::Blueprint::Given->new(
                        required => 0,
                    ),
                    scope     => $singleton,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'isa',
                artifact => Bolts::Artifact->new(
                    name => 'isa',
                    blueprint => Bolts::Blueprint::Given->new(
                        required => 0,
                    ),
                    scope     => $singleton,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'name',
                artifact => Bolts::Artifact->new(
                    name => 'name',
                    blueprint => Bolts::Blueprint::Given->new(
                        required => 0,
                    ),
                    scope     => $singleton,
                ),
            ),
        ],
    );

    return Bolts::Bag->create_or_reuse(
        package  => 'Bolts::Meta::Locator::Injector',
        contents => {
            parameter_name => $parameter_name,
            parameter_position => Bolts::Artifact->new(
                name      => 'parameter_position',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Injector::Parameter::ByPosition',
                ),
                infer     => 'parameters',
                scope     => $singleton,
            ),
            setter => Bolts::Artifact->new(
                name      => 'setter',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Injector::Parameter::ByPosition',
                ),
                infer     => 'parameters',
                scope     => $singleton,
            ),
            store => Bolts::Artifact->new(
                name      => 'store',
                blueprint => Bolts::Blueprint::Factory->new(
                    class => 'Bolts::Injector::Store',
                ),
                infer     => 'parameters',
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

    return Bolts::Bag->create_or_reuse(
        package  => 'Bolts::Meta::Locator::Scope',
        contents => {
            _         => $prototype_artifact,
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
