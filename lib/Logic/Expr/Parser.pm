# -*- Perl -*-
#
# a parser for logic expressions

package Logic::Expr::Parser;
our $VERSION = '0.01';
use Logic::Expr ':all';
use base 'Parser::MGC';    # 0.21 or higher required

# LE_NOT is handled outside the scope of this pair of variables
our %le_map = (
    '&'  => LE_AND,
    '|'  => LE_OR,
    'v'  => LE_OR,
    '->' => LE_COND,
    '==' => LE_BICOND,
);
our $le_regex = qr/->|==|[&|v]/;

sub on_parse_start
{
    my ($self) = @_;
    # hopefully these never conflict with Parser::MGC internals
    @$self{qw(_atoms _bools)} = ( {}, [] );
}

sub on_parse_end
{
    my ( $self, $tree ) = @_;
    Logic::Expr->new(
        atoms => $self->{_atoms},
        bools => $self->{_bools},
        expr  => $tree
    );
}

sub parse
{
    my ($self) = @_;
    my $first = $self->parse_term;
    my ( $operator, $second );
    $self->maybe(
        sub {
            $operator = $le_map{ $self->expect($le_regex) };
            $second   = $self->parse_term;
        }
    );
    defined $operator ? [ $operator, $first, $second ] : $first;
}

sub parse_term
{
    my ($self) = @_;
    my $neg    = $self->maybe( sub { $self->expect(qr/!+|~+/) } );
    my $term   = $self->any_of(
        sub { $self->scope_of( "(", \&parse, ")" ) },
        sub {
            my $atom = $self->expect(qr/[A-Z]+/);
            unless ( exists $self->{_atoms}->{$atom} ) {
                push @{ $self->{_bools} }, TRUE;
                $self->{_atoms}->{$atom} = \$self->{_bools}->[-1];
            }
            $self->{_atoms}->{$atom};
        },
    );
    # simplify !!!X to !X and !!X to X
    ( defined $neg and length($neg) & 1 ) ? [ LE_NOT, $term ] : $term;
}

1;
__END__

=head1 NAME

Logic::Expr - logical expression parsing and related routines

=head1 SYNOPSIS

  use Logic::Expr::Parser;

  # Parser::MGC also supports "from_file"
  my $le = Logic::Expr::Parser->new->from_string('Xv~Y');

  # and then see Logic::Expr for uses of the $le object

=head1 DESCRIPTION

This module parses logic expressions and returns a L<Logic::Expr>
object, which in turn has various methods for acting on the expression
thus parsed.

L<Parser::MGC> is the parent class used to parse the expressions;
B<from_string> and B<from_file> are the most relevant methods.

=head1 SYNTAX SANS EBNF

The usual atomic letters (C<X>, C<Y>, etc) are extended to include words
in captial letters to allow for more than 26 atoms, or at least more
descriptive names.

Operators include C<!> or C<~> for negation of the subsequent atom or
parenthesized term, and the binary operators

  | v  or            TTTF lojban .a
  &    and           TFFF lojban .e
  ->   conditional   TFTT lojban .a with first term negated
  ==   biconditional TFFT lojban .o

which taken together allow for such expressions as

  X&!Y
  X|~Y
  GILBERT&SULLIVAN
  (CATvDOG)->FISH
  ETC

=head1 MINUTIAE

=over 4

=item B<on_parse_end>

Internal L<Parser::MGC> hook function.

=item B<on_parse_start>

Internal L<Parser::MGC> hook function.

=item B<parse>

Internal L<Parser::MGC> function.

=item B<parse_term>

Called by the internal L<Parser::MGC> function.

=back

=head1 BUGS

None known.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
