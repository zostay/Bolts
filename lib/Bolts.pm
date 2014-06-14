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

# TODO This sugar requires special knowledge of the built-in blueprint
# types. It would be slick if this was not required. On the other hand, that
# sounds like very deep magic and that might just be taking the magic too far.
sub artifact {
    my $meta = shift;
    my $name = shift;

    # No arguments means it's a given 
    my $blueprint_name;
    my %params;
    if (@_ == 0) {
        $blueprint_name = 'given';
    }

    # One argument means it's a literal
    elsif (@_ == 1) {
        $blueprint_name = 'literal';
        $params{value} = $_[0];
    }

    # Otherwise, we gotta figure out what it is...
    else {
        my %params = @_;

        # Is it a given?
        if (defined $params{given} && $params{given}) {
            $blueprint_name = 'given';
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

    my $blueprint = $meta->acquire('blueprint', $blueprint_name, \%params);

    my $artifact = Bolts::Artifact->new(
        name         => $name,
        blueprint    => $blueprint,
        scope        => $scope,
    );

    # Setup the artifact factory method and any other accoutrements required
    # by the blueprint or scope
    $artifact->init_meta($meta, $name);
}

sub bag {
    my ($meta, $name, $def) = @_;

    ...
}

sub contains(&) {
    my ($meta, $code) = @_;

    ...
}

sub such_that_each(@) {
    my ($meta, %params) = @_;

    ...
}

1;
