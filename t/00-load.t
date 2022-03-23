#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Logic::Expr' ) || print "Bail out!\n";
}

diag( "Testing Logic::Expr $Logic::Expr::VERSION, Perl $], $^X" );
