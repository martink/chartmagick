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

sub SYMBOL_BLOCK {
    return 0b0001;
}

sub SYMBOL_LINE {
    return 0b0010;
}

sub SYMBOL_MARKER {
    return 0b0100;
}

sub addItem {
    my $self    = shift;
    my $symbol  = shift;
    my $label   = shift;
    my $color   = shift;
    my $marker  = shift;

    push @{ $items{ id $self } }, {
        symbol  => $symbol,
        label   => $label,
        color   => $color,
        marker  => $marker,
    };
}

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

sub definition {
    my $self = shift;

    my %definition = (
        position        => 'top right',
        orientation     => 'auto',
        overlapChart    => 0,
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

    if ( $symbol & SYMBOL_BLOCK ) {
        $self->im->Draw(
            primitive   => 'rectangle',
            points      => "$x1,$y1 $x2,$y2",
            fill        => $item->{ color }->getFillColor,
            stroke      => $item->{ color }->getStrokeColor,
        );
    }

    if ( $symbol & SYMBOL_LINE ) {
        $self->im->Draw(
            primitive   => 'line',
            points      => "$x,$y $x2,$y",
            stroke      => $item->{ color }->getStrokeColor,
        );
    }

    if ( $symbol & SYMBOL_MARKER && $item->{ marker } ) {
        $item->{ marker }->draw( ($x2 + $x1) / 2, $y );
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

    my $maxLabelWidth  = max map { $_->[0] || '0' } @labelDimensions;
    my $maxLabelHeight = max map { $_->[1] || '0' } @labelDimensions;

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


