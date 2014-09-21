package Bolts::Role::Locator;

# ABSTRACT: Interface for locating artifacts in a bag

use Moose::Role;

use Bolts::Locator;
use Bolts::Util;
use Carp ();
use Safe::Isa;
use Scalar::Util ();

=head1 DESCRIPTION

This is the interface that any locator must implement. A locator's primary job is to provide a way to find artifacts within a bag or selection of bags. This performs the acquisition and resolution process. This actually also implements everything needed for the process except for the L</root>.

=head1 REQUIRED METHODS

=head2 root

This is the object to use as the bag to start searching. It may be an object, a reference to an array, or a reference to a hash.

=cut

requires 'root';

=head1 METHODS

=head2 resolve

    my $resolved_artifact = $loc->resolve($bag, $artifact, \%options);

After the artifact has been found, this method resolves the a partial artifact implementing the L<Bolts::Role::Artifact> and turns it into the complete artifact.

=cut

sub resolve {
    my ($self, $bag, $item, $parameters) = @_;

    return $item->get($bag, %$parameters)
        if $item->$_can('does')
       and $item->$_does('Bolts::Role::Artifact');

    return $item;
}

=head2 acquire

    my $artifact = $loc->acquire(\@path);

Given a C<@path> of symbol names to traverse, this goes through each artifact in turn, resolves it, if necessary, and then continues to the next path component.

When complete, the complete, resolved artifact found is returned.

=cut

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

=head2 get

    my $artifact = $log->get($bag, $component, $current_path)

Given a bag and a single symbol name as the next path component to find during acquisition it returns the artifact (possibly still needing resolution).

=cut

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

=head2 acquire_all

    my @artifacts = @{ $loc->acquire_all(\@path) };

This is similar to L<acquire>, but if the last bag is a reference to an array, then all the artifacts within that bag are acquired, resolved, and returned as a reference to an array.

If the last item found at the path is not an array, it returns an empty list.

=cut

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
