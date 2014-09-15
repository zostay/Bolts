package Bolts::Blueprint::Role::Injector;

# ABSTRACT: Tags a blueprint as being usable during injection

use Moose::Role;

with 'Bolts::Blueprint';

=head1 DESCRIPTION

This role tags a class as a blueprint that may be used for injection. The difference between a common blueprint and an injector blueprint is that the parameters passed for an injector will always be passed as a hash in list form. Whereas a regular blueprint may receive any kind of argument list. Also, the injection parameters are not as well targeted or filtered as they are during regular blueprint resolution.

A blueprint may implement this instead of L<Bolts::Blueprint> if it could be useful to during injection and ignores or is able to process parameters as a hash.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint>

=back

=cut

1;
