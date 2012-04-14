use strict;
use warnings;

package MAS::TIFF::File;

sub new {
  my $class = shift;
  my $path = shift;

  my $io = MAS::TIFF::IO->new($path);
  
  my $absolute_ifd_offset = $io->read_dword;

  my @ifds = ( );
  while ($absolute_ifd_offset != 0) {
    my $ifd = MAS::TIFF::IFD->new($io, $absolute_ifd_offset);

    print "REF: " . ref($ifd) . "\n";
    
    push @ifds, $ifd;

    $absolute_ifd_offset = $ifd->next_ifd_offset();
  }

  my $self = bless {
    PATH => $path,
    IO => $io,
    IFDS => [ @ifds ],
  }, $class;
  
  return $self;
}

sub path { return shift->{PATH} }
sub io { return shift->{IO} }
sub ifds { return @{shift->{IFDS}} }

sub close {
  my $self = shift;
  $self->io->close;
  delete $self->{IO};
}

sub dump {
  my $self = shift;
  
  if ($self->io->byte_order eq 'M') {
      print "TIF: Motorola byte-order\n";
  }
  elsif ($self->io->byte_order eq 'I') {
    print "TIF: Intel byte-order\n";
  }
  else {
    die "Unexpected byte order '" . $self->io->byte_order . "'!";
  }

  foreach my $ifd ($self->ifds) {
    printf("  IFD: At offset %d\n", $ifd->offset);
    
    foreach my $field ($ifd->fields) {
      printf("    FIELD: TAG %d (%s), TYPE %s, COUNT %d, V/O 0x%04x\n", $field->id, $field->name,
        $field->type->name, $field->count, $field->offset);
    }
    
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
  }
}

1;
