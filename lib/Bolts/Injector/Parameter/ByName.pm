package Bolts::Injector::Parameter::ByName;
use Moose;

with 'Bolts::Injector';

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

has skip_undef => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 1,
);

sub _build_name { $_[0]->key }

sub pre_inject {
    my ($self, $loc, $in_params, $out_params) = @_;

    my $value = $self->get($loc, $in_params);

    return if $self->skip_undef and not defined $value;

    push @{ $out_params }, $self->name, $value;
}

sub post_inject { }

__PACKAGE__->meta->make_immutable;
