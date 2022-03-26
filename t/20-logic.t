#!perl
#
# is the logic at least not terrible? also some code coverage

use Test2::V0;

plan(11);

use Logic::Expr::Parser;
my $le = Logic::Expr::Parser->new;
my $pe;

$pe = $le->from_string('X|Y');
is( $pe->solutions,
    [   [ [ 1, 1 ], 1, ],    # T
        [ [ 1, 0 ], 1, ],    # T
        [ [ 0, 1 ], 1, ],    # T
        [ [ 0, 0 ], 0 ]      # F
    ]
);

$pe = $le->from_string('X&Y');
is( $pe->solutions,
    [   [ [ 1, 1 ], 1, ],    # T
        [ [ 1, 0 ], 0, ],    # F
        [ [ 0, 1 ], 0, ],    # F
        [ [ 0, 0 ], 0 ]      # F
    ]
);

$pe = $le->from_string('X->Y');
is( $pe->solutions,
    [   [ [ 1, 1 ], 1, ],    # T
        [ [ 1, 0 ], 0, ],    # F
        [ [ 0, 1 ], 1, ],    # T
        [ [ 0, 0 ], 1 ]      # T
    ]
);

$pe = $le->from_string('X==Y');
is( $pe->solutions,
    [   [ [ 1, 1 ], 1, ],    # T
        [ [ 1, 0 ], 0, ],    # F
        [ [ 0, 1 ], 0, ],    # F
        [ [ 0, 0 ], 1 ]      # T
    ]
);

$pe = $le->from_string('~(X->Y)');
is( $pe->solutions,
    [   [ [ 1, 1 ], 0, ],    # F
        [ [ 1, 0 ], 1, ],    # T
        [ [ 0, 1 ], 0, ],    # F
        [ [ 0, 0 ], 0 ]      # F
    ]
);

# was bools changed by solutions? (shouldn't be)
is( $pe->bools, [ 1, 1 ] );

$pe->bools->[1] = 0;
is( $pe->solve, 1 );    # [1,0] case from prior solutions call
# solve should not be fiddling with bools
is( $pe->bools, [ 1, 0 ] );

$pe->bools->[0] = 0;
is( $pe->solve, 0 );

$pe->{expr}->[0] = -1;    # FAKE_OP
like( dies { $pe->solve }, qr/unknown op/ );

$pe->{expr} = {};
like( dies { $pe->solve }, qr/unexpected reference type/ );
