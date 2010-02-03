use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Chart::Magick',
    license             => 'perl',
    dist_author         => 'Martin Kamerbeek <martin@oqapi.nl>',
    dist_version_from   => 'lib/Chart/Magick.pm',
    requires            => {
        'Image::Magick'     => 0,
        'Class::InsideOut'  => '1.09',
    },
    build_requires      => {
        'Test::More'        => 0,
        'Test::Warn'        => 0,
        'Test::NoWarnings'  => 0,
    },
    add_to_cleanup      => [ 'Chart-Magick-*' ],
    create_makefile_pl  => 'traditional',
);

$builder->create_build_script();
