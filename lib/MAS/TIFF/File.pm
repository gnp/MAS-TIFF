use strict;
use warnings;

package MAS::TIFF::File;

sub io { return shift->{IO} }
sub ifds { return shift->{IFDS} }

1;
