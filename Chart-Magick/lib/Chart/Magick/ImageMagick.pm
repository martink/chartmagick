package Chart::Magick::ImageMagick;

use strict;
use warnings;

use Math::Trig;
use Text::Wrap;

use base qw{ Image::Magick };

=head2 NAME

Chart::Magick::ImageMagick

=head2 DESCRIPTION

Extends Image::Magick to add a number of methods that are regularly used within Chart::Magick.

=head2 SYNOPSIS

my $im = Chart::Magick::ImageMagick->new( size => '100x100' );
$im->Read('xc:white');


#-------------------------------------------------------------------

=head2 wrapText ( properties )

Takes the same properties as text does, and returns the text property wrapped so that it fits within the amount of
pixels given by the wrapWidth property.

Note that, for now, the algorithm is very naive in that it assumes all characters to have equal width so in some
cases the rendered text  might be either less wide than possible or wider than requested. With most readable
strings you should be fairly safe, though.

=head3 properties

See the text method. However, the desired width is passed by means of the wrapWidth property.

=cut

sub wrapText {
    my $self        = shift;
    my %properties  = @_;

    my $maxWidth    = $properties{ wrapWidth    };
    my $text        = $properties{ text         }; 
    my $textWidth   = [ $self->QueryFontMetrics( %properties ) ]->[4];
 
    if ( $textWidth > $maxWidth ) {
        # This is not guaranteed to work in every case, but it'll do for now.

        local $Text::Wrap::columns = int( $maxWidth / $textWidth * length $text );
        $text = join "\n", wrap( '', '', $text );
    }

    return $text;
}


#-------------------------------------------------------------------

=head2 text ( properties )

Extend the imagemagick Annotate method so alignment can be controlled better.

=head3 properties

A hash containing the imagemagick Annotate properties of your choice.
Additionally you can specify:

	alignHorizontal : The horizontal alignment for the text. Valid values
		are: 'left', 'center' and 'right'. Defaults to 'left'.
	alignVertical : The vertical alignment for the text. Valid values are:
		'top', 'center' and 'bottom'. Defaults to 'top'.

You can use the align property to set the text justification.

=cut

sub text {
	my $self    = shift;
	my %prop    = @_;

    # Don't bother to draw an empty string...
    return unless length $prop{ text };

    # Wrap text if necessary
    $prop{ text } = $self->wrapText( %prop ) if $prop{ wrapWidth };

    # Find width and height of resulting text block
    my ( $ascender, $width, $height ) = ( $self->QueryMultilineFontMetrics( %prop ) )[ 2, 4, 5 ];

	# Process horizontal alignment
    my $anchorX  =
          !defined $prop{ halign }      ? 0
        : $prop{ halign } eq 'center'   ? $width / 2
        : $prop{ halign } eq 'right'    ? $width
        :                                 0;

    # Using the align properties will cause IM to shift its anchor point. We'll have to compensate for that...
    $anchorX     -=
          !defined $prop{ align }       ? 0
        : $prop{ align }  eq 'Center'   ? $width / 2
        : $prop{ align }  eq 'Right'    ? $width
        :                                 0;


    # IM aparently always anchors at the baseline of the first line of a text block, let's take that into account.
    my $anchorY =
          !defined $prop{ valign }      ? $ascender
        : $prop{ valign } eq 'center'   ? $ascender - $height / 2
        : $prop{ valign } eq 'bottom'   ? $ascender - $height
        :                                 $ascender;

    # Convert the rotation angle to radians
    my $rotation = $prop{ rotate } ? $prop{ rotate } / 180 * pi : 0 ;

    # Calc the the angle between the IM anchor and our desired anchor
    my $r       = sqrt( $anchorX ** 2  + $anchorY ** 2 );
    my $theta   = atan2( -$anchorY , $anchorX ); 

    # And from that angle we can translate the coordinates of the text block so that it will be alligned the way we
    # want it to.
    $prop{ x } -= $r * cos( $theta + $rotation );
    $prop{ y } -= $r * sin( $theta + $rotation );

    # Prevent Image::Magick from complaining about unrecognized options.
    delete @prop{ qw( halign valign wrapWidth ) };

    $self->Annotate(
        #Leave align => 'Left' here as a default or all text will be overcompensated.
        align       => 'Left',
        %prop,
        gravity     => 'Center', #'NorthWest',
        antialias   => 'true',
	);

    return;
}

sub shade {
    my $self    = shift;
    my $opacity = shift || 100;
    my $sigma   = shift || 3;

    my $shadow = $self->Clone;
    $shadow->set( background    => 'black' );
#    $shadow->set( background    => 'white' );
    $shadow->Shadow(
        #geometry    => '60x3+10+10',
        opacity     => $opacity,
        sigma       => $sigma,
        x           => 100,
        y           => 100,
    );
    $shadow->Composite(
        image       => $self,
#        image       => $self->Fx( expression => '(a > 0.25) ? 1.0 : a', channel => 'alpha' ),
#        compose     => 'DstIn',
        compose     => 'DstOut',
    );

    $self->Composite(
        image       => $shadow,
#        compose     => 'Over',
#        compose     => 'Min',
#       compose     => 'Multiply',
#        compose     => 'DstIn',
#        compose     => 'In',
    );
}

1;

