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

sub read_tif {
  my $path = shift;
  
  my $tif = MAS::TIFF::File->new($path);
  $tif->dump;
  
  $tif->close;
}


my $path = 't/original.tif';
#my $path = 't/noisy.tif';
#my $path = 't/diffuse.tif';
#my $path = 't/multi.tif';
read_tif($path);


exit 0;
