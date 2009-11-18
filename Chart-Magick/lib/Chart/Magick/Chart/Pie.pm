package Chart::Magick::Chart::Pie;

use strict;
use constant pi => 3.14159265358979;

use Data::Dumper;

use base qw{ Chart::Magick::Chart };


#### TODO: getXOffset en Y offset tov. axis anchor bepalen.
sub getXOffset {
    my $self = shift;
    my $axis = $self->axis;

    return $axis->getChartWidth / 2 + $axis->get('marginLeft');
}

sub getYOffset {
    my $self = shift;
    my $axis = $self->axis;

    return $axis->getChartHeight / 2 + $axis->get('marginTop');
}

sub definition {
    my $self    = shift;
    my %options = %{ $self->SUPER::definition };

    my %overrides = (
        bottomHeight        => 0, 
        explosionLength     => 0,
        labelPosition       => 'top',
        labelOffset         => 10,
        pieMode             => 'normal',
        radius              => 100,
        scaleFactor         => 1,
        startAngle          => 0,
        shadedSides         => 1,
        stickColor          => '#333333',
        stickLength         => 0,
        stickOffset         => 0,
        tiltAngle           => 55,
        topHeight           => 20, 
    );  

    return { %options, %overrides };
}




=head1 NAME

Package WebGUI::Image::Graph::Pie

=head1 DESCRIPTION

Package to create pie charts, both 2d and 3d.

=head1 SYNOPSIS

Pie charts have a top height, bottom height which are the amounts of pixels the
top and bottom rise above and below the z = 0 plane respectively. These
properties can be used to create stepping effect.

Also xeplosion and scaling of individual pie slices is possible. Labels can be
connected via sticks and aligned to top, bottom and center of the pie.

The package automatically desides whether to draw in 2d or 3d mode based on the
angle by which the pie is tilted.

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 _mod2pi ( angle )

Returns the angle modulo 2*pi.

=head3 angle

The angle you want the modulo of.

=cut

sub _mod2pi {
	my $angle = shift;

	if ($angle < 0) {
		return 2*pi + $angle - 2*pi*int($angle/(2*pi));
	} else {
		return $angle - 2*pi*int($angle/(2*pi));
	}
}

#-------------------------------------------------------------------
sub addSlice {
	my $self        = shift;
	my $properties  = shift;
    my $slices      = $self->{_slices};

	my $percentage  = $properties->{percentage};
    # Work around a bug in imagemagick where an A path with the same start and end point will segfault.
	if ($percentage == 1) { 
		$percentage = 0.999999999;
	}

	my $sliceStart  =  
          scalar @{ $slices }           ? $slices->[ -1 ]->{ stopAngle }
        : $self->get('startAngle')      ? 2 * pi * $self->get('startAngle') / 360
        : 0
        ;

    my $angle       = _mod2pi( 2 * pi * $percentage         );
    my $startAngle  = _mod2pi( $sliceStart                  );
	my $stopAngle   = _mod2pi( $startAngle + $angle         );
	my $avgAngle    = _mod2pi( $startAngle + $angle  / 2    );

	my $color       = $properties->{color};
	my $fillColor   = $color->getFillColor;
	my $strokeColor = $color->getStrokeColor;
	my $sideColor   = $self->get('shadedSides') 
                    ? $color->darken->getFillColor
                    : $fillColor
                    ;

	push @{ $slices }, {
		# color properties
		fillColor	    => $fillColor,
		strokeColor	    => $strokeColor,
		bottomColor	    => $fillColor,
		topColor	    => $fillColor,
		startPlaneColor	=> $sideColor,
		stopPlaneColor	=> $sideColor,
		rimColor	    => $sideColor,

		# geometric properties
		topHeight	    => $self->get('topHeight'),
		bottomHeight	=> $self->get('bottomHeight'),
		explosionLength	=> $self->get('explosionLength'),
		scaleFactor	    => ($self->get('scaleFactor') - 1) * $percentage + 1,

		# keep the slice number for debugging properties
		sliceNr		    => scalar @{ $slices },
		label		    => $properties->{ label },
		percentage	    => $percentage,

        # angles
		startAngle	    => $startAngle,
		angle		    => $angle,
		avgAngle	    => $avgAngle,
		stopAngle	    => $stopAngle,
	};

    return;
}

#--------------------------------------------------------------------

sub bigCircle {
    my $self    = shift;
    my $angle   = shift;
    my $tilt    = $self->get('tiltAngle');

    return 
          $tilt <= 90 && $angle  < pi   ? '0'
        : $tilt <= 90 && $angle >= pi   ? '1'
        : $tilt >  90 && $angle  < pi   ? '1'
        : $tilt >  90 && $angle >= pi   ? '0'
        : 0;
}

#-------------------------------------------------------------------

=head2 calcCoordinates ( slice )

Calcs the coordinates of the corners of the given pie slice.

=head3 slice

Hashref containing the information that defines the slice. Must be formatted
like the slices built by addSlice.

=cut

sub calcCoordinates {
	my $self    = shift;
	my $slice   = shift;

    my $radius      = $self->get('radius') * $slice->{ scaleFactor };
	my $pieHeight   = $radius * cos( 2 * pi * $self->get('tiltAngle') / 360 );
	my $pieWidth    = $radius;
	
	# Translate the origin from the top corner to the center of the image.
	my $offsetX = $self->getXOffset;
	my $offsetY = $self->getYOffset;

	$offsetX += ( $pieWidth  / ( $pieWidth+$pieHeight ) ) * $slice->{explosionLength} * cos( $slice->{avgAngle} );
	$offsetY -= ( $pieHeight / ( $pieWidth+$pieHeight ) ) * $slice->{explosionLength} * sin( $slice->{avgAngle} );

    my $coords = {
        %{ $slice },
        tip         => {
            x   => $offsetX,
            y   => $offsetY,
        },
        startCorner => {
            x   => $offsetX + $pieWidth  * cos $slice->{ startAngle },
            y   => $offsetY - $pieHeight * sin $slice->{ startAngle },
        },
        endCorner   => {
            x   => $offsetX + $pieWidth  * cos $slice->{ stopAngle },
            y   => $offsetY - $pieHeight * sin $slice->{ stopAngle },
        },
    };

	return $coords;
}

#--------------------------------------------------------------------
sub splitSlice {
    my $self    = shift;
    my %slice   = %{ shift || {} };

    my ( $start, $stop, $angle ) = @slice{ qw( startAngle stopAngle angle ) };

    my @parts       = ();
    my $noLeft      = 0;

    # slice crosses the left intersect (pi)
    if ( $start < pi && $start + $angle > pi ) {
        my $partAngle = pi - $start;

        push @parts, $self->calcCoordinates( {
            %slice,
            angle           => $partAngle,
            startAngle      => $start,
            stopAngle       => pi,
            noLeft          => 0,
            noRight         => 1,
        } );

        $noLeft = 1;
        $angle  -= $partAngle;
        $start  = pi;
    }

    # slice crosses the right intersect (2*pi)
    if ( $start >= pi && $start + $angle > 2 * pi ) {
        my $partAngle   = 2 * pi - $start;
        
        push @parts, $self->calcCoordinates( {
            %slice,
            angle           => $partAngle,
            startAngle      => $start,
            stopAngle       => 2 * pi,
            noLeft          => $noLeft,
            noRight         => 1,
        } );

        $noLeft = 1;
        $angle  -= $partAngle;
        $start  = 0;
    }

    push @parts, $self->calcCoordinates( {
        %slice,
        angle       => $angle,
        startAngle  => $start,
        stopAngle   => $stop,
        noLeft      => $noLeft,
        noRight     => 0,
    } );
        
    return @parts;
}
            

#-------------------------------------------------------------------

=head2 draw ( )

Draws the pie chart.

=cut

sub plot {
	my ($currentSlice, $coordinates, $leftPlaneVisible, $rightPlaneVisible);
	my $self = shift;
    my $axis = $self->axis;

	$self->processDataset;

	# Draw slices in the correct order or you'll get an MC Escher.
	my @slices = map { $self->calcCoordinates( $_ ) } @{ $self->{_slices} };

	# First draw the bottom planes and the labels behind the chart.
	foreach my $sliceData (@slices) {
		# Draw bottom
		if ( $self->get('tiltAngle') <= 90 ) {
            $self->drawBottom( $sliceData );
        }
        else {
            $self->drawTop( $sliceData );
        }

		if (_mod2pi($sliceData->{avgAngle}) > 0 && _mod2pi($sliceData->{avgAngle}) <= pi) {
			$self->drawLabel($sliceData);
		}
	}

	# Second draw the sides
	# If angle == 0 do a 2d pie
	if ($self->get('tiltAngle') != 0) {
        my @parts = 
            sort    sortSlices                                          # sort slices in drwaing order
            map     { $self->splitSlice( $_ ) }                         # split slices crossing the horizontal axis
            @slices;

		foreach my $sliceData (@parts) {
			$leftPlaneVisible  = ( _mod2pi( $sliceData->{startAngle} ) <= 0.5*pi || _mod2pi($sliceData->{startAngle} >= 1.5*pi));
			$rightPlaneVisible = ( _mod2pi( $sliceData->{stopAngle}  ) >= 0.5*pi && _mod2pi($sliceData->{stopAngle} <= 1.5*pi));

			if ( $leftPlaneVisible && $rightPlaneVisible ) {
				$self->drawRim( $sliceData );
				$self->drawRightSide( $sliceData );
				$self->drawLeftSide( $sliceData );
			} 
            elsif ( $leftPlaneVisible && !$rightPlaneVisible ) {
				# right plane invisible
				$self->drawRightSide( $sliceData );
				$self->drawRim( $sliceData );
				$self->drawLeftSide( $sliceData );
			} 
            elsif ( !$leftPlaneVisible && $rightPlaneVisible ) {
				# left plane invisible
				$self->drawLeftSide( $sliceData );
				$self->drawRim( $sliceData );
				$self->drawRightSide( $sliceData );
			} else {
				$self->drawLeftSide( $sliceData );
				$self->drawRightSide( $sliceData );
				$self->drawRim( $sliceData );
			}
		}
	}

	# Finally draw the top planes of each slice and the labels that are in front of the chart.
	foreach my $sliceData (@slices) {
        if ( $self->get('tiltAngle') <= 90 ) {
    		$self->drawTop($sliceData) if ($self->get('tiltAngle') != 0);
        }
        else {
             $self->drawBottom( $sliceData);
        }

		if (_mod2pi($sliceData->{avgAngle}) > pi) {
			$self->drawLabel($sliceData);
		}
	}
}

#-------------------------------------------------------------------

=head2 drawBottom ( slice )

Draws the bottom of the given pie slice.

=head3 slice

A slice hashref. See addSlice for more information.

=cut

sub drawBottom {
	my $self    = shift;
	my $slice   = shift;

	$self->drawPieSlice($slice, -1 * $slice->{bottomHeight}, $slice->{bottomColor}); #  if ($slice->{drawTopPlane});
}

#-------------------------------------------------------------------

=head2 drawLabel ( slice )

Draws the label including stick if needed for the given pie slice.

=head3 slice

A slice properties hashref.

=cut

sub drawLabel {
	my $self    = shift;
	my $slice   = shift;
    
    my $tiltScale   = cos( 2 * pi * $self->get('tiltAngle') / 360 );
	my $angle       = $slice->{avgAngle};
    my $radius      = $self->get('radius');

	my $startRadius = $radius * $slice->{ scaleFactor } + $self->get('stickOffset');
	my $stopRadius  = $startRadius + $self->get('stickLength');

    $self->im->Draw(
        primitive   => 'Line',
        points      => $self->getXOffset ."," . $self->getYOffset . " " .$self->getXOffset ."," .$self->getYOffset,
        stroke      => 'white',
    );

	my $pieHeight   = $radius * $tiltScale;
	my $pieWidth    = $radius;

    my $explodeX    = $slice->{explosionLength} * $pieWidth  / ( $pieHeight + $pieWidth );
    my $explodeY    = $slice->{explosionLength} * $pieHeight / ( $pieHeight + $pieWidth );
	my $startPointX = $self->getXOffset + ( $explodeX + $startRadius ) * cos $angle;
	my $startPointY = $self->getYOffset - ( $explodeY + $startRadius ) * $tiltScale * sin $angle;
	my $endPointX   = $self->getXOffset + ( $explodeX + $stopRadius  ) * cos $angle;
	my $endPointY   = $self->getYOffset - ( $explodeY + $stopRadius  ) * $tiltScale * sin $angle;

	if ($self->get('tiltAngle')) {
        my $position     = $self->get('labelPosition');
        my $labelOffsetY =
              $position eq 'top'        ? $slice->{topHeight}
            : $position eq 'bottom'     ? $slice->{bottomHeight}
            :                           ( $slice->{topHeight} - $slice->{bottomHeight} ) / 2;

        $startPointY    -= $labelOffsetY;
        $endPointY      -= $labelOffsetY;
	}

	# Draw the stick
	if ($self->get('stickLength')){
		$self->im->Draw(
			primitive	=> 'Path',
			stroke		=> $self->get('stickColor'),
			strokewidth	=> 3,
			points		=> 
				" M $startPointX,$startPointY ".
				" L $endPointX,$endPointY ",
			fill		=> 'none',
		);
	}
	
	# Process the textlabel
    my $horizontalAlign =
          $angle > 0.5 * pi && $angle < 1.5 * pi    ? 'right'
        : $angle < 1.5 * pi || $angle > 1.5 * pi    ? 'left'
        : 'center';
        
    my $verticalAlign    = 
          $angle < pi   ? 'bottom'
        : $angle > pi   ? 'top'
        : 'center';
        
	my $anchorX 
        = $horizontalAlign eq 'right'  
	    ? $endPointX - $self->get('labelOffset')
        : $endPointX + $self->get('labelOffset')
        ;

	my $text = $slice->{label} || sprintf('%.1f', $slice->{percentage}*100).' %';

	my $maxWidth = $anchorX;
	$maxWidth = $self->axis->get('width') - $anchorX if ($slice->{avgAngle} > 1.5 * pi || $slice->{avgAngle} < 0.5 * pi);
   
	$self->axis->text(
        text            => $text,
		halign          => $horizontalAlign,
		align           => ucfirst $horizontalAlign,
		valign          => $verticalAlign,
		x               => $anchorX,
		y               => $endPointY,
        font            => $self->axis->get('labelFont'),
        pointsize       => $self->axis->get('labelFontSize'),
        fill            => $self->axis->get('labelColor'),
        wrapWidth       => $maxWidth,
	);
}

#-------------------------------------------------------------------

=head2 drawLeftSide ( slice )

Draws the side connected to the startpoint of the slice.

=head3 slice

A slice properties hashref.

=cut

sub drawLeftSide {
	my $self    = shift;
	my $slice   = shift;
	
	$self->drawSide( $slice ) unless ( $slice->{ noLeft } );
}

#-------------------------------------------------------------------

=head2 drawPieSlice ( slice, offset, fillColor )

Draws a pie slice shape, ie. the bottom or top of a slice.

=head3 slice

A slice properties hashref.

=head3 offset

The offset in pixels for the y-direction. This is used to create the thickness
of the pie.

=head3 fillColor

The color with which the slice should be filled.

=cut

sub drawPieSlice {
    my $self        = shift;
	my $slice       = shift;
	my $offset      = shift || 0;
	my $fillColor   = shift;

	my %tip = (
		x	=> $slice->{tip}->{x},
		y	=> $slice->{tip}->{y} - $offset,
	);
	my %startCorner = (
		x	=> $slice->{startCorner}->{x},
		y	=> $slice->{startCorner}->{y} - $offset,
	);
	my %endCorner = (
		x	=> $slice->{endCorner}->{x},
		y	=> $slice->{endCorner}->{y} - $offset,
	);

    my $radius     = $self->get('radius') * $slice->{ scaleFactor  };
	my $pieWidth   = $radius; 
	my $pieHeight  = $radius * cos(2 * pi * $self->get('tiltAngle') / 360);
	my $bigCircle  = $self->bigCircle( $slice->{ angle } );

	$self->im->Draw(
		primitive	=> 'Path',
		stroke		=> $slice->{strokeColor},
		points		=> 
			" M $tip{x},$tip{y} ".
			" L $startCorner{x},$startCorner{y} ".
			" A $pieWidth,$pieHeight 0 $bigCircle,0 $endCorner{x},$endCorner{y} ".
			" Z ",
		fill		=> $fillColor,
	);
}

#-------------------------------------------------------------------

=head2 drawRightSide ( slice )

Draws the side connected to the endpoint of the slice.

=head3 slice

A slice properties hashref.

=cut

sub drawRightSide {
	my $self = shift;
	my $slice = shift;
	
	$self->drawSide( $slice, 'endCorner', $slice->{stopPlaneColor} ) unless ( $slice->{ noRight } );
}

#-------------------------------------------------------------------

=head2 drawRim ( slice )

Draws the rim of the slice.

=head3 slice

A slice properties hashref.

=cut

sub drawRim {
	my (%startSideTop, %startSideBottom, %endSideTop, %endSideBottom,
		$pieWidth, $pieHeight, $bigCircle);
	my $self = shift;
	my $slice = shift;
	
	%startSideTop = (
		x	=> $slice->{startCorner}->{x},
		y	=> $slice->{startCorner}->{y} - $slice->{topHeight}
	);
	%startSideBottom = (
		x	=> $slice->{startCorner}->{x},
		y	=> $slice->{startCorner}->{y} + $slice->{bottomHeight}
	);
	%endSideTop = (
		x	=> $slice->{endCorner}->{x},
		y	=> $slice->{endCorner}->{y} - $slice->{topHeight}
	);
	%endSideBottom = (
		x	=> $slice->{endCorner}->{x},
		y	=> $slice->{endCorner}->{y} + $slice->{bottomHeight}
	);

    my $radius  = $self->get('radius') * $slice->{ scaleFactor };
	$pieWidth   = $radius;
	$pieHeight  = $radius * cos(2 * pi * $self->get('tiltAngle') / 360);
	$bigCircle  = $self->bigCircle( $slice->{ angle } );
	
	# Draw curvature
	$self->im->Draw(
		primitive       => 'Path',
		stroke          => $slice->{strokeColor},
		points		=> 
			" M $startSideBottom{x},$startSideBottom{y} ".
			" A $pieWidth,$pieHeight 0 $bigCircle,0 $endSideBottom{x},$endSideBottom{y} ".
			" L $endSideTop{x}, $endSideTop{y} ".
			" A $pieWidth,$pieHeight 0 $bigCircle,1 $startSideTop{x},$startSideTop{y}".
			" Z",
		fill		=> $slice->{rimColor},
	);
}

#-------------------------------------------------------------------

=head2 drawSide ( slice, [ cornerName ], [ fillColor ] )

Draws the sides connecting the rim and tip of a pie slice.

=head3 slice

A slice properties hashref.

=head3 cornerName

Specifies which side you want to draw, identified by the name of the corner that
attaches it to the rim. Can be either 'startCorner' or 'endCorner'. If ommitted
it will default to 'startCorner'.

=head3 fillColor

The color with which the side should be filled. If not passed the color for the
'startCorner' side will be defaulted to.

=cut

sub drawSide {
	my (%tipTop, %tipBottom, %rimTop, %rimBottom);
	my $self = shift;
	my $slice = shift;
	my $cornerName = shift || 'startCorner';
	my $color = shift || $slice->{startPlaneColor};
	
	%tipTop = (
		x	=> $slice->{tip}->{x},
		y	=> $slice->{tip}->{y} - $slice->{topHeight}
	);
	%tipBottom = (
		x	=> $slice->{tip}->{x},
		y	=> $slice->{tip}->{y} + $slice->{bottomHeight}
	);
	%rimTop = (
		x	=> $slice->{$cornerName}->{x},
		y	=> $slice->{$cornerName}->{y} - $slice->{topHeight}
	);
	%rimBottom = (
		x	=> $slice->{$cornerName}->{x},
		y	=> $slice->{$cornerName}->{y} + $slice->{bottomHeight}
	);

    $self->im->Draw(
        primitive   => 'Path',
        stroke      => $slice->{strokeColor},
        points      =>
            " M $tipBottom{x},$tipBottom{y} ". 
            " L $rimBottom{x},$rimBottom{y} ".
            " L $rimTop{x},$rimTop{y} ".
            " L $tipTop{x},$tipTop{y} ".
            " Z ",
        fill        => $color,
    );
}

#-------------------------------------------------------------------

=head2 drawBottom ( slice )

Draws the bottom of the given pie slice.

=head3 slice

A slice hashref. See addSlice for more information.

=cut

sub drawTop {
	my $self = shift;
	my $slice = shift;

	$self->drawPieSlice($slice, $slice->{topHeight}, $slice->{topColor}); # if ($slice->{drawTopPlane});
}

#-------------------------------------------------------------------

=head2 new ( )

Contstructor. See SUPER classes for additional parameters.

=cut

sub new {
	my $class = shift;
	
	my $self = $class->SUPER::new(@_);
	$self->{_slices} = [];

	return $self;
}

#-------------------------------------------------------------------

=head2 processDataset ( )

Takes the dataset and takes the necesarry steps for the pie to be drawn.

=cut

sub processDataset {
	my $self    = shift;

	my $total = $self->dataset->datasetData->[0]->{ total }->[ 0 ] || 1;

    my $divisor     = $self->dataset->datasetData->[0]->{ coordCount }; # avoid division by zero
	my $stepsize    = ( $self->get('topHeight') + $self->get('bottomHeight') ) / $divisor;

	for my $coord ( @{ $self->dataset->getCoords } ) {
        my $x = $coord->[0];
        my $y = $self->dataset->getDataPoint( $coord, 0 )->[0];

        # Skip undef or negative values
        next unless $y >= 0;

		$self->addSlice( {
			percentage	=> $y / $total, 
			label		=> $self->axis->getLabels( 0, $x ) || $x,
			color		=> $self->getPalette->getNextColor,
		} );
		
		$self->set('topHeight', $self->get('topHeight') - $stepsize) if ($self->get('pieMode') eq 'stepped');
	}
}

#-------------------------------------------------------------------

=head2 sortSlices

A sort routine for sorting the slices in drawing order. Must be run from within
the sort command.

=cut

sub sortSlices {
	my $self = shift;

	my $aStart = $a->{startAngle};
	my $aStop  = $a->{stopAngle};
	my $bStart = $b->{startAngle};
	my $bStop  = $b->{stopAngle};

	# If sliceA and sliceB are in different halfplanes sorting is easy...
	return -1 if ( $aStart  < pi && $bStart >= pi );
	return  1 if ( $aStart >= pi && $bStart < pi  );

	if ($aStart < pi) {
		if ($aStop <= 0.5*pi && $bStop <= 0.5* pi) {
			# A and B in quadrant I
			return 1 if ($aStart < $bStart);
			return -1;
		} elsif ($aStart >= 0.5*pi && $bStart >= 0.5*pi) {
			# A and B in quadrant II
			return 1 if ($aStart > $bStart);
			return -1;
		} elsif ($aStart < 0.5*pi && $aStop >= 0.5*pi) {
			# A in both quadrant I and II
			return -1;
		} else {
			# B in both quadrant I and II
			return 1;
		}
	} else {
		if ($aStop <= 1.5*pi && $bStop <= 1.5*pi) {
			# A and B in quadrant III
			return 1 if ($aStop > $bStop);
			return -1;
		} elsif ($aStart >= 1.5*pi && $bStart >= 1.5*pi) {
			# A and B in quadrant IV
			return 1 if ($aStart < $bStart);
			return -1;
		} elsif ($aStart <= 1.5*pi && $aStop >= 1.5*pi) {
			# A in both quadrant III and IV
			return 1;
		} else {
			# B in both quadrant III and IV
			return -1;
		}
	}
	
	return 0;
}

1;

