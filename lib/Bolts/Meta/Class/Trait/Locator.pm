package Bolts::Meta::Class::Trait::Locator;

# ABSTRACT: Metaclass role for objects that have a meta locator

use Moose::Role;

use Bolts::Meta::Locator;

=head1 DESCRIPTION

This is another handy feature for use when constructing and managing a bag of artifacts. It provides a meta locator to the class for looking up standard Bolts objects like blueprints, scopes, injectors, inferrers, etc.

=head1 ATTRIBUTES

=head2 locator

This returns an implementation of L<Bolts::Role::Locator> containing the needed standard Bolts objects.

Defaults to a new object from L<Bolts/$Bolts::GLOBAL_FALLBACK_META_LOCATOR>, which defaults to L<Bolts::Meta::Locator>.

=cut

has locator => (
    is          => 'rw',
    does        => 'Bolts::Role::Locator',
    lazy_build  => 1,
    handles     => 'Bolts::Role::Locator',
);

sub _build_locator {
    $Bolts::GLOBAL_FALLBACK_META_LOCATOR->new;
}

1;
