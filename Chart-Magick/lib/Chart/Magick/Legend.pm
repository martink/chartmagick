package Chart::Magick::Legend;

use strict;
use warnings;
use Moose;

use Carp;
use List::Util qw{ max };
use Moose::Util::TypeConstraints;
use Chart::Magick::Types;

use Data::Dumper;

has items => (
    is          => 'rw',
    isa         => 'ArrayRef',
    default     => sub { [] },
);

has precalc => (
    is          => 'rw',
    isa         => 'HashRef',
    default     => sub { {} },
);

has axis => (
    is          => 'rw',
    isa         => 'Chart::Magick::Axis',
    required    => 1,
);

#--------------------------------------------------------------------

=head1 PRPOERTIES

The following properties are settable:

=over 4

=item position

String defining the location of the legend. This string consists of two words identifying horizontal and vertical
position, and are separated by a space. 

Available horizontal locations are 'left', 'center', and 'right'. Available vertical locations are 'top', 'middle'
and 'bottom'.

Defaults to 'top right'.

=item orientation

Determines whether the legend should be drawn horizontally or vertically. Options are 'horizontal', 'vertical' and
'auto'. If set to auto the orientation will be automatically determined as a function of location.

Defaults to 'auto'.

=item drawBorder

If set to a true value, a border will be drawn around the legend.

Defaults to 1.

=item borderColor

The color the border should be drawn in. Can be any format accepted by imagemagick.

Defaults to 'black'.

=item backgroundColor

The color of the legend's background. Can be any format accepted by imagemagick. For a transparent background, set
to 'none'.

Defaults to 'white'.

=item margin

The number of pixels of emptyness the legend should be surrounded with.

Defaults to 10.

=item padding

The number of pixels the contents of the legend should be at least away from the legend border.

Defaults to 10.

=item spacing

The number of pixels that should be between each legend item.

Defaults to 10.

=item labelSpacing

The number of pixels between symbol and text label.

Defaults to 5.

=item legendFont

The font to render the text labels of the legend items.

Defaults to the labelFont set by the Axis object.

=item legendFontSize

The pointsize the legend item text labels are rendered in.

=item legendColor

The color of the item text labels.

=item symbolWidth

The width of the symbols in pixels.

=item symbolHeight

The height of the symbols in pixels.

=back

=cut 

has position => (
	is		=> 'rw',
    isa     => 'LegendPosition',
	default => 'top right',
);
has orientation => (
	is		=> 'rw',
    isa     => enum([ qw{ horizontal vertical auto } ]),
	default => 'auto',
);
has drawBorder => (
	is		=> 'rw',
    isa     => 'Bool',
	default => 1,
);
has backgroundColor => (
	is		=> 'rw',
    isa     => 'MagickColor',
	default => 'white',
);
has borderColor => (
	is		=> 'rw',
    isa     => 'MagickColor',
	default => 'black',
);
has margin => (
	is		=> 'rw',
	default => 10,
);
has padding => (
	is		=> 'rw',
	default => 10,
);
has spacing => (
	is		=> 'rw',
	default => 10,
);
has labelSpacing => (
	is		=> 'rw',
	default => 5,
);
has legendFont => (
	is		=> 'rw',
    isa     => 'MagickFont',
    lazy    => 1,
	default => sub { $_[0]->axis->labelFont },
);
has legendFontSize => (
	is		=> 'rw',
    lazy    => 1,
	default => sub { $_[0]->axis->labelFontSize },
);
has legendColor => (
	is		=> 'rw',
    isa     => 'MagickColor',
    lazy    => 1,
	default => sub { $_[0]->axis->labelColor },
);
has symbolWidth => (
	is		=> 'rw',
	default => 20,
);
has symbolHeight => (
	is		=> 'rw',
	default => 10,
);




#--------------------------------------------------------------------

=head1 Symbol definitions

Each item in the legend has a symbol that corresponds to its representation in the chart. Eg. a line of a certain
color with a marker.

Each symbol is composed of different components and symbol definitions describe which components to use within a
symbol. Such a definition is a hashref containing one or more of the following keys and values:

=over 4

=item block

Adds a colored rectangle to the symbol. This is mainly used for charts that consist of areas rather than lines or
points, such as bar charts. The value must be an instanciated Chart::Magick::Color object.

=item line 

Adds a line to the symbol. Used in eg. line charts. Value must be an instanciated Chart::Magick::Color object.

=item marker

Adds a marker to the symbol. Value must be an instanciated Chart::Magick::Marker object.

=back

=head3 Examples

A legend item with only a line has the following definition

    {
        line    => $color,
    }

whereas a line with markers is defined as

    {
        line    => $color,
        marker  => $marker,
    }

The variables $color and $marker are instanciated Chart::Magick::Color and ::Marker objects respectively.

=head1 Methods

The following methods are available from this class:

=cut

#--------------------------------------------------------------------

=head2 addItem ( symbolType, label, color, marker )

Adds an item to the legend.

=head3 label

The text label of this item.

=head3 symbol

The symbol definition for this item. See the Symbol definitions section above.

=cut

sub addItem {
    my $self    = shift;
    my $label   = shift;
    my $symbol  = shift;

#    push @{ $items{ id $self } }, {
    push @{ $self->items }, {
        symbol  => $symbol,
        label   => $label,
    };
}

#--------------------------------------------------------------------

=head2 getRequiredMargins ( );

Returns an array containing the required margins that should be set in order for the legend not to overlap
anything. The returned margins are based on the location of the legend and its orientatation.

The array that is returned holds the required margins in the following order:

    ( left, right, top, bottom )

=cut

sub getRequiredMargins {
    my $self    = shift;

    my @margins = ( 0, 0, 0, 0 );

    return @margins unless @{ $self->items };

    my $pos     = $self->position;
    my $width   = $self->precalc->{ width   };
    my $height  = $self->precalc->{ height  };

    if ( $pos =~ m{ left }ix && !$self->isHorizontal ) {
        $margins[0] = $width;
    }

    if ( $pos =~ m{ right }ix && !$self->isHorizontal ) {
        $margins[1] = $width;
    }

    if ( $pos =~ m{ top }ix && $self->isHorizontal ) {
        $margins[2] = $height;
    }

    if ( $pos =~ m{ bottom }ix && $self->isHorizontal ) {
        $margins[3] = $height;
    }

    return @margins;
}


#--------------------------------------------------------------------

=head2 getAnchor

Returns the x,y coordinate of the legend anchor.

=cut

sub getAnchor {
    my $self = shift;

    my $axis    = $self->axis;
    my $pos     = $self->position;

    my $x =
          $pos =~ m{ left   }ix     ? 0
        : $pos =~ m{ center }ix     ? ( $axis->width - $self->precalc->{ width } ) / 2
        : $pos =~ m{ right  }ix     ? ( $axis->width - $self->precalc->{ width } )
        :                             ( $axis->width - $self->precalc->{ width } )
        ;


    my $y = 
          $pos =~ m{ top    }ix     ? 0
        : $pos =~ m{ middle }ix     ? ( $axis->height - $self->precalc->{ height } ) / 2
        : $pos =~ m{ bottom }ix     ? ( $axis->height - $self->precalc->{ height } )
        :                             0
        ;

    return ( int $x, int $y );
}

#--------------------------------------------------------------------

=head2 draw ( )

Draws the legend onto the axis canvas.

=cut

sub draw {
    my $self = shift;

    return unless scalar @{ $self->items };

    $self->preprocess;

    my $margin      = $self->margin;
    my $width   = $self->precalc->{ width }  - 2 * $margin;
    my $height  = $self->precalc->{ height } - 2 * $margin;

    # Get xy coord of left top corner of legend block and add the margin width.
    my ( $x1,$y1 )  = map { $_ + $margin } $self->getAnchor;

    my $x2      = $x1 + $width;
    my $y2      = $y1 + $height;

    # Bounding box
    $self->im->Draw(
        primitive   => 'Rectangle',
        points      => "$x1,$y1 $x2,$y2",
        strokeWidth => 1,
        fill        => $self->backgroundColor,
        stroke      => $self->borderColor,
    );

    # Calc  offset of first item
    $x1 += $self->padding;
    $y1 += $self->padding + $self->precalc->{ itemHeight } / 2;

    foreach my $item ( @{ $self->items } ) {
        $self->drawSymbol( $x1, $y1, $item->{ symbol } );

        $self->im->text( 
            text        => $item->{ label },
            x           => $x1 + $self->symbolWidth + $self->labelSpacing,
            y           => $y1,
            halign      => 'left',
            valign      => 'center',
            align       => 'Left',
            font        => $self->legendFont,
            pointsize   => $self->legendFontSize,
            color       => $self->legendColor,
        );

        if ( $self->isHorizontal ) {
            $x1 += $self->precalc->{ itemWidth } + $self->spacing;
        }
        else {
            $y1 += $self->precalc->{ itemHeight } + $self->spacing;
        }
    }

}

#--------------------------------------------------------------------

=head2 drawSymbol ( x, y, symbolDef )

Draws the passed symbl at the given coordinates.

=head3 x

The x coordinate of the symbol on the canvas.

=head3 y

The y coordinate of the symbol on the canvas.

=head3 symbolDef

The symbol definition of the symbol as defined in the Symbol definitions section above.

=cut

sub drawSymbol {
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;
    my $symbol    = shift;

    my $x1      = $x;
    my $y1      = int( $y - $self->symbolHeight / 2 );
    my $x2      = $x + $self->symbolWidth;
    my $y2      = int( $y + $self->symbolHeight / 2 );

    if ( exists $symbol->{ block } && $symbol->{ block } ) {
        $self->im->Draw(
            primitive   => 'rectangle',
            points      => "$x1,$y1 $x2,$y2",
            fill        => $symbol->{ block }->getFillColor,
            stroke      => $symbol->{ block }->getStrokeColor,
        );
    }

    if ( exists $symbol->{ line } && $symbol->{ line } ) {
        $self->im->Draw(
            primitive   => 'line',
            points      => "$x,$y $x2,$y",
            stroke      => $symbol->{ line }->getStrokeColor,
        );
    }

    if ( exists $symbol->{ marker } && $symbol->{ marker } ) {
        $symbol->{ marker }->draw( ($x2 + $x1) / 2, $y, $self->im );
    }
    
}

#--------------------------------------------------------------------

=head2 isHorizontal ( )

Return a true value if the legend is being drawn horizontally. Returns false for vertical legends.

=cut

sub isHorizontal {
    my $self = shift;

    return 1 if $self->orientation eq 'horizontal';
    return 0 if $self->orientation eq 'vertical';

    return $self->position =~ m{ center }ix;
}

#--------------------------------------------------------------------

=head2 preprocess ( )

Precalculates and caches some parameters required for drawing the legend.

=cut

sub preprocess {
    my $self    = shift;

    my @labelDimensions = map { [ 
        ( $self->im->QueryFontMetrics( 
            text        => $_->{ label },
            font        => $self->legendFont,
            pointsize   => $self->legendFontSize,
        ) )[ 4, 5 ]
    ] } @{ $self->items };

    my $maxLabelWidth  = max( map { $_->[0] } @labelDimensions ) || 0;
    my $maxLabelHeight = max( map { $_->[1] } @labelDimensions ) || 0;

    my $itemWidth   = $self->symbolWidth + $self->labelSpacing + $maxLabelWidth;
    my $itemHeight  = max $self->symbolHeight, $maxLabelHeight;

    my $spacing     = $self->spacing;
    my $margin      = $self->margin;
    my $padding     = $self->padding;
    my $width       
        = $self->isHorizontal
            ? scalar( @{ $self->items } ) * ( $itemWidth + $spacing ) - $spacing
            : $itemWidth
        ;
    my $height      
        = $self->isHorizontal
            ? $itemHeight
            : ( scalar( @{ $self->items } ) * ( $itemHeight + $spacing ) - $spacing )
        ;

    $self->precalc->{ itemWidth     } = $itemWidth;
    $self->precalc->{ itemHeight    } = $itemHeight;
    $self->precalc->{ width         } = $width  + 2 * ( $margin + $padding );
    $self->precalc->{ height        } = $height + 2 * ( $margin + $padding );

    return;
}

#--------------------------------------------------------------------

=head2 im ( )

Returns the Image::Magick object that the legend is being drawn onto.

=cut

sub im {
    my $self = shift;

    return $self->axis->im;
}

1;


