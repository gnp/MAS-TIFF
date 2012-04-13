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
use MAS::TIFF::Tag;
use MAS::TIFF::IFD;

# http://www.fileformat.info/format/tiff/egff.htm
my %compression = (
      1 => 'Uncompressed', # baseline
      2 => 'CCITT 1D', # baseline
      3 => 'CCITT Group 3',
      4 => 'CCITT Group 4',
      5 => 'LZW',
      6 => 'JPEG (Old)',
      7 => 'JPEG (Technote2)',
  32771 => 'CCITT RLEW', # http://www.awaresystems.be/imaging/tiff/tifftags/compression.html
  32773 => 'Packbits', # baseline
);

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

# http://www.fileformat.info/format/tiff/egff.htm
my %tags = (
    254 => 'NewSubFileType',
    255 => 'SubFileType',
    256 => 'ImageWidth',
    257 => 'ImageLength', # aka ImageHeight
    258 => 'BitsPerSample',
    259 => 'Compression',
    262 => 'PhotometricInterpretation',
    263 => 'Thresholding',
    264 => 'CellWidth',
    265 => 'CellLength',
    266 => 'FillOrder',
    269 => 'DocumentName',
    270 => 'ImageDescription',
    271 => 'Make',
    272 => 'Model',
    273 => 'StripOffsets',
    274 => 'Orientation',
    277 => 'SamplesPerPixel',
    278 => 'RowsPerStrip',
    279 => 'StripByteCounts',
    280 => 'MinSampleValue',
    281 => 'MaxSampleValue',
    282 => 'XResolution',
    283 => 'YResolution',
    284 => 'PlanarConfiguration',
    285 => 'PageName',
    286 => 'XPosition',
    287 => 'YPosition',
    288 => 'FreeOffsets',
    289 => 'FreeByteCounts',
    290 => 'GrayResponseUnit',
    291 => 'GrayResponseCurve',
    292 => 'T4Options', # Before TIFF 6.0, was called Group3Options
    293 => 'T6Options', # Before TIFF 6.0, was called Group3Options
    296 => 'ResolutionUnit',
    297 => 'PageNumber',
    300 => 'ColorResponseUnit',
    301 => 'TransferFunction', # Before TIFF 6.0, was called ColorResponseCurve
    305 => 'Software',
    306 => 'DateTime',
    315 => 'Artist',
    316 => 'HostComputer',
    317 => 'Predictor',
    318 => 'WhitePoint',
    319 => 'PrimaryChromaticities',
    320 => 'ColorMap',
    321 => 'HalftoneHints',
    322 => 'TileWidth',
    323 => 'TileLength',
    324 => 'TileOffsets',
    325 => 'TileByteCounts',

    # TIFF Class F, not TIFF 6.0
    326 => 'BadFaxLines',
    327 => 'CleanFaxData',
    328 => 'ConsecutiveBadFaxLines',

    332 => 'InkSet',
    333 => 'InkNames',
    334 => 'NumberOfInks',
    336 => 'DotRange',
    337 => 'TargetPrinter',
    338 => 'ExtraSamples',
    339 => 'SampleFormat',
    340 => 'SMinSampleValue',
    341 => 'SMaxSampleValue',
    342 => 'TransferRange',
    512 => 'JPEGProc',
    513 => 'JPEGInterchangeFormat',
    514 => 'JPEGInterchangeFormatLength',
    515 => 'JPEGRestartInterval',
    517 => 'JPEGLosslessPredictors',
    518 => 'JPEGPointTransforms',
    519 => 'JPEGQTables',
    520 => 'JPEGDCTTables',
    521 => 'JPEGACTTables',
    529 => 'YCbCrCoefficiets',
    530 => 'YCbCrSubSampling',
    531 => 'YCbCrPositioning',
    532 => 'ReferenceBlackAndWhite',
    700 => 'XMP', # http://www.awaresystems.be/imaging/tiff/tifftags/extension.html
  33432 => 'Copyright',
  34377 => 'Photoshop Image Resource Blocks', # http://www.digitalpreservation.gov/formats/content/tiff_tags.shtml
  34665 => 'Exif IFD', # http://www.digitalpreservation.gov/formats/content/tiff_tags.shtml
);

# http://www.fileformat.info/format/tiff/egff.htm
my %types = (
   1 => 'BYTE',
   2 => 'ASCII',
   3 => 'SHORT',
   4 => 'LONG',
   5 => 'RATIONAL',

   # TIFF 6.0
   6 => 'SBYTE',
   7 => 'UNDEFINE',
   8 => 'SSHORT',
   9 => 'SLONG',
  10 => 'SRATIONAL',
  11 => 'FLOAT',
  12 => 'DOUBLE',
);

sub read_data_type {
  my $io = shift;

  my $data_type = $io->read_word;

  my $t = $types{$data_type};

  die "Unrecognized data type: $data_type" unless defined $t;

  return bless { 
    ID   => $data_type,
    NAME => $t,
  }, 'MAS::TIFF::DataType';
}

sub read_tag {
  my $io = shift;

  my $tag_id = $io->read_word;
  my $tag_name = $tags{$tag_id};

  my $data_type = read_data_type($io);
  my $data_count = $io->read_dword;
  my $data_offset = $io->read_dword;

  return bless {
    ID     => $tag_id,
    NAME   => $tag_name,
    TYPE   => $data_type,
    COUNT  => $data_count,
    OFFSET => $data_offset,
  }, 'MAS::TIFF::Tag';
}

sub read_ifd {
  my ($io, $absolute_offset) = @_;

  printf("  IFD: At offset %d\n", $absolute_offset);

  my $num_dir_entries = $io->read_word($absolute_offset);

  my %tags = ( );

  for (my $i = 0; $i < $num_dir_entries; ++$i) {
    my $tag = read_tag($io);
      
    $tags{$tag->id} = $tag;

    printf("    TAG: %d (%s), %s, %d, %d\n", $tag->id, $tag->name,
      $tag->type->name, $tag->count, $tag->offset);
  }

  $absolute_offset = $io->read_dword;

  my $ifd = bless {
    IO => $io,
    OFFSET => $absolute_offset,
    TAGS => { %tags },
    NEXT_IFD_OFFSET => $absolute_offset,
  }, 'MAS::TIFF::IFD';

  return $ifd;
}

sub read_header {
  my $fh = shift;

  my $buf;
  my $n = $fh->read($buf, 4);

  die "Error reading file: $!" unless defined $n;
  die "Could not read 4 bytes from file!" unless $n == 4;

  my $byte_order;

  if ($buf eq "MM\0\x2a") {
    print "TIF: Motorola byte-order\n";
    $byte_order = 'M';
  }
  elsif ($buf eq "II\x2a\0") {
    print "TIF: Intel byte-order\n";
    $byte_order = 'I';
  }
  else {
    printf "Not a TIFF file. Header: '%s', version %x %x\n", substr($buf, 0, 2), ord substr($buf, 2, 1), ord substr($buf, 3, 1);
    exit -1;
  }

  my $io = bless {
    FH => $fh,
    BYTE_ORDER => $byte_order,
  }, 'MAS::TIFF::IO';

  my $absolute_ifd_offset = $io->read_dword;

  my @ifds = ( );
  while ($absolute_ifd_offset != 0) {
    my $ifd = read_ifd($io, $absolute_ifd_offset);

    push @ifds, $ifd;

    printf("    Size: %d x %d\n", $ifd->image_width, $ifd->image_length);
    printf("    Bits per sample: %d\n", $ifd->bits_per_sample);
    printf("    Samples per pixel: %d\n", $ifd->samples_per_pixel);
    printf("    Is Image: %d\n", $ifd->is_image);
    printf("    Is Reduced Image: %d\n", $ifd->is_reduced_image);
    printf("    Is Page: %d\n", $ifd->is_page);
    printf("    Is Mask: %d\n", $ifd->is_mask);
    printf("    Resolution: %s x %s PIXELS / %s\n", $ifd->x_resolution->to_string, $ifd->y_resolution->to_string, $ifd->resolution_unit);
    printf("    Software: '%s'\n", $ifd->software);
    printf("    Datetime: '%s'\n", $ifd->datetime);

    $absolute_ifd_offset = $ifd->next_ifd_offset();
  }

  my $tif = bless {
    IO => $io,
    IFDS => [ @ifds ],
  }, 'MAS::TIFF::File';

  return $tif;
}

sub read_tif {
  my $path = shift;
  my $fh = FileHandle->new($path, 'r');

  die 'Could not open' unless defined $fh;

  binmode($fh);

  my $tif = read_header($fh);

  undef $fh; # automatically closes the file
}


my $path = 't/original.tif';
#my $path = 't/noisy.tif';
#my $path = 't/diffuse.tif';
#my $path = 't/multi.tif';
read_tif($path);


exit 0;
