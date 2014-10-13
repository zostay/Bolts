package Bolts::Meta::Attribute::Traits::Initializer;

# ABSTRACT: Build an attribute with an initializer

use Moose::Role;
use Safe::Isa;

Moose::Util::meta_attribute_alias('Bolts::Initializer');

# TODO Make this into a helper class so that other kinds of init can be added
# and customized later.
use Moose::Util::TypeConstraints;
has init_type => (
    is          => 'ro',
    isa         => enum([qw( Array Scalar )]),
    required    => 1,
    default     => 'Scalar',
);
no Moose::Util::TypeConstraints;

has special_initializer => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has _original_default => (
    is          => 'rw',
    predicate   => '_has_original_default',
);

before install_accessors => sub {
    my $self = shift;
    my $meta = $self->associated_class;

    $meta->add_attribute($self->special_initializer => (
        is       => 'ro',
        required => $self->is_required,
        init_arg => $self->name,
        ($self->_has_original_default ? (
            default  => $self->_original_default
        ) : ()),
    ));
};

before _process_options => sub {
    my ($self, $name, $options) = @_;

    # Having these here is probably a sign that we're doing this wrong.
    # Should probably just have the default call some predefined subroutine
    # instead and skip these bits here.
    $options->{special_initializer} //= '_' . $name . '_initializer';
    $options->{init_type}           //= 'Scalar';

    my $_initializer = $options->{special_initializer};

    $options->{_original_default} = delete $options->{default}
        if exists $options->{default};

    $options->{init_arg}  = undef;
    $options->{lazy}      = 1;

    if ($options->{init_type} eq 'Scalar') {
        $options->{default} = sub {
            my $self = shift;

            my $init = $self->$_initializer;
            if ($init->$_isa('Bolts::Meta::Initializer')) {
                return $self->initialize_value($init->get);
            }
            else {
                return $init;
            }
        };
    }
    else {
        $options->{default} = sub {
            my $self = shift;

            my @values;
            my $init_array = $self->$_initializer;
            for my $init (@$init_array) {
                if ($init->$_isa('Bolts::Meta::Initializer')) {
                    push @values, $self->initialize_value($init->get);
                }
                else {
                    push @values, $init;
                }
            }

            return \@values;
        };
    }
};

1;
