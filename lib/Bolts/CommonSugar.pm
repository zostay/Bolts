package Bolts::CommonSugar;

use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_meta => [ qw(
        artifact bag builder contains dep option self such_that_each value
    ) ],
);

sub artifact {
    my $meta = shift->_bag_meta;
    my $artifact = Bolts::Util::artifact($meta, @_);
    $meta->add_artifact(%$artifact);
    return;
}

sub bag {
    my ($meta, $name, $partial_def) = @_;

    my $extends = 0;
       $extends = 1 if $name =~ s/^\+//;

    $meta = $meta->_bag_meta;

    my $def = $partial_def->(
        name    => $name,
        extends => $extends,
    );

    $meta->add_artifact(
        $name => Bolts::Artifact->new(
            name      => $name,
            blueprint => $meta->acquire('blueprint', 'factory', {
                class     => $def->name,
            }),
            injectors => [
                $meta->acquire('injector', 'parameter_name', {
                    key       => '__parent',
                    blueprint => $meta->acquire('blueprint', 'parent_bag'),
                }),
            ],
            infer => 'options',
            scope => $meta->acquire('scope', 'singleton'),
        )
    );
}

sub contains(&;$) {
    my ($parent_meta, $code, $such_that_each) = @_;

    my $meta = $parent_meta->_bag_meta;

    return sub {
        my (%params) = @_;

        my $name    = $params{name};
        my $extends = $params{extends};

        my $parent  = $meta->name;

        my @superclass;
        if ($extends) {
            my %artifacts = $meta->get_all_artifacts;
            my $extend_artifact = $artifacts{$name};

            Carp::croak("Cannot extend bag +$name: No such bag defined in parent")
                unless defined $extend_artifact;

            # TODO This is *very* specific. It would be nice to
            # extrapolate into a more general solution.
            #
            # Also, just because the factory calls a class method on a given
            # class does not mean it returns an object of that class.
            Carp::croak("Cannot extend bag +$name: Unable to determine class of bag")
                unless $extend_artifact->blueprint->isa('Bolts::Blueprint::Factory');

            @superclass = ($extend_artifact->blueprint->class);
        }

        my $bag_meta = Bolts::Bag->start_bag(
            package => "${parent}::$name",
            extends => \@superclass,
            ($such_that_each ? (such_that_each => $such_that_each) : ()),
        );
        $parent_meta->_enter_bag($bag_meta);

        $bag_meta->add_attribute(__parent => (
            reader   => '__parent',
            required => 1,
            default  => sub { Carp::confess('why are we here?') },
            weak_ref => 1,
        ));

        $bag_meta->add_artifact(
            __top => Bolts::Artifact->new(
                meta_locator => $bag_meta,
                name         => '__top',
                blueprint    => $bag_meta->acquire('blueprint', 'acquired', {
                    path => [ '__parent', '__top' ],
                }),
                scope        => $bag_meta->acquire('scope', 'prototype'),
            )
        );

        $code->($bag_meta);

        $parent_meta->_exit_bag;

        $bag_meta->finish_bag;

        return $bag_meta;
    };
}

sub such_that_each($) {
    my ($meta, $params) = @_;
    return $params;
}

sub builder(&) {
    my ($meta, $code) = @_;
    $meta = $meta->_bag_meta;

    return {
        blueprint => $meta->acquire('blueprint', 'built_injector', {
            builder => $code,
        }),
    };
}

sub dep($) {
    my ($meta, $path) = @_;
    $meta = $meta->_bag_meta;

    $path = [ $path ] unless ref $path eq 'ARRAY';

    my @path = ('__top', @$path);

    return {
        blueprint => $meta->acquire('blueprint', 'acquired', {
            path => \@path,
        }),
    };
}

sub option($) {
    my ($meta, $p) = @_;

    my %bp = %$p;
    my %ip;
    for my $k (qw( isa does )) {
        $ip{$k} = delete $bp{$k} if exists $bp{$k};
    }

    return {
        %ip,
        blueprint => $meta->acquire('blueprint', 'given', \%bp),
    },
}

sub value($) {
    my ($meta, $value) = @_;

    return {
        blueprint => $meta->acquire('blueprint', 'literal', {
            value => $value,
        }),
    };
}

sub self() {
    my ($meta) = @_;
    $meta = $meta->_bag_meta;

    return {
        blueprint => $meta->acquire('blueprint', 'acquired', {
            path => [ '__top' ],
        }),
    };
}

1;
