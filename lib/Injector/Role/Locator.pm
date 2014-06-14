package Injector::Role::Locator;
use Moose::Role;

use Carp ();
use Safe::Isa;
use Scalar::Util ();

requires 'root';

sub acquire {
    my ($self, @path) = @_;

    my $parameters;
    if (@path > 1 and ref $path[-1]) {
        $parameters = pop @path;
    }
    
    my $current_path = '';

    my $item = $self->root;
    while (@path) {
        my $component = shift @path;

        my $bag = $item;
        $item = $self->get($bag, $component, $current_path);

        if ($item->$_does('Injector::Role::Artifact')) {
            my $loc = $self->locator_for($bag);
            $item = $item->get($loc, %$parameters);
        }

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

sub locator_for {
    my ($self, $bag) = @_;

    if ($bag->$_does('Injector::Role::Locator')) {
        return $bag;
    }
    else {
        return Injector::Locator->new($bag);
    }
}

# Get all in a bag
sub acquire_all { ... }

1;
