package Bolts::Role::Meta::Instance;
use Moose::Role;

around get_slot_value => sub {
    my $next = shift;
    my $self = shift;
    my $value = $self->$next(@_);

    return $value->();
}

1;
