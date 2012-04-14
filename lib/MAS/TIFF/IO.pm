use strict;
use warnings;

package MAS::TIFF::IO;

sub new {
  my $class = shift;
  my $path = shift;
  
  my $fh = FileHandle->new($path, 'r');

  die 'Could not open' unless defined $fh;

  binmode($fh);

  my $buf;
  my $n = $fh->read($buf, 4);

  die "Error reading file: $!" unless defined $n;
  die "Could not read 4 bytes from file!" unless $n == 4;

  my $byte_order;

  if ($buf eq "MM\0\x2a") {
    $byte_order = 'M';
  }
  elsif ($buf eq "II\x2a\0") {
    $byte_order = 'I';
  }
  else {
    die "Not a TIFF file. Header: '%s', version %x %x\n", substr($buf, 0, 2), ord substr($buf, 2, 1), ord substr($buf, 3, 1);
  }

  my $self = bless {
    FH => $fh,
    BYTE_ORDER => $byte_order,
  }, $class;
  
  return $self;
}

sub close {
  my $self = shift;
  
  my $fh = $self->fh;
  $fh->close;
  delete $self->{FH};
}

sub fh { return shift->{FH} }
sub byte_order { return shift->{BYTE_ORDER} }

sub read_word {
  my $self = shift;
  my $seek = shift;

  $self->fh->seek($seek, 0) if defined $seek;

  my $buf;

  my $n = $self->fh->read($buf, 2);
  die "Error reading file: $!" unless defined $n;
  die "Could not read 2 bytes from file!" unless $n == 2;

  my $result = 0;

  if ($self->byte_order eq 'M') {
    for (my $i = 0; $i < 2; ++$i) {
      $result *= 256;
      $result += ord substr($buf, $i, 1);
    }
  }
  else {
    for (my $i = 1; $i >= 0; --$i) {
      $result *= 256;
      $result += ord substr($buf, $i, 1);
    }
  }

  return $result;
}

sub read_dword {
  my $self = shift;
  my $seek = shift;

  $self->fh->seek($seek, 0) if defined $seek;

  my $buf;

  my $n = $self->fh->read($buf, 4);
  die "Error reading file: $!" unless defined $n;
  die "Could not read 4 bytes from file!" unless $n == 4;

  my $result = 0;

  if ($self->byte_order eq 'M') {
    for (my $i = 0; $i < 4; ++$i) {
      $result *= 256;
      $result += ord substr($buf, $i, 1);
    }
  }
  else {
    for (my $i = 3; $i >= 0; --$i) {
      $result *= 256;
      $result += ord substr($buf, $i, 1);
    }
  }

  return $result;
}

sub read_rational {
  my $self = shift;
  my $seek = shift;

  $self->fh->seek($seek, 0) if defined $seek;

  my $numerator = $self->read_dword;
  my $denominator = $self->read_dword;

  return bless [$numerator, $denominator], 'MAS::TIFF::Rational';
}

sub read_ascii {
  my $self = shift;
  my ($count, $seek) = @_;

  $self->fh->seek($seek, 0) if defined $seek;

  my $buf;

  my $n = $self->fh->read($buf, $count);
  die "Error reading file: $!" unless defined $n;
  die "Could not read $count bytes from file!" unless $n == $count;

  return unpack("Z*", $buf);
}

1;
