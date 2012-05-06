use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'MAS::TIFF',
  VERSION_FROM  => 'lib/MAS/TIFF/File.pm',
  AUTHOR        => 'Gregor N. Purdy, Sr. <gnp@acm.org>',
  MIN_PERL_VERSION => '5.8.0',
);
