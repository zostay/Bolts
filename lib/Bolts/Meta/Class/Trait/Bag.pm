package Bolts::Meta::Class::Trait::Bag;

# ABSTRACT: Metaclass role for Bolts-built bags

use Moose::Role;

use Safe::Isa;
use Scalar::Util qw( reftype );

=head1 DESCRIPTION

While a bag may be any kind of object, this metaclass role on a bag provides some helpful utilities for creating and managing bags.

=head1 ATTRIBUTES

=head2 such_that_isa

This is a L<Moose::Meta::TypeConstraint> to apply to the L<Bolts::Artifact/isa_type> of all contained artifacts.

=cut

has such_that_isa => (
    is          => 'rw',
    isa         => 'Moose::Meta::TypeConstraint',
    predicate   => 'has_such_that_isa',
);

=head2 such_that_does

This is a L<Moose::Meta::TypeConstraint> to apply to the L<Bolts::Artifact/does_type> of all contained artifacts.

=cut

has such_that_does => (
    is          => 'rw',
    isa         => 'Moose::Meta::TypeConstraint',
    predicate   => 'has_such_that_does',
);

=head1 METHODS

=head2 is_finished_bag

    my $finished = $meta->is_finished_bag;

This is used to determine if a bag's definition has already been performed and completed. At this time, it's just a synonym for L<Class::MOP::Class/is_immutable>.

=cut

sub is_finished_bag {
    my $meta = shift;
    return $meta->is_immutable;
}

=head2 add_artifact

    $meta->add_artifact(name => $artifact, {
        isa  => $isa_type,
        does => $does_type,
    });    

Adds an artifact method to the bag with the given C<name>. The C<$artifact> may be an instance of L<Bolts::Role::Artifact>, a code reference to used to define a L<Bolts::Artifact::Thunk> or just another value, which will be wrapped in an anonymous sub and turned into a L<Bolts::Artifact::Thunk>.

The C<isa> and C<does> will be applied to the artifact as appropriate.

=cut

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

=head2 finish_bag

    $meta->finish_bag;

This completes the bag building process and marks the Moose object as immutable. Aft this is called, L</is_finished_bag> returns true.

=cut

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
