package Bolts::Util;

# ABSTRACT: Utilities helpful for use with Bolts

use Moose ();
use Moose::Exporter;

use Bolts::Locator;
use Moose::Util;
use Safe::Isa;
use Hash::Util::FieldHash 'fieldhash';

Moose::Exporter->setup_import_methods(
    as_is => [ qw( locator_for meta_locator_for ) ],
);

fieldhash my %locator;
fieldhash my %meta_locator;

=head1 SYNOPSIS

    use Bolts::Util qw( locator_for meta_locator_for );

    my $loc   = locator_for($bag);
    my $thing = $loc->acquire('path', 'to', 'thing');

    my $metaloc = meta_locator_for($bag);
    my $blueprint = $metaloc->acquire('blueprint', 'factory', {
        class  => 'MyApp::Thing',
        method => 'fetch',
    });

=head1 DESCRIPTION

This provides some helpful utility methods for use with Bolts.

=head1 EXPORTED FUNCTIONS

=head2 locator_for

    my $loc = locator_for($bag);

Given a bag, it will return a L<Bolts::Role::Locator> for acquiring artifacts from it. If the bag provides it's own locator, the bag will be returned. If it doesn't (e.g., if it's a hash or an array or just some other object that doesn't have a locator built-in), then a new locator will be built to locate within the bag and returned on the first call. Subsequent calls using the same reference will return the same locator object.

=cut

sub locator_for {
    my ($bag) = @_;

    if ($bag->$_does('Bolts::Role::Locator')) {
        return $bag;
    }
    elsif (defined $locator{ $bag }) {
        return $locator{ $bag };
    }
    else {
        return $locator{ $bag } = Bolts::Locator->new($bag);
    }
}

=head2 meta_locator_for

    my $metaloc = meta_locator_for($bag);

Attempts to find the meta locator for the bag. It returns a L<Bolts::Role::Locator> that is able to return artifacts used to manage a collection of bolts bags and artifacts. If the bag itself does not have such a locator associated with it, one is constructed using the L<Bolts/$Bolts::GLOBAL_FALLBACK_META_LOCATOR> class, which is L<Bolts::Meta::Locator> by default. After the first call, the object created the first time for each reference will be reused.

=cut

sub meta_locator_for {
    my ($bag) = @_;

    my $meta = Moose::Util::find_meta($bag);
    if (defined $meta) {
        my $meta_meta = Moose::Util::find_meta($meta);
        if ($meta_meta->$_can('does_role') && $meta_meta->does_role('Bolts::Meta::Class::Trait::Locator')) {
            return $meta->locator;
        }
    }

    elsif (defined $meta_locator{ $bag }) {
        return $meta_locator{ $bag };
    }

    return $meta_locator{ $bag } = $Bolts::GLOBAL_FALLBACK_META_LOCATOR->new;
}

1;
