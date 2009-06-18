#!perl -T

use Test::More tests => 12;

BEGIN {
    use_ok( 'Chart::Magick' );
    use_ok( 'Chart::Magick::Axis' );
    use_ok( 'Chart::Magick::Axis::Lin' );
    use_ok( 'Chart::Magick::Axis::LinLog' );
    use_ok( 'Chart::Magick::Chart' );
    use_ok( 'Chart::Magick::Chart::Bar' );
    use_ok( 'Chart::Magick::Chart::Line' );
    use_ok( 'Chart::Magick::Chart::Pie' );
    use_ok( 'Chart::Magick::Color' );
    use_ok( 'Chart::Magick::Data' );
    use_ok( 'Chart::Magick::Marker' );
    use_ok( 'Chart::Magick::Palette' );
}

diag( "Testing Chart::Magick $Chart::Magick::VERSION, Perl $], $^X" );