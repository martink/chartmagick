package Chart::Magick::Types;

use strict;
use warnings;
use Moose::Util::TypeConstraints;
#use MooseX::Types -declare => [qw( PositiveOrZeroInt MagickColor )];
use Image::Magick;

subtype 'PositiveOrZeroInt'
    => as       'Int',
    => where    { $_ >= 0 };

subtype 'MagickColor'
    => as       'Str',
#   => where    { $_ =~ m|^#[0-9a-f]{6}$|i || $_ =~ m{^[\w\d]+$} };
    => where    { defined Image::Magick->QueryColor( $_ ) };


