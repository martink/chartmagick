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
    => where    { defined Image::Magick->QueryColor( $_ ) }
    => message  { "Image::Magick does not recognize the value '$_' as a valid color" };
 
type 'MagickFont'
    => where    { defined $_ && ( -e $_ || -e Image::Magick->QueryFont( $_ ) ) }
    => message  { 
          "The font '$_' does not exist on your file system. If you passed only a font name and not a "
        . "path it is likely that your fonts.xml file is corrupt. "
    };

