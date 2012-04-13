use strict;
use warnings;

package MAS::TIFF::Field;

sub id { return shift->{ID} }
sub name { return shift->{NAME} }
sub type { return shift->{TYPE} }
sub count { return shift->{COUNT} }
sub offset { return shift->{OFFSET} }

1;
