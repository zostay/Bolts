package Bolts;

# ABSTRACT: An Inversion of Control framework for Perl

use Moose ();
use Moose::Exporter;

use Class::Load ();
use Moose::Util::MetaRole ();
use Scalar::Util ();
use Carp ();

use Bolts::Util qw( locator_for );
use Bolts::Blueprint::Given;
use Bolts::Blueprint::Literal;
use Bolts::Blueprint::Built;

use Safe::Isa;

our @CARP_NOT = qw( Moose::Exporter );

# Ugly, but so far... necessary...
our $GLOBAL_FALLBACK_META_LOCATOR = 'Bolts::Meta::Locator';

my @BAG_META;

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        class => [ 
            'Bolts::Meta::Class::Trait::Locator',
            'Bolts::Meta::Class::Trait::Bag',
        ],
    },
    base_class_roles => [ 'Bolts::Role::SelfLocator' ],
    with_meta => [ qw(
        artifact bag builder contains dep parameter such_that_each
    ) ],
    also => 'Moose',
);

sub _bag_meta {
    my ($meta) = @_;

    $meta = $BAG_META[-1] if @BAG_META;

    return $meta;
}

=head1 SYNOPSIS

    package MyApp;
    use Bolts;

    artifcat log_file => 'var/messages.log';
    artifact logger   => (
        class => 'MyApp::Logger',
        scope => 'singleton',
        infer => 'dependencies',
    );

    # Later...
    my $log = $app->acquire('logger');
    $log->error("Bad stuff.");

=head1 DESCRIPTION

This is yet another Inversion of Control framework for Perl. This one is based upon a combination of L<Bread::Board>, concepts from the Spring framework, and a good mix of my own ideas and modifications after spending a few years using L<Moose> and Bread::Board.

=head2 Inversion of Control

For those who might now know what Inversion of Control (IOC) is, it is a design pattern aimed at helping you decouple your code, automate parts of the configuration assembly, and manage the life cycle of your objects.

By using an IOC framework, the objects in your program need to know less about the other objects in your application. Your objects can focus on knowing what it needs from other objects without knowing where to find objects that do that or how they are configured. 

For example, early in a programs lifetime, the logger might be a local object that writes directly to a file. Later, it might be an object with the same interface, but it writes to syslog. Further on, it might be some sort of logging service that is accessed over the network through a stub provided by a service locator. If your program uses an IOC framework, the configuration files for your IOC will change to pass a different object to the application during each phase, but the program itself might not change at all.

An IOC framework also helps you assemble complex configuration related to your application. It can join various configurations together in interesting and complex ways automatically.

An IOC framework can make sure that your objects live only as long as they should or longer than they would normally. It can manage the list of objects that should be created each time (prototypes), objects that should last as long as a user session, objects that should last as long as some request, and objects that last for the duration of the process (singletons).

The next sections will introduce the concepts and terminology used by this framework.

=head2 Artifacts

The basic building block of the Bolts IOC framework is the B<artifact>. At the simplest level, an artifact is any kind of thing your program might use. It might be a value, it might be a reference to something, it might be an object, or it might be something more complex.

For simple values and direct references to things, you can treat any thing as an artifact. However, the real power starts when you use an implementation of L<Bolts::Role::Artifact>, usually L<Bolts::Artifact> to manage that thing. These provide utilities for constructing an object or other value according to some set of instructions and directions for managing the lifecycle of the artifact in question.

=head2 Bags

Artifacts are grouped into bags. A B<bag> can be any object, hash reference, or array reference. Artifacts are associated with the bag as indexes in the array, keys on the hash, or methods on the object. Literally, any object can be used as a bag, which differs from frameworks like L<Bread::Board>, which requires that its services be put inside a special container object. Bolts just uses hashes, arrays, and objects in the usual Perl way to locate artifacts.

=head2 Locators

A B<locator> is an object that finds things in a bag (these are things related to L<Bolts::Role::Locator>. The finding process is called, B<acquisition>. (If you are familiar with Harry Potter, this process is similar to Harry Potter using a wand to extract dittany from Hermione's handbag by saying "Accio Dittany.") After finding the object, the locator performs B<resolution>, which checks to see if returned artifact needs to be resolved further. (To continue the analogy, this is like unbottling the dittany and pouring it out, there may be another step before the artifact is completely ready for use.)

=head2 Blueprints

Attached to L<Bolts::Artifact> definitions are a set of blueprints (some object that implements L<Bolts::Blueprint>). A B<blueprint> describes how an artifact is located or constructed, which is part of resolution. The system provides standard blueprints that can cover all possible needs, but you can create your own to extend the framework as necessary. The built-in blueprints can locate an object by acquring it from a bag, the result of a subroutine, by use of a factory method or constructor on an object, by directly handing the value in to the bag when the bag is constructed, or set as a constant.

=head2 Injectors

Another step in resolution is injection. An B<injector> associates additional artifacts with the artifact being resolved. This might be values that need to be passed to the artifact during construction, methods that need to be called to configure the object following construction, or even keys on a hash that need to be set on the artifact.

Injectors come in two flavors, dependency injection and parameter injection. With dependency injection, the framework will acquire or other provide addition artifacts to the artifact being resolved automatically, this is where much of the power of IOC comes from. Sometimes, however, an object just requires some configuration state to let it know how it will be used. In those cases, parameter injection can be used to let the caller to C<acquire> pass in the artifacts to be used for injection.

=head2 Scope

The B<scope> of an artifact determines during what period an artifact is valid. Bolts provides two built-in scopes, prototype and singleton. A prototype represents an artifact that must be resolved every time it is acquired. A singleton represents an artifact that is resolved only the first time it is acquired and is then reused for all following acquisitions for the lifetime of the bag.

=head2 Infererer

It is usually considered a bad thing in computer science if you have to configure something twice in the same program. Such duplication is tedious and leads to technical debt. This, unfortunately, is often the case when using some IOC frameworks. You configure the object once using Moose and then a second time to let the IOC framework know how to inject configuration into the artifact. This is where the inferers come in.

An B<inferer> is a tool that can inspect an object and automatically decide how that object should be configured. Bolts provides an inferer for L<Moose> that can use the metadata about a L<Moose> object to determine how to inject into that object automatically.

=head2 Meta Locator and Extension

One of the goals of this system is to have the system rely on the IOC internally as much as possible and to decouple the components as much as possible. This goal has not been totally achieved, but it is something strived for. The framework itself depends on L<Bolts::Meta::Locator>, which provides all the standard definitions internally. This can be extended to provide additional or even alternate features.

All the various components: artifact, bag, locator, blueprint, injector, scope, and inferer are completely extensible. You can create new versions of L<Bolts::Role::Artifact>. You can create bags from almost anything. You can create new locators via L<Bolts::Role::Locator>. You can create new blueprints via L<Bolts::Blueprint>. You can create new scopes via L<Bolts::Scope>. You can create new inferers via L<Bolts::Inferer>. You can then associate these components with the internals using L<Bolts::Meta::Locator>.

=head1 THIS CLASS

The purpose of the Bolts module itself is to provide some nice syntactic sugar for turning the class that uses it into a bag and locator.

=head1 FUNCTIONS

=head2 artifact

    artifact 'name';
    artifact name => $value;
    artifact name => %options;

This defines an artifact in the current class. This will create a method on the current object with the given "name". If only the name is given, then the artifact to use must be passed when the bag is constructed.

    # for example, if you bag is named "MyApp"
    my $bag = MyApp->new( name => 42 );
    my $value = $bag->acquire('name');
    say $value; # 42

If a scalar or reference is passed in as a single argument in addition to the name, the artifact will be set to that literal value.

Otherwise, you may pass in a list of pairs, which will be interpreted depending on the keys present. Here is a list of keys and their meanings:

=over

=item path

This is like an alias to an artifact elsewhere within this bag or in another bag (if "locator" is passed as well). It is set to a reference to an array of names, naming the path within the bag to acquire. See L<Bolts::Blueprint::Acquired> for details.

=item value

This sets the artifact to a literal value, similar to passing C<$value> in the example above. See L<Bolts::Blueprint::Literal> for details.

=item class

This should be set to a package name. This causes the artifact to construct and return the value from a factory method or constructor. See L<Bolts::Blueprint::Factory> for details.

=item builder

This should be set to a subroutine. The subroutine will be called to attain this artifact and the return value used as the artifact. See L<Bolts::Blueprint::Builder> for details.

=item blueprint

This is set to the name of a L<Bolts::Blueprint> definition and allows you to specify the blueprint you wish to use directly.

=item scope

In addition to the options above, you may also specify the scope. This is usually either "prototype" or "singleton" and the default is generally "prototype".

=back

=cut

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

        # Is the service class named?
        if (defined $params{blueprint}) {
            $blueprint_name = delete $params{blueprint};
        }

        # Is it an acquired?
        elsif (defined $params{path} && $params{path}) {
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

        else {
            Carp::croak("unable to determine what kind of service $name is in ", $meta->name);
        }
    }

    my @injectors;
    if (defined $params{dependencies}) {
        my $dependencies = delete $params{dependencies};

        if ($dependencies->$_does('Bolts::Blueprint')) {
            Carp::croak("invalid blueprint in dependencies")
                unless defined $dependencies and $dependencies->$_does('Bolts::Blueprint::Role::Injector');
            push @injectors,
                $meta->acquire('injector', 'parameter_position', {
                    key       => '0',
                    blueprint => $dependencies,
                }),
        }
        elsif (ref $dependencies eq 'HASH') {
            for my $key (keys %$dependencies) {
                my $blueprint = $dependencies->{$key};

                Carp::croak("invalid blueprint in dependencies $key")
                    unless defined $blueprint and $blueprint->$_does('Bolts::Blueprint::Role::Injector');

                push @injectors, 
                    $meta->acquire('injector', 'parameter_name', {
                        key       => $key,
                        blueprint => $blueprint,
                    });
            }
        }
        elsif (ref $dependencies eq 'ARRAY') {
            my $key = 0;
            for my $blueprint (@$dependencies) {

                Carp::croak("invalid blueprint in dependencies $key")
                    unless defined $blueprint and $blueprint->$_does('Bolts::Blueprint::Role::Injector');

                push @injectors, 
                    $meta->acquire('injector', 'parameter_position', {
                        key       => $key++,
                        blueprint => $blueprint,
                    });
            }
        }
        else {
            Carp::croak("dependencies must be a blueprint, an array of blueprints, or a hash with blueprint values");
        }
    }

    # TODO Remember the service for introspection

    my $scope_name = delete $params{scope} // '_';
    my $infer      = delete $params{infer} // 'none';

    my $scope      = $meta->acquire('scope', $scope_name);

    my $blueprint  = $meta->acquire('blueprint', $blueprint_name, \%params);

    my $artifact = Bolts::Artifact->new(
        name         => $name,
        blueprint    => $blueprint,
        scope        => $scope,
        infer        => $infer,
        injectors    => \@injectors,
    );

    $meta->add_artifact($name, $artifact);
    return;
}

=head2 bag

    bag 'name' => contains {
        artifact 'child_name' => 42;
    };

Attaches a bag at the named location. This provides tools for assembling complex IOC configurations.

=cut

our @BAG_OF_BUILDING;
sub bag {
    my ($meta, $name, $partial_def) = @_;

    $meta = _bag_meta($meta);

    my $def = $partial_def->($name);
    $meta->add_artifact($name, sub { $def });
}

sub contains(&) {
    my ($parent_meta, $code) = @_;

    my $meta = _bag_meta($parent_meta);

    return sub {
        my ($name) = shift;

        my $parent = $meta->name;

        my $bag_meta = Bolts::Bag->start_bag(
            package => "${parent}::$name",
        );
        push @BAG_META, $bag_meta;

        $code->($bag_meta);

        pop @BAG_META;

        $bag_meta->finish_bag;
        return $bag_meta->name->new;
    };
}

sub such_that_each(@) {
    my ($meta, %params) = @_;

    $meta = _bag_meta($meta);

    ...
}

sub builder(&) {
    my ($meta, $code) = @_;
    $meta = _bag_meta($meta);

    return $meta->acquire('blueprint', 'built_injector', {
        builder => $code,
    });
}

sub dep($) {
    my ($meta, @path) = @_;
    $meta = _bag_meta($meta);

    return $meta->acquire('blueprint', 'acquired', {
        path => \@path,
    });
}

sub parameter($) {
    my ($meta, $param) = @_;

    return $meta->acquire('blueprint', 'given', $param);
}

sub value($) {
    my ($meta, $value) = @_;

    return $meta->acquire('blueprint', 'literal', {
        value => $value,
    });
}

1;
