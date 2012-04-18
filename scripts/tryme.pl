#!/usr/bin/perl
#
# http://www.fileformat.info/format/tiff/corion.htm
#

use strict;
use warnings;

use FileHandle;

use MAS::TIFF::IO;
use MAS::TIFF::Rational;
use MAS::TIFF::DataType;
use MAS::TIFF::Field;
use MAS::TIFF::IFD;
use MAS::TIFF::File;

my $path = 't/original.tif';
#my $path = 't/noisy.tif';
#my $path = 't/diffuse.tif';
#my $path = 't/multi.tif';

my $tif = MAS::TIFF::File->new($path);
$tif->dump;

for my $ifd ($tif->ifds) {
  for my $y (0..70) {
    for my $x (0..70) {
      print $ifd->pixel_at($x, $y) ? '.' : '*';
    }
    print "\n";
  }
}

$tif->close;

exit 0;
