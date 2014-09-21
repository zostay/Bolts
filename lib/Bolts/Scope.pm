package Bolts::Scope;

# ABSTRACT: The interface for lifecycle managers

use Moose::Role;

=head1 DESCRIPTION

This describes the interface to be implemented by all artifact scopes, which are used to manage the lifecycles of artifacts in the Bolts system.

=head1 REQUIRED METHODS

=head2 get

    my $artifact = $scope->get($bag, $name);

Fetches the named value out of the scope cache for the given bag.

=head2 put

    $scope->put($bag, $name, $artifact);

Stores the named value into the scope cache for the given bag.

=cut

requires 'get';
requires 'put';

1;
