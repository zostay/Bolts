#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 17;

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
    use Injector::Locator;

    artifact 'given';

    artifact literal => 42;

    artifact class => (
        class => 'Foo',
    );

    artifact singleton_class => (
        class => 'Foo',
        scope => 'singleton',
    );

    # bag 'bag' => contains {
    #     artifact bag_class => (
    #         class => 'Foo',
    #     );
    # };

    __PACKAGE__->meta->make_immutable;
}

my $locator = Artifacts->new( given => 'something' );;
ok($locator);

# Via attribute accessor
is($locator->given, 'something');
is($locator->literal, 42);
is($locator->class->id, 1);
is($locator->class->id, 2);
is($locator->singleton_class->id, 3);
is($locator->singleton_class->id, 3);
is($locator->bag->class->id, 4);
is($locator->bag->class->id, 4);

# Via the acquire method
is($locator->acquire('given'), 'something');
is($locator->acquire('literal'), 42);
is($locator->acquire('class')->id, 5);
is($locator->acquire('class')->id, 6);
is($locator->acquire('singleton_class')->id, 3);
is($locator->acquire('singleton_class')->id, 3);
is($locator->acquire('bag/class')->id, 7);
is($locator->acquire('bag/class')->id, 8);
