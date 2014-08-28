#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 9;

{
    package Foo;
    use Moose;

    has id => (
        is          => 'ro',
        isa         => 'Int',
        lazy_build  => 1,
    );

    my $counter = 1;
    sub _build_id { $counter++ }

    __PACKAGE__->meta->make_immutable;
}

{
    package Artifacts;
    use Bolts;
    
    artifact 'acquired';

    artifact literal => 42;

    artifact class => (
        class => 'Foo',
    );

    artifact singleton_class => (
        class => 'Foo',
        scope => 'singleton',
    );

    bag 'bag' => contains {
        artifact class => (
            class => 'Foo',
        );
    };

    __PACKAGE__->meta->make_immutable;
}

my $locator = Artifacts->new( acquired => 'something' );;
diag explain $locator;
ok($locator);

# Via the acquire method
is($locator->acquire('acquired'), 'something');
is($locator->acquire('literal'), 42);
is($locator->acquire('class')->id, 1);
is($locator->acquire('class')->id, 2);
is($locator->acquire('singleton_class')->id, 3);
is($locator->acquire('singleton_class')->id, 3);
is($locator->acquire('bag', 'class')->id, 4);
is($locator->acquire('bag', 'class')->id, 5);
