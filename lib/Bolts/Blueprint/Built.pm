package Bolts::Blueprint::Built;

# ABSTRACT: Build an artifact by running a subroutine

use Moose;

with 'Bolts::Blueprint';

use Carp ();

=head1 SYNOPSIS

    use Bolts;

    # Using the usual sugar...
    artifact thing => (
        builder => sub {
            my ($self, $bag, $name, @params) = @_;
            return MyApp::Thing->new(@params);
        },
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        name      => 'thing',
        blueprint => $meta->locator->acquire('blueprint', 'built', {
            builder => sub {
                my ($self, $bag, $name, @params) = @_;
                return MyApp::Thing->new(@params);
            },
        }),
        scope    => $meta->locator->acquire('scope', '_'),
    );

=head1 DESCRIPTION

This is a blueprint for constructing an artifact using a custom subroutine. This is handy for gluing anything to anything.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint>

=back

=head1 ATTRIBUTES

=head2 builder

B<Required.> This is the subroutine to execute to construct the artifact. The reader for this attribute is named C<the_builder>.

=cut

has builder => (
    isa         => 'CodeRef',
    reader      => 'the_builder',
    required    => 1,
    traits      => [ 'Code' ],
    handles     => {
        'call_builder' => 'execute_method',
    },
);

=head1 METHODS

=head2 builder

This executes the subroutine in the C<builder> attribute.

=cut

sub builder {
    my ($self, $bag, $name, @params) = @_;
    $self->call_builder($bag, $name, @params);
}

__PACKAGE__->meta->make_immutable;
