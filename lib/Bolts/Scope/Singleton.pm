package Bolts::Scope::Singleton;
use Moose;

use Hash::Util::FieldHash 'fieldhash';

with 'Bolts::Scope';

fieldhash my %singleton;

sub get {
    my ($self, $bag, $name) = @_;

    return unless defined $singleton{$bag};
    return unless defined $singleton{$bag}{$name};
    return $singleton{$bag}{$name};
}

sub put {
    my ($self, $bag, $name, $artifact) = @_;

    $singleton{$bag} = {} unless defined $singleton{$bag};
    $singleton{$bag}{$name} = $artifact;
    return;
}

__PACKAGE__->meta->make_immutable;
