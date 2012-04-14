use strict;
use warnings;

package MAS::TIFF::Field;

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

sub new {
  my $class = shift;
  my $io = shift;
  
  my $tag_id = $io->read_word;
  my $tag_name = $tags{$tag_id};

  my $data_type = read_data_type($io);
  my $data_count = $io->read_dword;
  my $data_offset = $io->read_dword;
  
  my $self = bless {
    ID     => $tag_id,
    NAME   => $tag_name,
    TYPE   => $data_type,
    COUNT  => $data_count,
    OFFSET => $data_offset,
  }, $class;
  
  return $self;
}

sub id { return shift->{ID} }
sub name { return shift->{NAME} }
sub type { return shift->{TYPE} }
sub count { return shift->{COUNT} }
sub offset { return shift->{OFFSET} }

1;