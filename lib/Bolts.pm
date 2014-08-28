package Bolts;
use Moose ();
use Moose::Exporter;

use Class::Load ();
use Moose::Util::MetaRole ();
use Scalar::Util ();
use Carp ();

use Bolts::Blueprint::Given;
use Bolts::Blueprint::Literal;
use Bolts::Blueprint::Built;

our @CARP_NOT = qw( Moose::Exporter );

# Ugly, but so far... necessary...
our $GLOBAL_FALLBACK_META_LOCATOR = 'Bolts::Meta::Locator';

my @BAG_META;

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        class => [ 'Bolts::Meta::Class::Trait::Locator' ],
    },
    base_class_roles => [ 'Bolts::Role::SelfLocator' ],
    with_meta => [ qw(
        artifact bag contains such_that_each
    ) ],
    also => 'Moose',
);

sub _bag_meta {
    my ($meta) = @_;

    $meta = $BAG_META[-1] if @BAG_META;

    return $meta;
}


# TODO This sugar requires special knowledge of the built-in blueprint
# types. It would be slick if this was not required. On the other hand, that
# sounds like very deep magic and that might just be taking the magic too far.
sub artifact {
    my $meta = _bag_meta(shift);
    my $name = shift;

    # No arguments means it's a given 
    my $blueprint_name;
    my %params;
    if (@_ == 0) {
        $blueprint_name = 'acquired';
        $params{path}   = [ "__auto_$name" ];
        $meta->add_attribute("__auto_$name" =>
            is       => 'ro',
            init_arg => $name,
        );
    }

    # One argument means it's a literal
    elsif (@_ == 1) {
        $blueprint_name = 'literal';
        $params{value} = $_[0];
    }

    # Otherwise, we gotta figure out what it is...
    else {
        %params = @_;

        # Is it an acquired?
        if (defined $params{path} && $params{path}) {
            $blueprint_name = 'acquired';
        }

        # Is it a literal?
        elsif (exists $params{value}) {
            $blueprint_name = 'literal';
        }

        # Is it a factory blueprint?
        elsif (defined $params{class}) {
            $blueprint_name = 'factory';
        }

        # Is it a builder blueprint?
        elsif (defined $params{builder}) {
            $blueprint_name = 'built';
        }

        # Is the service class named?
        elsif (defined $params{blueprint}) {
            $blueprint_name = delete $params{blueprint};
        }

        else {
            Carp::croak("unable to determine what kind of service $name is in ", $meta->name);
        }
    }

    # TODO Remember the service for introspection

    my $scope_name = delete $params{scope} // '_';

    my $scope      = $meta->acquire('scope', $scope_name);

    my $blueprint  = $meta->acquire('blueprint', $blueprint_name, \%params);

    my $artifact = Bolts::Artifact->new(
        name         => $name,
        blueprint    => $blueprint,
        scope        => $scope,
    );

    Bolts::Bag->add_item($meta, $name, $artifact);
    return;
}

our @BAG_OF_BUILDING;
sub bag {
    my ($meta, $name, $partial_def) = @_;

    $meta = _bag_meta($meta);

    my $def = $partial_def->($name);
    Bolts::Bag->add_item($meta, $name, sub { $def });
}

sub contains(&) {
    my ($parent_meta, $code) = @_;

    my $meta = _bag_meta($parent_meta);

    return sub {
        my ($name) = shift;

        my $parent = $meta->name;

        my $bag_meta = Bolts::Bag->start(
            package => "${parent}::$name",
        );
        push @BAG_META, $bag_meta;

        $code->($bag_meta);

        pop @BAG_META;

        return Bolts::Bag->finish($bag_meta);
    };
}

sub such_that_each(@) {
    my ($meta, %params) = @_;

    $meta = _bag_meta($meta);

    ...
}

1;
