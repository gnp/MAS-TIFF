use strict;
use warnings;

package MAS::TIFF::IFD;

use constant {
  TAG_NEW_SUBFILE_TYPE => 254,
  TAG_SUBFILE_TYPE     => 255,
  TAG_IMAGE_WIDTH      => 256,
  TAG_IMAGE_LENGTH     => 257,

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

sub io { return shift->{IO} }
sub offset { return shift->{OFFSET} }
sub tags { return shift->{TAGS} }
sub next_ifd_offset { return shift->{NEXT_IFD_OFFSET} }

sub tag {
  my $self = shift;
  my $tag_id = shift;

  return $self->{TAGS}{$tag_id};
}

sub image_width { return shift->tag(TAG_IMAGE_WIDTH)->offset }
sub image_length { return shift->tag(TAG_IMAGE_LENGTH)->offset }

sub is_image {
  my $self = shift;

  my $tag = $self->tag(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $tag) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($tag->offset & (FILE_TYPE_REDUCED_IMAGE | FILE_TYPE_PAGE | FILE_TYPE_MASK)) == 0;
  }
  else {
    $tag = $self->tag(TAG_SUBFILE_TYPE);

    if (defined $tag) {
      return $tag->offset == OLD_FILE_TYPE_IMAGE;
    }
    else {
      return 1;
    }
  }
}

sub is_reduced_image {
  my $self = shift;

  my $tag = $self->tag(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $tag) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($tag->offset & FILE_TYPE_REDUCED_IMAGE) != 0;
  }
  else {
    $tag = $self->tag(TAG_SUBFILE_TYPE);

    if (defined $tag) {
      return $tag->offset == OLD_FILE_TYPE_REDUCED_IMAGE;
    }
    else {
      return 0;
    }
  }
}

sub is_page {
  my $self = shift;

  my $tag = $self->tag(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $tag) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($tag->offset & FILE_TYPE_PAGE) != 0;
  }
  else {
    $tag = $self->tag(TAG_SUBFILE_TYPE);

    if (defined $tag) {
      return $tag->offset == OLD_FILE_TYPE_PAGE;
    }
    else {
      return 0;
    }
  }
}

sub is_mask {
  my $self = shift;

  my $tag = $self->tag(TAG_NEW_SUBFILE_TYPE);

  # First try TAG_NEW_SUBFILE_TYPE, else TAG_SUBFILE_TYPE
  if (defined $tag) {
    # If none of bits 0, 1 or 2 is set, this is a regular image
    return ($tag->offset & FILE_TYPE_MASK) != 0;
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

sub resolution_unit {
  my $self = shift;

  my $tag = $self->tag(TAG_RESOLUTION_UNIT);

  return $resolution_units{2} unless defined $tag;

  my $unit = $resolution_units{$tag->offset};

  die("Unrecognized resolution unit '" . $tag->offset . "'. Expected one of: " . join(', ', map { $_ = "'$_'" } sort keys %resolution_units)) unless defined $unit;

  return $unit;
}

sub datetime {
  my $self = shift;

  return $self->{DATETIME} if exists $self->{DATETIME};

  my $datetime = undef;

  my $tag = $self->tag(TAG_DATETIME);

  if (defined $tag) {
    $datetime = $self->io->read_ascii($tag->count, $tag->offset);
  }

  $self->{DATETIME} = $datetime;

  return $datetime;
}

sub software {
  my $self = shift;

  return $self->{SOFTWARE} if exists $self->{SOFTWARE};

  my $software = undef;

  my $tag = $self->tag(TAG_SOFTWARE);

  if (defined $tag) {
    $software = $self->io->read_ascii($tag->count, $tag->offset);
  }

  $self->{SOFTWARE} = $software;

  return $software;
}

sub x_resolution {
  my $self = shift;

  return $self->{X_RESOLUTION} if exists $self->{X_RESOLUTION};

  my $tag = $self->tag(TAG_X_RESOLUTION);

  return undef unless defined $tag;

  my $rat = $self->io->read_rational($tag->offset);

  $self->{X_RESOLUTION} = $rat;

  return $rat;
}

sub y_resolution {
  my $self = shift;

  return $self->{Y_RESOLUTION} if exists $self->{Y_RESOLUTION};

  my $tag = $self->tag(TAG_Y_RESOLUTION);

  return undef unless defined $tag;

  my $rat = $self->io->read_rational($tag->offset);

  $self->{Y_RESOLUTION} = $rat;

  return $rat;
}

1;
