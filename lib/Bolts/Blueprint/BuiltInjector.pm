package Bolts::Blueprint::BuiltInjector;

# ABSTRACT: An injector-oriented builder using a subroutine

use Moose;

with 'Bolts::Blueprint::Role::Injector';

use Carp ();

=head1 SYNOPSIS

    use Bolts;

    # Using the usual sugar...
    artifact thing => (
        ...
        parameters => {
            thing => builder {
                my ($self, $bag, %params) = @_;
                return MyApp::Thing->new(%params);
            },
        },
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        ...
        injectors => [
            $meta->locator->acquire('injector', 'parameter_name', {
                key       => 'thing',
                blueprint => $meta->locator->acquire('blueprint', 'built_injector', {
                    builder => sub {
                        my ($self, $bag, %params) = @_;
                        return MyApp::Thing->new(%params);
                    },
                }),
            }),
        ],
    );

=head1 DESCRIPTION

This is a blueprint for using a subroutine to fill in an injected artifact dependency.

This differs from L<Bolts::Blueprint::Built> in that it implements L<Bolts::Blueprint::Role::Injector>, which tags this has only accepting named parameters to the builder method, which is required during injection.

B<Caution:> As of this writing the builder subroutine receives only some of the arguments normally passed to the blueprint builder method. This will probably change.

=head1 ROLES

=over

=item *

L<Bolts::Blueprint::Role::Injector>

=back

=head1 ATTRIBUTES

=head2 builder

B<Required.> This is the subroutine to execute to construct the artifact. The reader for this attribute is named C<the_builder>.

=cut

has builder => (
    isa         => 'CodeRef',
    reader      => 'the_builder',
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
    my ($self, $bag, $name, %params) = @_;
    $self->call_builder($bag, %params);
}

__PACKAGE__->meta->make_immutable;
