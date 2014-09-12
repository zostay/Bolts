package Bolts::Bag;
use Moose;

use Carp;
use Moose::Util::MetaRole;
use Moose::Util::TypeConstraints;
use Safe::Isa;
use Scalar::Util qw( blessed reftype );

sub start_bag {
    my ($class, %params) = @_;

    my $package        = $params{package};
    my $meta_locator   = $params{meta_locator};
    my $such_that_each = $params{such_that_each};

    my $meta;
    my %options = (superclasses => [ 'Moose::Object' ]);
    if (defined $package) {
        $meta = Moose::Util::find_meta($package);
        if (defined $meta) {
            return $meta;
        }

        $meta = Moose::Meta::Class->create($package, %options);
    }
    else {
        $meta = Moose::Meta::Class->create_anon_class(%options);
    }

    Moose::Util::MetaRole::apply_base_class_roles(
        for   => $meta,
        roles => [ 'Bolts::Role::SelfLocator' ],
    );

    $meta = Moose::Util::MetaRole::apply_metaroles(
        for             => $meta,
        class_metaroles => {
            class => [ 
                'Bolts::Meta::Class::Trait::Locator',
                'Bolts::Meta::Class::Trait::Bag',
            ],
        },
    );

    if ($such_that_each) {
        my $such_that = $class->_expand_such_that($such_that_each);
        if (defined $such_that->{does}) {
            $meta->such_that_does($such_that->{does});
        }
        if (defined $such_that->{isa}) {
            $meta->such_that_isa($such_that->{isa});
        }
    }

    if ($meta_locator) {
        $meta->locator($meta_locator);
    }

    Carp::cluck("bad meta @{[$meta->name]}") unless $meta->can('locator');

    return $meta;
}

sub _expand_such_that {
    my ($class, $such_that) = @_;

    $such_that //= {};
    my %expanded_such_that;

    if (defined $such_that->{isa}) {
        $expanded_such_that{isa} = Moose::Util::TypeConstraints::find_or_create_isa_type_constraint($such_that->{isa});
    }

    if (defined $such_that->{does}) {
        $expanded_such_that{does} = Moose::Util::TypeConstraints::find_or_create_does_type_constraint($such_that->{does});
    }

    return \%expanded_such_that;
}


__PACKAGE__->meta->make_immutable;
