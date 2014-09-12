package Bolts::Role::Locator;
use Moose::Role;

use Bolts::Locator;
use Bolts::Util;
use Carp ();
use Safe::Isa;
use Scalar::Util ();

requires 'root';

sub resolve {
    my ($self, $bag, $item, $parameters) = @_;

    return $item->get($bag, %$parameters)
        if $item->$_can('does')
       and $item->$_does('Bolts::Role::Artifact');

    return $item;
}

sub acquire {
    my ($self, @path) = @_;

    my $parameters = {};
    if (@path > 1 and ref $path[-1]) {
        $parameters = pop @path;
    }
    
    my $current_path = '';

    my $item = $self->root;
    while (@path) {
        my $component = shift @path;

        my $bag = $item;
        $item = $self->get($bag, $component, $current_path);
        $item = $self->resolve($bag, $item, $parameters);

        $current_path .= ' ' if $current_path;
        $current_path .= qq["$component"];
    }

    return $item;
}

sub get {
    my ($self, $bag, $component, $current_path) = @_;

    Carp::croak("unable to acquire artifact for [$current_path]")
        unless defined $bag;

    # A bag can be any blessed object...
    if (Scalar::Util::blessed($bag)) {

        # So long as it has that method
        if ($bag->can($component)) {
            return $bag->$component;
        }
        
        else {
            Carp::croak(qq{no artifact named "$component" at [$current_path]});
        }
    }

    # Or any unblessed hash
    elsif (ref $bag eq 'HASH') {
        return $bag->{ $component };
    }

    # Or any unblessed array
    elsif (ref $bag eq 'ARRAY') {
        return $bag->[ $component ];
    }

    # But nothing else...
    else {
        Carp::croak(qq{not able to acquire artifact for [$current_path "$component"]});
    }
}

sub acquire_all {
    my ($self, @path) = @_;

    my $parameters = {};
    if (@path > 1 and ref $path[-1]) {
        $parameters = pop @path;
    }
    
    my $bag = $self->acquire(@path);
    if (ref $bag eq 'ARRAY') {
        return [
            map { $self->resolve($bag, $_, $parameters) } @$bag
        ];
    }

    else {
        return [];
    }
}

1;
