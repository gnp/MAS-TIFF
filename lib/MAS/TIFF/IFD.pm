use strict;
use warnings;

package MAS::TIFF::IFD;

use MAS::TIFF::Field;
use MAS::TIFF::Compression::LZW;

use constant {
  TAG_NEW_SUBFILE_TYPE => 254,
  TAG_SUBFILE_TYPE     => 255,
  TAG_IMAGE_WIDTH      => 256,
  TAG_IMAGE_LENGTH     => 257,
  
  TAG_BITS_PER_SAMPLE   => 258,
  TAG_COMPRESSION       => 259,
  TAG_PHOTOMETRIC_INTERPRETATION => 262,
  TAG_STRIP_OFFSETS     => 273,
  TAG_SAMPLES_PER_PIXEL => 277,
  TAG_ROWS_PER_STRIP    => 278,
  TAG_STRIP_BYTE_COUNTS => 279,
  
  TAG_X_RESOLUTION     => 282,
  TAG_Y_RESOLUTION     => 283,
  TAG_RESOLUTION_UNIT  => 296,

  TAG_SOFTWARE         => 305,
  TAG_DATETIME         => 306,
};

use constant {
  FILE_TYPE_REDUCED_IMAGE => 1,
  FILE_TYPE_PAGE          => 2,
  FILE_TYPE_MASK          => 4,
};

use constant {
  OLD_FILE_TYPE_IMAGE         => 1,
  OLD_FILE_TYPE_REDUCED_IMAGE => 2,
  OLD_FILE_TYPE_PAGE          => 3,
};

sub new {
  my $class = shift;
  my ($io, $offset) = @_;
  
  my $num_dir_entries = $io->read_word($offset);

  my @field_ids = ( );
  my %fields = ( );

  for (my $i = 0; $i < $num_dir_entries; ++$i) {
    my $field = MAS::TIFF::Field->read_from_io($io);
    push @field_ids, $field->id;
    $fields{$field->id} = $field;
  }

  my $next_offset = $io->read_dword;

  my $self = bless {
    IO => $io,
    OFFSET => $offset,
    FIELD_IDS => [ @field_ids ],
    FIELDS => { %fields },
    NEXT_IFD_OFFSET => $next_offset,
  }, $class;
  
  return $self;
}

sub io { return shift->{IO} }
sub offset { return shift->{OFFSET} }

sub fields {
  my $self = shift;
  
  return map { $self->{FIELDS}{$_} } @{$self->{FIELD_IDS}};
}

sub next_ifd_offset { return shift->{NEXT_IFD_OFFSET} }

sub field {
  my $self = shift;
  my $tag_id = shift;

  return $self->{FIELDS}{$tag_id};
}

sub image_width { return shift->field(TAG_IMAGE_WIDTH)->value_at(0) }
sub image_length { return shift->field(TAG_IMAGE_LENGTH)->value_at(0) }

sub bits_per_sample {
  my $self = shift;
  
  my $spp = $self->samples_per_pixel;
  
  my $field = $self->field(TAG_BITS_PER_SAMPLE);
  
  if (not defined $field) {
    if ($spp == 1) {
      return 1; # OK to default to 1 if only expecting a single value
    }
    else {
      die "Cannot omit bits_per_sample tag when samples_per_pixel > 1!";
    }
  }
  
  if ($spp == 1) {
    return $field->value_at(0);
  }
  else {
    die "Not supported yet -- Need better tag reading code";
  }
}

sub samples_per_pixel {
  my $self = shift;
  
  my $field = $self->field(TAG_SAMPLES_PER_PIXEL);
  
  return 1 unless defined $field;
  
  return $field->value_at(0);
}

sub rows_per_strip {
  my $self = shift;
  
  my $field = $self->field(TAG_ROWS_PER_STRIP);
  
  return undef unless defined $field;
  
  return $field->value_at(0);
}

sub strip_offsets {
  my $self = shift;
  
  my $field = $self->field(TAG_STRIP_OFFSETS);
    
  return ( ) unless defined $field;
  
  return @{$field->all_values};
}

sub strip_byte_counts {
  my $self = shift;
  
  my $field = $self->field(TAG_STRIP_BYTE_COUNTS);
    
  return ( ) unless defined $field;
  
  return @{$field->all_values};
}

sub strip_count {
  my $self = shift;
  
  my $field = $self->field(TAG_STRIP_OFFSETS);
    
  return undef unless defined $field;

  return $field->count;
}

sub strip {
  my $self = shift;
  my $index = shift;
  
  die "Index must be defined" unless defined $index;
  
  if (exists $self->{STRIPS}[$index]) {
    return $self->{STRIPS}[$index];
  }
  
  my $size = ($self->strip_byte_counts)[$index];
  my $offset = ($self->strip_offsets)[$index];
  
  my $bytes = $self->io->read($size, $offset);
  
  if ($self->compression eq 'LZW') {
    $bytes = MAS::TIFF::Compression::LZW::decode($bytes);
  }
  
  $self->{STRIPS}[$index] = $bytes;
  
  return $bytes;
}

#
# With the strip, each row is stored in a contiguous byte sequence, with possibly some
# unused bits at the end.
#
# Returns zero for black, one for white.
#

sub pixel_at {
  use integer;
  
  my $self = shift;
  my ($x, $y) = @_;
  
  if ($self->samples_per_pixel != 1) {
    die "Sorry, only images with one sample per pixel are supported!";
  }
  
  if ($self->bits_per_sample != 1) {
    die "Sorry, only images with one bit per sample are supported!";
  }
  
  if (($x < 0) || ($x >= $self->image_width)) {
    die "x must be in range 0.." . ($self->image_width - 1) . "!";
  }
  
  if (($y < 0) || ($y >= $self->image_length)) {
    die "y must be in range 0.." . ($self->image_width - 1) . "!";
  }
  
  my $index = $y / $self->rows_per_strip;
  my $strip = $self->strip($index);

  my $row = $y % $self->rows_per_strip;
  
  my $bytes_per_row = $self->image_width / 8 + (($self->image_width % 8) != 0 ? 1 : 0);
  my $byte_index = ($row * $bytes_per_row) + ($x / 8);
  my $byte = ord substr($strip, $byte_index, 1);
  my $bit_index = 7 - ($x % 8);
  my $bit = ($byte >> $bit_index) & 0x01;
  my $row_offset =
  
  my $pi = $self->photometric_interpretation;
  
  if ($pi eq 'MinIsWhite') {
    return !$bit;
  }
  elsif ($pi eq 'MinIsBlack') {
    return $bit;
  }
  else {
    die "Sorry, only MinIsWhite and MinIsBlack are supported photometric interpretations!";
  }
}

sub is_image {
  my $self = shift;

  my $field = $self->field(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $field) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($field->value_at(0) & (FILE_TYPE_REDUCED_IMAGE | FILE_TYPE_PAGE | FILE_TYPE_MASK)) == 0;
  }
  else {
    $field = $self->field(TAG_SUBFILE_TYPE);

    if (defined $field) {
      return $field->value_at(0) == OLD_FILE_TYPE_IMAGE;
    }
    else {
      return 1;
    }
  }
}

sub is_reduced_image {
  my $self = shift;

  my $field = $self->field(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $field) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($field->value_at(0) & FILE_TYPE_REDUCED_IMAGE) != 0;
  }
  else {
    $field = $self->field(TAG_SUBFILE_TYPE);

    if (defined $field) {
      return $field->value_at(0) == OLD_FILE_TYPE_REDUCED_IMAGE;
    }
    else {
      return 0;
    }
  }
}

sub is_page {
  my $self = shift;

  my $field = $self->field(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $field) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($field->value_at(0) & FILE_TYPE_PAGE) != 0;
  }
  else {
    $field = $self->field(TAG_SUBFILE_TYPE);

    if (defined $field) {
      return $field->value_at(0) == OLD_FILE_TYPE_PAGE;
    }
    else {
      return 0;
    }
  }
}

sub is_mask {
  my $self = shift;

  my $field = $self->field(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $field) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($field->value_at(0) & FILE_TYPE_MASK) != 0;
  }
  else {
    return 0;
  }
}

my %resolution_units = (
  1 => 'NONE',
  2 => 'INCH',
  3 => 'CM',
);

my $default_resolution_units = 2;

sub resolution_unit {
  my $self = shift;

  my $field = $self->field(TAG_RESOLUTION_UNIT);

  unless (defined $field) {
    my $temp = $resolution_units{$default_resolution_units};
    
    return $temp;
  }

  my $unit = $resolution_units{$field->value_at(0)};

  die("Unrecognized resolution unit '" . $field->value_at(0) . "'. Expected one of: " . join(', ', map { $_ = "'$_'" } sort keys %resolution_units)) unless defined $unit;

  return $unit;
}

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

my $default_compression = 1;

sub compression {
  my $self = shift;

  my $field = $self->field(TAG_COMPRESSION);

  unless (defined $field) {
    my $temp = $compression{$default_compression};
    
    return $temp;
  }

  my $value = $compression{$field->value_at(0)};

  die("Unrecognized compression '" . $field->value_at(0) . "'. Expected one of: " . join(', ', map { $_ = "'$_'" } sort keys %compression)) unless defined $value;

  return $value;
}

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

sub photometric_interpretation {
  my $self = shift;
  
  if (exists $self->{PHOTOMETRIC_INTERPRETATION}) {
    return $self->{PHOTOMETRIC_INTERPRETATION};
  }

  my $field = $self->field(TAG_PHOTOMETRIC_INTERPRETATION);

  unless (defined $field) {
    $self->{PHOTOMETRIC_INTERPRETATION} = undef;
    return undef;
  }

  my $value = $photometric_interpretation{$field->value_at(0)};

  die("Unrecognized photometric interpretation '" . $field->value_at(0) . "'. Expected one of: " . join(', ', map { $_ = "'$_'" } sort keys %photometric_interpretation)) unless defined $value;

  $self->{PHOTOMETRIC_INTERPRETATION} = $value;
  
  return $value;
}

sub datetime {
  my $self = shift;

  return $self->{DATETIME} if exists $self->{DATETIME};

  my $datetime = undef;

  my $field = $self->field(TAG_DATETIME);

  if (defined $field) {
    $datetime = $field->value_at(0);
  }

  $self->{DATETIME} = $datetime;

  return $datetime;
}

sub software {
  my $self = shift;

  return $self->{SOFTWARE} if exists $self->{SOFTWARE};

  my $software = undef;

  my $field = $self->field(TAG_SOFTWARE);

  if (defined $field) {
    $software = $field->value_at(0);
  }

  $self->{SOFTWARE} = $software;

  return $software;
}

sub x_resolution {
  my $self = shift;

  return $self->{X_RESOLUTION} if exists $self->{X_RESOLUTION};

  my $field = $self->field(TAG_X_RESOLUTION);

  return undef unless defined $field;

  my $rat = $field->value_at(0);

  $self->{X_RESOLUTION} = $rat;

  return $rat;
}

sub y_resolution {
  my $self = shift;

  return $self->{Y_RESOLUTION} if exists $self->{Y_RESOLUTION};

  my $field = $self->field(TAG_Y_RESOLUTION);

  return undef unless defined $field;

  my $rat = $field->value_at(0);

  $self->{Y_RESOLUTION} = $rat;

  return $rat;
}

1;
