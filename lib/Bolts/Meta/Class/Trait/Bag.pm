package Bolts::Meta::Class::Trait::Bag;

use Moose::Role;

use Safe::Isa;
use Scalar::Util qw( reftype );

has such_that_isa => (
    is          => 'rw',
    isa         => 'Moose::Meta::TypeConstraint',
    predicate   => 'has_such_that_isa',
);

has such_that_does => (
    is          => 'rw',
    isa         => 'Moose::Meta::TypeConstraint',
    predicate   => 'has_such_that_does',
);

sub is_finished_bag {
    my $meta = shift;
    return $meta->is_immutable;
}

sub add_artifact {
    my ($meta, $method, $value, $such_that) = @_;
    
    if (!defined $such_that and ($meta->has_such_that_isa
                             or  $meta->has_such_that_does)) {
        $such_that = {};
        $such_that->{isa}  = $meta->such_that_isa
            if $meta->has_such_that_isa;
        $such_that->{does} = $meta->such_that_does
            if $meta->has_such_that_does;
    }

    if ($value->$_does('Bolts::Role::Artifact')) {
        $value->such_that($such_that) if $such_that;
        $meta->add_method($method => sub { $value });
    }

    elsif (defined reftype($value) and reftype($value) eq 'CODE') {
        my $thunk = Bolts::Artifact::Thunk->new(
            %$such_that,
            thunk => $value,
        );

        $meta->add_method($method => sub { $thunk });
    }

    else {
        # TODO It would be better to assert the validity of the checks on
        # the value immediately.

        my $thunk = Bolts::Artifact::Thunk->new(
            %$such_that,
            thunk => sub { $value },
        );

        $meta->add_method($method => sub { $thunk });
    }

}

sub finish_bag {
    my ($meta) = @_;

    $meta->make_immutable(
        replace_constructor => 1,
        replace_destructor  => 1,
    );

    return $meta;
}

sub _wrap_method_in_such_that_check {
    my ($meta, $code, $such_that) = @_;

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


1;
