package Bolts::Bag;
use Moose;

use Moose::Util::TypeConstraints;
use Safe::Isa;
use Scalar::Util qw( blessed reftype );

sub create {
    my ($class, %params) = @_;

    my $package   = $params{package};
    my $contents  = $params{contents};
    my $such_that = $class->expand_such_that($params{such_that_each});

    my $meta;
    if (defined $package) {
        $meta = Moose::Meta::Class->create($package);
    }
    else {
        $meta = Moose::Meta::Class->create_anon_class;
    }

    for my $method (keys %$contents) {
        my $value = $contents->{$method};

        if ($value->$_isa('Bolts::Artifact')) {
            $value->such_that($such_that);
            $value->init_meta($meta, $method);
        }
        elsif (reftype($value) eq 'CODE') {
            $value = $class->wrap_method_in_such_that_check($value);
            $meta->add_method($method => $value);
        }
        else {
            # TODO It would be better to asert the validity of the checks on
            # the value immediately.

            $value = $class->wrap_method_in_such_that_check(sub { $value });
            $meta->add_method($method => $value);
        }
    }

    $meta->make_immutable;
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
