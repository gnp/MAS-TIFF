use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'MAS::TIFF',
    license             => 'perl',
    dist_author         => 'Gregor N. Purdy, Sr. <gnp@acm.org>',
    dist_version_from   => 'lib/MAS/TIFF/File.pm',
    dist_abstract => 'Pure Perl TIFF image metadata and samples reading',
    requires => {
      'perl' => '5.008000',
    },
    add_to_cleanup => ['MAS-TIFF-*.tar.gz'],
);

$builder->create_build_script();
