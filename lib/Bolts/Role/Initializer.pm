package Bolts::Role::Initializer;

# ABSTRACT: Give components some control over their destiny

use Moose::Role;

requires 'init_locator';

sub initialize_value {
    my $self = shift;
    return $self->locator->acquire(@_);
}

1;
