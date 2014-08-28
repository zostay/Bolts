package Bolts::Injector::Parameter;
use Moose;

with 'Bolts::Injector';

has name => (
    is          => 'ro',
    isa         => 'Str',
    lazy_build  => 1,
);

sub _build_name { $_[0]->key }

sub pre_inject {
    my ($self, $loc, %in_params, $out_params) = @_;
    
    my $value = $self->get($loc, %params);
    $out_params->{ $self->name } = $value;
}

sub post_inject { }

__PACKAGE__->meta->make_immutable;
