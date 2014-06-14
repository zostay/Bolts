package Injector::Dependency;
use Moose;

extends 'Injector::Parameter';

requires 'get_value';

around get => sub {
    my $next = shift;
    my ($self, $bag, %params) = @_;

    my $value = $self->get_value($bag);
    $params{ $self->key } = $value;

    return $self->$next($bag, %params);
};

__PACKAGE__->meta->make_immutable;
