package Chart::Magick::Chart::Bar;

use strict;
use List::Util qw{ sum reduce };

use base qw{ Chart::Magick::Chart };

=head1 NAME

Chart::Magick::Chart::Bar

=head1 DESCRIPTION

A bar graph Chart plugin for Chart::Magick.

=head1 METHODS

The following methods are available from this class:

=cut

#--------------------------------------------------------------------------

=head2 definition ( )

See Chart::Magick::Chart::definition for details.

The following properties can be set:

=over 4

=item drawMode

The way groups of bars are drawn. Valid values are:

=over 8

=item sideBySide

Default value. Draws bars next to each other.

=item cumulative

Draws bars on top of each other.

=back

=back

=cut

sub definition {
    my $self    = shift;
    my %options = %{ $self->SUPER::definition };

    my %overrides = (
        barWidth    => 20,
        barSpacing  => 5,
        drawMode    => 'sideBySide',
    );  

    return { %options, %overrides };
}

#--------------------------------------------------------------------------

=head2 drawBar ( color, width, length, coord, coordOffset, bottom )

Draw a bar onto the axis set in the object. All parameters should be passed in coordinates, not pixels.

=head3 color

The Chart::Magick::Color object for this specific bar.

=head3 width

The width of the bar.

=head3 length

The length (or height) of the bar.

=head3 coord

The coordinate of the center of the bar(group).

=head3 coordOffset

The displacement of the actual bar center wrt. the center of the bar group. Defaults to 0.

=head3 bottomOffset

The displacement of the actual bar bottom and the horizontal axis. Defaults to 0.

=cut

sub drawBar {
    my $self            = shift;

    my $color           = shift;
    my $width           = shift;
    my $length          = shift;
    my $coord           = shift;        # x-location of center of bar group
    my $coordOffset     = shift || 0;   # offset of bar center wrt. $coord 
    my $bottom          = shift || 0;   # y-location of bar bottom wrt. 0 axis

    my $axis    = $self->axis;

    my $left    = $coord - $width / 2 + $coordOffset;   # x-location of left bar edge
    my $right   = $left + $width;                       # x-location of right bar edge
    my $top     = $bottom + $length;

	$axis->im->Draw(
		primitive	=> 'Path',
		stroke		=> $color->getStrokeColor,
		fill		=> $color->getFillColor,
		points		=> 
			  " M " . $axis->toPx( [ $left  ], [ $bottom ] )
			. " L " . $axis->toPx( [ $left  ], [ $top    ] )
            . " L " . $axis->toPx( [ $right ], [ $top    ] )
			. " L " . $axis->toPx( [ $right ], [ $bottom ] )
            . " Z ",
	);
    
}

#--------------------------------------------------------------------------

=head2 getDataRange ( )

See Chart::Magick::Chart::getDataRange.

=cut

sub getDataRange {
    my $self = shift;

    return $self->SUPER::getDataRange( @_ ) unless $self->get('drawMode') eq 'cumulative';

    my $global = $self->dataset->globalData;
    my $maxNeg = 0;
    my $maxPos = 0;

    # Doing it this way is wrong b/c it should prolly be done in Data. However it works for now.
    foreach my $coord ( @{ $self->dataset->getCoords } ) {
        my @values = map { $self->dataset->getDataPoint( $coord, $_ ) } (0 .. $self->dataset->datasetCount - 1);

        my $negSum = sum( grep { $_ < 0 } map { $_ ? $_->[0] : 0 } @values ) || 0;
        my $posSum = sum( grep { $_ > 0 } map { $_ ? $_->[0] : 0 } @values ) || 0;

        $maxNeg = $negSum if $negSum < $maxNeg;
        $maxPos = $posSum if $posSum > $maxPos;
    }

    return ( $global->{ minCoord }, $global->{ maxCoord }, [ $maxNeg ], [ $maxPos ] );
}

#--------------------------------------------------------------------

=head2 getSymbolType ( )

See Chart::Magick::Chart::getSymbolType.

=cut

sub getSymbolType {
    my $self    = shift;
    my $legend  = $self->axis->legend;

    return $legend->SYMBOL_BLOCK;
}

#--------------------------------------------------------------------------

=head2 plot ( ) 

Plots the bars onto the axis set in the object.

=cut

sub plot {
    my $self = shift;

    my $barCount    = $self->dataset->datasetCount;
    my $groupCount  = $self->get('drawMode') eq 'cumulative' 
                    ? 1
                    : $barCount
                    ;


    my $minSpacing;
    my $p;
    foreach ( @{ $self->dataset->getCoords } ) {
        if ( defined $p ) {
            $minSpacing = abs( $_->[0] - $p ) if !$minSpacing || abs( $_->[0] - $p ) < $minSpacing;
        }
           
        $p = $_->[0];
    }

    my $dataRange       = 5;
    my $groupWidth      = $minSpacing; #$dataRange / $groupCount;
    my $groupSpacing    = $groupWidth * 0.1;
    my $barSpacing      = $groupWidth * 0.05;

    my $barWidth        = ( $groupWidth  - $groupSpacing ) / $groupCount - $barSpacing ;
    $barWidth *= 0.5;

    foreach my $coord ( @{ $self->dataset->getCoords } ) {
        my $positiveVerticalOffset = 0;
        my $negativeVerticalOffset = 0;
        for my $dataset ( 0 .. $barCount - 1 ) {
            my $color   = $self->colors->[ $dataset ]; #$self->getPalette->getNextColor;
            my $value   = $self->dataset->getDataPoint( $coord, $dataset );
            
            next unless $value;

            my $barLength = $value->[0];

            if ( $self->get('drawMode') eq 'cumulative' ) {
                my $verticalOffset;
                if ( $barLength >= 0 ) {
                    $verticalOffset          = $positiveVerticalOffset;
                    $positiveVerticalOffset += $barLength;
                }
                else {
                    $verticalOffset          = $negativeVerticalOffset;
                    $negativeVerticalOffset += $barLength;
                }

                # Draw bars on top of each other.
                $self->drawBar( $color, $barWidth, $barLength, $coord->[0], 0, $verticalOffset );

                $verticalOffset += $barLength;
            }
            else {
                # Default to sideBySide draw mode
                my $offset      = $dataset * ( $barWidth + $barSpacing) - ($barSpacing + $barWidth ) * ( $barCount - 1 ) / 2;

                $self->drawBar( $color, $barWidth, $barLength, $coord->[ 0 ], $offset, 0  );
            }
        }
    }
}

#--------------------------------------------------------------------------

=head2 preprocessData ( )

See Chart::Magick::Chart::preprocessData.

Please note the following:

=over 4

=item *

Sets the xTickOffset axis property to 1, unless it has been set to something else already.

=item *

Forces the xTickCount axis property to the number of bar(group)s. Even when xTickCount has been set already.

=cut

sub preprocessData {
    my $self = shift;
    my $axis = $self->axis;

    $self->SUPER::preprocessData;

    $axis->set('xTickOffset', 1 ) unless $axis->get('xTickOffset');
    $axis->set('xTickCount', scalar @{ $self->dataset->getCoords } ); # unless $axis->get('xTickCount');
}

1;

