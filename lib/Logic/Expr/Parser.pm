# -*- Perl -*-
#
# a parser for logic expressions

package Logic::Expr::Parser 0.01;
use base 'Parser::MGC';    # 0.21 or higher required
use Logic::Expr;

use constant { TRUE => 1, FALSE => 0 };

sub on_parse_start
{
    my ($self) = @_;
    $self->@{qw/_atoms _bools/} = ( {}, [] );
}

sub on_parse_end
{
    my ( $self, $ref ) = @_;
    Logic::Expr->new(
        atoms => $self->{_atoms},
        bools => $self->{_bools},
        expr  => $ref
    );
}

sub parse
{
    my ( $self, $less ) = @_;
    my $first = $self->any_of(
        sub {
            # logic book uses '~' for negation; '!' is also supported
            # here and is used internally as that better matches Perl
            my $nots = $self->expect(qr/[!~]+/);
            # !!X -> X, !!!X -> !X, etc instead of a needlessly deep tree
            length($nots) & 1 ? [ '!', $self->parse(1) ] : $self->parse(1);
        },
        sub { $self->scope_of( "(", \&parse, ")" ) },
        sub {
            # this allows for more descriptive expressions such as
            # GILBERT&SULLIVAN instead of just G&S or such
            my $atom = $self->expect(qr/[A-Z]+/);
            unless ( exists $self->{_atoms}->{$atom} ) {
                push $self->{_bools}->@*, TRUE;
                $self->{_atoms}->{$atom} = \$self->{_bools}[-1];
            }
            $self->{_atoms}->{$atom};
        },
    );
    my $rest;
    unless ($less) {
        # TODO this allows trailing empty "S&T&" logical ops, a
        # documented feature of list_of and common in Perl structures
        # (2,3,5,) but not at all typical in logical expressions
        $rest = $self->maybe(
            sub {
                my $op  = $self->expect(qr/[v&]/);
                my $ret = $self->list_of( $op, sub { $self->parse(1) } );
                die "no alt??" unless $ret->@*;    # TODO can this happen?
                [ $op, $ret->@* ];
            }
        );
    }
    if ($rest) {
        splice @$rest, 1, 0, $first;
        return $rest;
    }
    $first;
}

1;
__END__

=head1 NAME

Logic::Expr - logical expression parsing and related routines

=head1 SYNOPSIS

  use Logic::Expr::Parser;

  # Parser::MGC also supports "from_file"
  my $le = Logic::Expr::Parser->new->from_string('Xv~Y');

  # then see Logic::Expr for uses of the $le object

=head1 DESCRIPTION

L<Logic::Expr::Parser> parses logic expressions and returns a
L<Logic::Expr> object, which in turn has various methods for solving all
possible solutions, etc.

L<Parser::MGC> is the parent class of this module used to parse the
logic expressions.

=head1 BUGS

None known.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
