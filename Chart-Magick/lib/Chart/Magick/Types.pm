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

sub _isProperPosition {
    my @pos = split /\s+/, shift;

    my @horiz   = grep { { left => 1, center => 1, right  => 1 }->{ $_ } } @pos;      
    my @vert    = grep { { top  => 1, middle => 1, bottom => 1 }->{ $_ } } @pos;

    return 
          @horiz > 1 || @vert > 1 || @pos > 2           ? 0
        : @pos == 2 && ( @horiz == 1 && @vert == 1 )    ? 1
        : @pos == 1 && ( @horiz == 1 || @vert == 1 )    ? 1
        :                                                 0
        ;
}
subtype 'LegendPosition'
    => as       'Str',
    => where    { _isProperPosition( $_ ) },
    => message  { 
          "The legend position must consist of either 'left', 'center' or 'right' for horizontal "
        . "postioning and 'top', 'middle', or 'bottom' for vertical positioning. "
    };
