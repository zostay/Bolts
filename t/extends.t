#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 11;

{
    package BaseBag;
    use Bolts;

    artifact one => 1;
    
    artifact two => 2;

    bag ay => contains {
        artifact three => 3;

        artifact four => 4;
    };
}

{
    package SubBag;
    use Bolts;

    extends 'BaseBag';

    artifact '+two' => 20;

    artifact five => 5;

    bag '+ay' => contains {
        artifact '+four' => 40;

        artifact six => 6;
    };

    bag bee => contains {
        artifact 'seven' => 7;
    };
}

my $base = BaseBag->new;
is($base->acquire('one'), 1);
is($base->acquire('two'), 2);
is($base->acquire('ay', 'three'), 3);
is($base->acquire('ay', 'four'), 4);

my $sub = SubBag->new;
is($sub->acquire('one'), 1);
is($sub->acquire('two'), 20);
is($sub->acquire('ay', 'three'), 3);
is($sub->acquire('ay', 'four'), 40);
is($sub->acquire('five'), 5);
is($sub->acquire('ay', 'six'), 6);
is($sub->acquire('bee', 'seven'), 7);
