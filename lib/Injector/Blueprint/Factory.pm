package Injector::Blueprint::Factory;
use Moose;

with 'Injector::Blueprint';

use Class::Load ();

has class => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has method => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'new',
);

sub init_meta { }

sub builder {
    my ($self) = @_;

    my $class = $self->class;
    my $method = $self->method;

    sub {
        my ($self, $bag, $name, @params) = @_;

        Class::Load::load_class($class);

        return $class->$method(@params);
    };
}

__PACKAGE__->meta->make_immutable;
