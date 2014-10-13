package Bolts::Meta::Initializer;

# ABSTRACT: Store a path and parameters for acquisition

use Moose;

has path => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    traits      => [ 'Array' ],
    handles     => { list_path => 'elements' },
);

has parameters => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

sub BUILDARGS {
    my ($self, @path) = @_;

    my $parameters = {};
    if (@path > 1 and ref $path[-1]) {
        $parameters = pop @path;
    }

    return {
        path       => \@path,
        parameters => $parameters,
    };
}

sub get {
    my $self = shift;
    return ($self->list_path, $self->parameters);
}

__PACKAGE__->meta->make_immutable;
