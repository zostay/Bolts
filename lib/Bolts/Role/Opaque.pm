package Bolts::Role::Opaque;

# ABSTRACT: Make a bag/artifact opaque to acquisition

use Moose::Role;

=head1 SYNOPSIS

    package MyApp::Secrets;
    use Moose;

    with 'Bolts::Role::Opaque';

    sub foo { "secret" }

    package MyApp;
    use Bolts;

    artifact 'secrets' => (
        class => 'MyApp::Secrets',
    );

    my $bag = MyApp->new;
    my $secrets = $bag->acquire('secrets'); # OK!
    my $foo     = $secrets->foo;            # OK!

    # NO NO NO! Croaks.
    my $foo_direct = $bag->acquire('secrets', 'foo'); # NO!

=head1 DESCRIPTION

Marks an artifact/bag so that the item cannot be reached via the C<acquire> method. 

Why? I don't know. It seemed like a good idea.

=cut

1;
