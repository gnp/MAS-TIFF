use strict;
use warnings;

package MAS::TIFF::Rational;

sub numerator { return shift->[0] }
sub denominator { return shift->[1] }

sub to_string {
  my $self = shift;

  if ($self->denominator == 1) {
    return $self->numerator;
  }
  else {
    return sprintf("(%d / %d)", $self->numerator, $self->denominator);
  }
}

1;
