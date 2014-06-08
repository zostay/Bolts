package Injector::Blueprint::Built;
use Moose;

with 'Injector::Blueprint';

use Carp ();

has builder => (
    isa         => 'CodeRef',
    reader      => 'the_builder',
);

sub init_meta { }

sub builder {
    my ($self) = @_;

    my $builder = $self->the_builder;
    return sub {
        my ($self, $bag, $name, @params) = @_;
        $builder->($bag, @params);
    };
}

__PACKAGE__->meta->make_immutable;
