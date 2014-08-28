package Bolts::Util;
use Moose ();
use Moose::Exporter;

use Bolts::Locator;
use Moose::Util;
use Safe::Isa;

Moose::Exporter->setup_import_methods(
    as_is => [ qw( locator_for meta_locator_for ) ],
);

sub locator_for {
    my ($bag) = @_;

    if ($bag->$_does('Bolts::Role::Locator')) {
        return $bag;
    }
    else {
        return Bolts::Locator->new($bag);
    }
}

sub meta_locator_for {
    my ($bag) = @_;

    my $meta = Moose::Util::find_meta($bag);
    if (defined $meta) {
        my $meta_meta = Moose::Util::find_meta($meta);
        if ($meta_meta->$_can('does_role') && $meta_meta->does_role('Bolts::Meta::Class::Trait::Locator')) {
            return $meta->locator;
        }
    }

    return $Bolts::GLOBAL_FALLBACK_META_LOCATOR->new;
}

1;
