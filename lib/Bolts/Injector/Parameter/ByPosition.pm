package Bolts::Injector::Parameter::ByPosition;
use Moose;

with 'Bolts::Injector';

sub pre_inject {
    my ($self, $loc, %in_params, $out_params) = @_;

    my $value = $self->get($loc, %in_params);

    Carp::croak('You cannot mix parameters by position and by name.')
        if defined ${ $out_params }
       and (not defined ref ${ $out_params } or ref ${ $out_params } ne 'ARRAY');

    ${ $out_params } //= [];
    push @{ ${ $out_params } }, $value;
}

sub post_inject { }

__PACKAGE__->meta->make_immutable;
