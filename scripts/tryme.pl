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

# http://www.awaresystems.be/imaging/tiff/tifftags/photometricinterpretation.html
my %photometric_interpretation = (
      0 => 'MinIsWhite', # WhiteIsZero
      1 => 'MinIsBlack', # BlackIsZero
      2 => 'RGB',
      3 => 'Palette', # RGB Palette
      4 => 'Mask', # Transparency Mask
      5 => 'Separated', # CMYK
      6 => 'YCbCr',
      8 => 'CIELab',
      9 => 'ICCLab',
     10 => 'ITULab',
  32844 => 'LogL', # Pixar
  32845 => 'LogLuv', # Pixar
);

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
