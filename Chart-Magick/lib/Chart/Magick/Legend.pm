package Chart::Magick::Legend;

use strict;
use warnings;

use Carp;
use List::Util qw{ max };
use Class::InsideOut qw{ :std };

use Data::Dumper;

use base qw{ Chart::Magick::Definition };

readonly items      => my %items;
readonly precalc    => my %precalc;
readonly axis       => my %axis;

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

    push @{ $items{ id $self } }, {
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

    my $pos     = $self->get('position');
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

=head2 definition ( )

The following properties are settable:

=over 4
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

sub definition {
    my $self = shift;

    my %definition = (
        position        => 'top right',
        orientation     => 'auto',
        drawBorder      => 1,
        backgroundColor => 'white',
        borderColor     => 'black',
        margin          => 10,
        padding         => 10,
        spacing         => 10,
        labelSpacing    => 5,
        legendFont      => sub { $_[0]->axis->get('labelFont') },
        legendFontSize  => sub { $_[0]->axis->get('labelFontSize') },
        legendColor     => sub { $_[0]->axis->get('labelColor') },
        symbolWidth     => 20,
        symbolHeight    => 10,
    );

    return { %definition };
}

sub getAnchor {
    my $self = shift;

    my $axis    = $self->axis;
    my $pos     = $self->get('position');

    my $x =
          $pos =~ m{ left   }ix     ? 0
        : $pos =~ m{ center }ix     ? ( $axis->get('width') - $self->precalc->{ width } ) / 2
        : $pos =~ m{ right  }ix     ? $axis->get('width') - $self->precalc->{ width }
        :                             $axis->get('width') - $self->precalc->{ width }
        ;


    my $y = 
          $pos =~ m{ top    }ix     ? 0
        : $pos =~ m{ middle }ix     ? ( $axis->get('height') - $self->precalc->{ height } ) / 2
        : $pos =~ m{ bottom }ix     ? $axis->get('height') - $self->precalc->{ height }
        :                             0
        ;

    return ( int $x, int $y );
}

sub draw {
    my $self = shift;

    return unless scalar @{ $self->items };

    $self->preprocess;

    my $margin      = $self->get('margin');
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
        fill        => $self->get('backgroundColor'),
        stroke      => $self->get('borderColor'),
    );

    # Calc  offset of first item
    $x1 += $self->get('padding');
    $y1 += $self->get('padding') + $self->precalc->{ itemHeight } / 2;

    foreach my $item ( @{ $self->items } ) {
        $self->drawSymbol( $x1, $y1, $item );

        $self->axis->text( 
            text        => $item->{ label },
            x           => $x1 + $self->get('symbolWidth') + $self->get('labelSpacing'),
            y           => $y1,
            halign      => 'left',
            valign      => 'center',
            align       => 'Left',
            font        => $self->get('legendFont'),
            pointsize   => $self->get('legendFontSize'),
            color       => $self->get('legendColor'),
        );

        if ( $self->isHorizontal ) {
            $x1 += $self->precalc->{ itemWidth } + $self->get('spacing');
        }
        else {
            $y1 += $self->precalc->{ itemHeight } + $self->get('spacing');
        }
    }

}

sub drawSymbol {
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;
    my $item    = shift;

    my $x1      = $x;
    my $y1      = int( $y - $self->get('symbolHeight') / 2 );
    my $x2      = $x + $self->get('symbolWidth');
    my $y2      = int( $y + $self->get('symbolHeight') / 2 );

    my $symbol  = $item->{ symbol };

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

    if ( exists $symbol->{ marker } && $symbol->{ marker } ) { #) & SYMBOL_MARKER && $item->{ marker } ) {
        $symbol->{ marker }->draw( ($x2 + $x1) / 2, $y );
    }
    
}

sub isHorizontal {
    my $self = shift;

    return 1 if $self->get('orientation') eq 'horizontal';
    return 0 if $self->get('orientation') eq 'vertical';

    return $self->get('position') =~ m{ center }ix;
}

sub new {
    my $class   = shift;
    my $axis    = shift || croak "No axis passed";
    my $self    = bless {}, $class;

    register $self;

    my $id  = id $self;
    $items{ $id     } = [];
    $precalc{ $id   } = {};
    $axis{ $id      } = $axis;

    $self->initializeProperties;
    return $self;
}

sub preprocess {
    my $self    = shift;

    my @labelDimensions = map { [ 
        ( $self->im->QueryFontMetrics( 
            text        => $_->{ label },
            font        => $self->get('legendFont'),
            pointsize   => $self->get('legendFontSize'),
        ) )[ 4, 5 ]
    ] } @{ $self->items };

    my $maxLabelWidth  = max( map { $_->[0] } @labelDimensions ) || 0;
    my $maxLabelHeight = max( map { $_->[1] } @labelDimensions ) || 0;

    my $itemWidth   = $self->get('symbolWidth') + $self->get('labelSpacing') + $maxLabelWidth;
    my $itemHeight  = max $self->get('symbolHeight'), $maxLabelHeight;

    my $spacing     = $self->get('spacing');
    my $margin      = $self->get('margin');
    my $padding     = $self->get('padding');
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

sub im {
    my $self = shift;

    return $self->axis->im;
}

1;


