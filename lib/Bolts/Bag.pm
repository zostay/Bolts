package Bolts::Bag;
use Moose;

use Carp;
use Moose::Util::MetaRole;
use Moose::Util::TypeConstraints;
use Safe::Isa;
use Scalar::Util qw( blessed reftype );

sub start {
    my ($class, %params) = @_;

    my $package   = $params{package};

    my $meta;
    my %options = (superclasses => [ 'Moose::Object' ]);
    if (defined $package) {
        $meta = Moose::Util::find_meta($package);
        if (defined $meta) {
            Carp::croak("The package ", $meta->name, " is already defined. You cannot create another bag there.");
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
            class => [ 'Bolts::Meta::Class::Trait::Locator' ],
        },
    );

    Carp::cluck("bad meta @{[$meta->name]}") unless $meta->can('locator');

    return $meta;
}

sub create {
    my ($class, %params) = @_;

    my $contents  = $params{contents};
    my $such_that = $class->expand_such_that($params{such_that_each});

    my $meta = $class->start(%params);

    for my $method (keys %$contents) {
        my $value = $contents->{$method};
        $class->add_item($meta, $method, $value, $such_that);
    }

    return $class->finish($meta);
}

sub create_or_reuse {
    my ($class, %params) = @_;

    my $package = $params{package};
    my $meta    = Moose::Util::find_meta($package);

    if (defined $meta) {
        return $meta->name->new;
    }
    else {
        return $class->create(%params);
    }
}

sub add_item {
    my ($class, $meta, $method, $value, $such_that) = @_;

    if ($value->$_does('Bolts::Role::Artifact')) {
        $value->such_that($such_that) if $such_that;
        $meta->add_method($method => sub { $value });
    }

    elsif (reftype($value) eq 'CODE') {
        $value = $class->wrap_method_in_such_that_check($value, $such_that)
            if $such_that;
        $meta->add_method($method => $value);
    }

    else {
        # TODO It would be better to assert the validity of the checks on
        # the value immediately.

        $value = $class->wrap_method_in_such_that_check(sub { $value }, $such_that)
            if $such_that;
        $meta->add_method($method => $value);
    }

}

sub finish {
    my ($class, $meta) = @_;

    $meta->make_immutable(
        replace_constructor => 1,
        replace_destructor  => 1,
    );

    return $meta->name->new;
}

sub expand_such_that {
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

sub wrap_method_in_such_that_check {
    my ($class, $code, $such_that) = @_;

    my $wrapped;
    if (defined $such_that->{isa} or defined $such_that->{does}) {
        $wrapped = sub {
            my $result = $code->(@_);

            $such_that->{isa}->assert_valid($result)
                if defined $such_that->{isa};

            $such_that->{does}->assert_valid($result)
                if defined $such_that->{does};

            return $result;
        };
    }
    else {
        $wrapped = sub {
            return scalar $code->(@_);
        };
    }

    return $wrapped;
}

__PACKAGE__->meta->make_immutable;
