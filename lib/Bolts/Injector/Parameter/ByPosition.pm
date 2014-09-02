package Bolts::Injector::Parameter::ByPosition;
use Moose;

with 'Bolts::Injector';

sub pre_inject {
    my ($self, $loc, $in_params, $out_params) = @_;

    my $value = $self->get($loc, $in_params);

    push @{ ${ $out_params } }, $value;
}

sub post_inject { }

__PACKAGE__->meta->make_immutable;
