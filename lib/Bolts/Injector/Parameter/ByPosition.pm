package Bolts::Injector::Parameter::ByPosition;

# ABSTRACT: Inject parameters by position during construction

use Moose;

with 'Bolts::Injector';

=head1 SYNOPSIS

    use Bolts;

    artifact thing => (
        class => 'MyApp::Thing',
        parameters => [
            dep('other_thing'),
        ],
    );

=head1 DESCRIPTION

Inject parameters by position during construction.

=head1 ROLES

=over

=item *

L<Bolts::Injector>

=back

=head1 METHODS

=head2 pre_inject

Perform the pre-injection of the parameter by position.

=cut

sub pre_inject {
    my ($self, $loc, $in_params, $out_params) = @_;

    my $value = $self->get($loc, $in_params);

    push @{ ${ $out_params } }, $value;
}

=head2 post_inject

No-op.

=cut

sub post_inject { }

__PACKAGE__->meta->make_immutable;
