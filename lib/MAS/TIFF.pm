#!/usr/bin/perl
#
# http://www.fileformat.info/format/tiff/corion.htm
#

use strict;
use warnings;
use FileHandle;

package MAS::TIFF::File;

sub io { return shift->{IO} }
sub ifds { return shift->{IFDS} }

1;

