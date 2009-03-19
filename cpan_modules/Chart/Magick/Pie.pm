package Chart::Magick::Pie;

use strict;
use constant pi => 3.14159265358979;

use base qw{ Chart::Magick::Chart };

#### TODO: getXOffset en Y offset tov. axis anchor bepalen.
sub getXOffset {
    my $self = shift;

    return $self->{ axis }->plotOption( 'axisWidth' ) / 2 + $self->{ axis }->get('marginLeft');
}

sub getYOffset {
    my $self = shift;

    return $self->{ axis }->plotOption( 'axisHeight' ) / 2 + $self->{ axis }->get('marginTop');
}

sub im {
    my $self = shift;

    return $self->{ axis }->im;
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
#		return 2*pi + $angle - 2*pi*int($angle/(2*pi));
	} else {
		return $angle - 2*pi*int($angle/(2*pi));
	}
}

#-------------------------------------------------------------------
sub addSlice {
	my (%slice, $leftMost, $rightMost, $center, $overallStartCorner, $overallEndCorner, 
		$fillColor, $strokeColor, $sideColor);
	my $self = shift;
	my $properties = shift;

	my $percentage = $properties->{percentage};

	# Work around a bug in imagemagick where an A path with the same start and end point will segfault.
	if ($percentage == 1) { 
		$percentage = 0.999999999;
	}

	my $label = $properties->{label};
	my $color = $properties->{color};
	
	my $angle = 2*pi*$percentage;
	my $startAngle = _mod2pi($self->{_currentAngle}) || _mod2pi(2*pi*$self->get('startAngle')/360) || 0; 
	my $stopAngle = _mod2pi($startAngle + $angle);
	my $avgAngle = _mod2pi((2 * $startAngle + $angle) / 2);

	$self->{_currentAngle} = $stopAngle;

	my $mainStartDraw = 1;
	my $mainStopDraw = 1;

	$fillColor = $color->getFillColor;
	$strokeColor = $color->getStrokeColor;
	
#	if ($self->get('shadedSides')) {
#		$sideColor = $color->darken->getFillColor;
#	} else {
		$sideColor = $fillColor;
#	}
	
	my %sliceData = (
		# color properties
		fillColor	=> $fillColor,
		strokeColor	=> $strokeColor,
		bottomColor	=> $fillColor, #$properties->{bottomColor} || $properties->{fillColor},
		topColor	=> $fillColor, #$properties->{topColor} || $properties->{fillColor},
		startPlaneColor	=> $sideColor, #$properties->{startPlaneColor} || $properties->{fillColor},
		stopPlaneColor	=> $sideColor, #$properties->{stopPlaneColor} || $properties->{fillColor},
		rimColor	=> $sideColor, #$properties->{rimColor} || $properties->{fillColor},

		# geometric properties
		topHeight	=> $self->get('topHeight'),
		bottomHeight	=> $self->get('bottomHeight'),
		explosionLength	=> $self->get('explosionLength'),
		scaleFactor	=> $self->get('scaleFactor'),

		# keep the slice number for debugging properties
		sliceNr		=> scalar(@{$self->{_slices}}),
		label		=> $label,
		percentage	=> $percentage,
	);

	# parttion the slice if it crosses the x-axis
	%slice = (
		startAngle	=> $startAngle,
		angle		=> $angle,
		avgAngle	=> $avgAngle,
		stopAngle	=> $stopAngle,
		%sliceData
	);

	my $hopsa = $self->calcCoordinates(\%slice);
	$sliceData{overallStartCorner} = $hopsa->{startCorner};
	$sliceData{overallEndCorner} = $hopsa->{endCorner};
	$sliceData{overallBigCircle} = $hopsa->{bigCircle};
	
	my $leftIntersect = pi;
	my $rightIntersect = $leftIntersect+pi;
	
	if ($startAngle < $leftIntersect) {
		if ($stopAngle > $leftIntersect || $stopAngle < $startAngle) {
			%slice = (
				startAngle	=> $startAngle,
				angle		=> $leftIntersect - $startAngle,
				stopAngle	=> $leftIntersect,
				avgAngle	=> $avgAngle,
				####
				drawStartPlane	=> 1,
				drawStopPlane	=> 0,
				drawTopPlane	=> 1,
				id 		=> scalar(@{$self->{_slices}}),
				%sliceData
			);
			$mainStopDraw = 0;
			$startAngle = $leftIntersect;

			$leftMost = { %slice, %{$self->calcCoordinates(\%slice)} };
			
			push (@{$self->{_slices}}, $leftMost);
		}

		if ($stopAngle < $startAngle) {
			%slice = (
				startAngle	=> $leftIntersect,
				angle		=> pi,
				stopAngle	=> $rightIntersect,
				avgAngle	=> $avgAngle,
				####
				drawStartPlane	=> 0,
				drawStopPlane	=> 0,
				drawTopPlane	=> 0,
				id 		=> scalar(@{$self->{_slices}}),
				%sliceData
			);
			$mainStopDraw = 0;
			$startAngle = 0;

			$center = { %slice, %{$self->calcCoordinates(\%slice)} };
			
			push (@{$self->{_slices}}, $center);
		}

			
		%slice = (
			mainSlice	=> 1,
			startAngle	=> $startAngle,
			angle		=> $stopAngle - $startAngle,
			stopAngle	=> $stopAngle,
			avgAngle	=> $avgAngle,
			####
			drawStartPlane	=> !defined($leftMost->{drawStartPlane}),
			drawStopPlane	=> 1,
			drawTopPlane	=> !$leftMost->{drawTopPlane},
			id 		=> scalar(@{$self->{_slices}}),
			%sliceData
		);
		$mainStopDraw = 0;
		$rightMost = { %slice, %{$self->calcCoordinates(\%slice)} };
	
		push (@{$self->{_slices}}, $rightMost );
	} else {
		if ($stopAngle < $leftIntersect || $stopAngle < $startAngle) {
			%slice = (
				startAngle	=> $startAngle,
				angle		=> $rightIntersect - $startAngle,
				stopAngle	=> $rightIntersect,
				avgAngle	=> $avgAngle,
				####
				drawStartPlane	=> 1,
				drawStopPlane	=> 0,
				drawTopPlane	=> 0,
				id 		=> scalar(@{$self->{_slices}}),
				%sliceData
			);
			$mainStopDraw = 0;
			$startAngle = 0;

			$leftMost = { %slice, %{$self->calcCoordinates(\%slice)} };
			$overallStartCorner = $leftMost->{startCorner};
			
			push (@{$self->{_slices}}, $leftMost);
		}

		if ($stopAngle < $startAngle && $stopAngle > $leftIntersect) {
			%slice = (
				startAngle	=> 0,
				angle		=> pi,
				stopAngle	=> $leftIntersect,
				avgAngle	=> $avgAngle,
				####
				drawStartPlane	=> 0,
				drawStopPlane	=> 0,
				drawTopPlane	=> 0,
				id 		=> scalar(@{$self->{_slices}}),
				%sliceData
			);
			$mainStopDraw = 0;
			$startAngle = $leftIntersect;

			$center = { %slice, %{$self->calcCoordinates(\%slice)} };
			
			push (@{$self->{_slices}}, $center);
		}

			
		%slice = (
			mainSlice	=> 1,
			startAngle	=> $startAngle,
			angle		=> $stopAngle - $startAngle,
			stopAngle	=> $stopAngle,
			avgAngle	=> $avgAngle,
			####
			drawStartPlane	=> !defined($leftMost->{drawStartPlane}),
			drawStopPlane	=> 1,
			drawTopPlane	=> !$leftMost->{drawTopPlane},
			id 		=> scalar(@{$self->{_slices}}),
			%sliceData
		);
		$mainStopDraw = 0;
		$startAngle = $leftIntersect;

		$rightMost = { %slice, %{$self->calcCoordinates(\%slice)} };
		
		push (@{$self->{_slices}}, $rightMost);
	}

}

#-------------------------------------------------------------------

=head2 calcCoordinates ( slice )

Calcs the coordinates of the corners of the given pie slice.

=head3 slice

Hashref containing the information that defines the slice. Must be formatted
like the slices built by addSlice.

=cut

sub calcCoordinates {
	my ($pieHeight, $pieWidth, $offsetX, $offsetY, $coords);
	my $self = shift;
	my $slice = shift;

	$pieHeight = $self->get('radius') * cos(2 * pi * $self->get('tiltAngle') / 360);
	$pieWidth = $self->get('radius');
	
	# Translate the origin from the top corner to the center of the image.
	$offsetX = $self->getXOffset;
	$offsetY = $self->getYOffset;

	$offsetX += ($self->get('radius')/($pieWidth+$pieHeight))*$slice->{explosionLength}*cos($slice->{avgAngle});
	$offsetY -= ($pieHeight/($pieWidth+$pieHeight))*$slice->{explosionLength}*sin($slice->{avgAngle});

	$coords->{bigCircle} = ($slice->{angle} > pi) ? '1' : '0';
	$coords->{tip}->{x} = $offsetX;
	$coords->{tip}->{y} = $offsetY;
	$coords->{startCorner}->{x} = $offsetX + $pieWidth*$slice->{scaleFactor}*cos($slice->{startAngle});
	$coords->{startCorner}->{y} = $offsetY - $pieHeight*$slice->{scaleFactor}*sin($slice->{startAngle});
	$coords->{endCorner}->{x} = $offsetX + $pieWidth*$slice->{scaleFactor}*cos($slice->{stopAngle});
	$coords->{endCorner}->{y} = $offsetY - $pieHeight*$slice->{scaleFactor}*sin($slice->{stopAngle});

	return $coords;
}

#-------------------------------------------------------------------

=head2 draw ( )

Draws the pie chart.

=cut

sub plot {
	my ($currentSlice, $coordinates, $leftPlaneVisible, $rightPlaneVisible);
	my $self = shift;
    my $axis = shift;

    $self->{ axis } = $axis;
	
	$self->processDataset;

	# Draw slices in the correct order or you'll get an MC Escher.
	my @slices = sort sortSlices @{$self->{_slices}};
	
	# First draw the bottom planes and the labels behind the chart.
	foreach my $sliceData (@slices) {
		# Draw bottom
		$self->drawBottom($sliceData);

		if (_mod2pi($sliceData->{avgAngle}) > 0 && _mod2pi($sliceData->{avgAngle}) <= pi) {
			$self->drawLabel($sliceData);
		}
	}

	# Second draw the sides
	# If angle == 0 do a 2d pie
	if ($self->get('tiltAngle') != 0) {
		foreach my $sliceData (@slices) {  #(sort sortSlices @{$self->{_slices}}) {
			$leftPlaneVisible = (_mod2pi($sliceData->{startAngle}) <= 0.5*pi || _mod2pi($sliceData->{startAngle} >= 1.5*pi));
			$rightPlaneVisible = (_mod2pi($sliceData->{stopAngle}) >= 0.5*pi && _mod2pi($sliceData->{stopAngle} <= 1.5*pi));

			if ($leftPlaneVisible && $rightPlaneVisible) {
				$self->drawRim($sliceData);
				$self->drawRightSide($sliceData);
				$self->drawLeftSide($sliceData);
			} elsif ($leftPlaneVisible && !$rightPlaneVisible) {
				# right plane invisible
				$self->drawRightSide($sliceData);
				$self->drawRim($sliceData);
				$self->drawLeftSide($sliceData);
			} elsif (!$leftPlaneVisible && $rightPlaneVisible) {
				# left plane invisible
				$self->drawLeftSide($sliceData);
				$self->drawRim($sliceData);
				$self->drawRightSide($sliceData);
			} else {
				$self->drawLeftSide($sliceData);
				$self->drawRightSide($sliceData);
				$self->drawRim($sliceData);
			}
		}
	}

	# Finally draw the top planes of each slice and the labels that are in front of the chart.
	foreach my $sliceData (@slices) {
		$self->drawTop($sliceData) if ($self->get('tiltAngle') != 0);

		if (_mod2pi($sliceData->{avgAngle}) > pi) {
			$self->drawLabel($sliceData);
		}
	}

    delete $self->{ axis };
}

#-------------------------------------------------------------------

=head2 drawBottom ( slice )

Draws the bottom of the given pie slice.

=head3 slice

A slice hashref. See addSlice for more information.

=cut

sub drawBottom {
	my $self = shift;
	my $slice = shift;

	$self->drawPieSlice($slice, -1 * $slice->{bottomHeight}, $slice->{bottomColor})  if ($slice->{drawTopPlane});
}

#-------------------------------------------------------------------

=head2 drawLabel ( slice )

Draws the label including stick if needed for the given pie slice.

=head3 slice

A slice properties hashref.

=cut

sub drawLabel {
	my ($startRadius, $stopRadius, $pieHeight, $pieWidth, $startPointX, $startPointY, 
		$endPointX, $endPointY);
	my $self = shift;
	my $slice = shift;

	# Draw labels only once
	return undef unless ($slice->{mainSlice});

	$startRadius = $self->get('radius') * $slice->{scaleFactor}+ $self->get('stickOffset');
	$stopRadius = $startRadius + $self->get('stickLength');

	$pieHeight = $self->get('radius') * cos(2 * pi * $self->get('tiltAngle') / 360);
	$pieWidth = $self->get('radius');

	$startPointX = $self->getXOffset + ($slice->{explosionLength}*$pieWidth/($pieHeight+$pieWidth)+$startRadius) * cos($slice->{avgAngle});
	$startPointY = 
        $self->getYOffset - ($slice->{explosionLength}*$pieHeight/($pieHeight+$pieWidth)+$startRadius) * sin($slice->{avgAngle}) * cos(2 * pi * $self->get('tiltAngle') / 360);
	$endPointX = $self->getXOffset + ($slice->{explosionLength}*$pieWidth/($pieHeight+$pieWidth)+$stopRadius) * cos($slice->{avgAngle});
	$endPointY = $self->getYOffset - ($slice->{explosionLength}*$pieHeight/($pieHeight+$pieWidth)+$stopRadius) *
    sin($slice->{avgAngle}) * cos(2 * pi * $self->get('tiltAngle') / 360);

	if ($self->get('tiltAngle')) {
		if ($self->get('labelPosition') eq 'center') {
			$startPointY -= ($slice->{topHeight} - $slice->{bottomHeight}) / 2;
			$endPointY -= ($slice->{topHeight} - $slice->{bottomHeight}) / 2;
		}
		elsif ($self->get('labelPosition') eq 'top') {
			$startPointY -= $slice->{topHeight};
			$endPointY -= $slice->{topHeight};
		}
		elsif ($self->get('labelPosition') eq 'bottom') {
			$startPointY += $slice->{bottomHeight};
			$endPointY += $slice->{bottomHeight};
		}

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
	my $horizontalAlign = 'center';
	my $align = 'Center';
	if ($slice->{avgAngle} > 0.5 * pi && $slice->{avgAngle} < 1.5 * pi) {
		$horizontalAlign = 'right';
		$align = 'Right';
	}
	elsif ($slice->{avgAngle} > 1.5 * pi || $slice->{avgAngle} < 0.5 * pi) {
		$horizontalAlign = 'left';
		$align = 'Left';
	}

	my $verticalAlign = 'center';
	$verticalAlign = 'bottom' if ($slice->{avgAngle} == 0.5 * pi);
	$verticalAlign = 'top' if ($slice->{avgAngle} == 1.5 * pi);

	my $anchorX = $endPointX + $self->get('labelOffset');
	$anchorX = $endPointX - $self->get('labelOffset') if ($horizontalAlign eq 'right');

	my $text = $slice->{label} || sprintf('%.1f', $slice->{percentage}*100).' %';

	my $maxWidth = $anchorX;
####	$maxWidth = $self->getImageWidth - $anchorX if ($slice->{avgAngle} > 1.5 * pi || $slice->{avgAngle} < 0.5 * pi);
	$maxWidth = $self->get('chartWidth') - $anchorX if ($slice->{avgAngle} > 1.5 * pi || $slice->{avgAngle} < 0.5 * pi);
	
	$self->{ axis }->text(
        text            => $text, #$self->wrapLabelToWidth( $text, $maxWidth ),
		alignHorizontal => $horizontalAlign,
		align           => $align,
		alignVertical   => $verticalAlign,
		x               => $anchorX,
		y               => $endPointY,
        font            => $self->{ axis }->get('labelFont'),
        pointsize       => $self->{ axis }->get('labelFontSize'),
        fill            => $self->{ axis }->get('labelColor'),
	);
}

#-------------------------------------------------------------------

=head2 drawLeftSide ( slice )

Draws the side connected to the startpoint of the slice.

=head3 slice

A slice properties hashref.

=cut

sub drawLeftSide {
	my $self = shift;
	my $slice = shift;
	
	$self->drawSide($slice) if ($slice->{drawStartPlane});
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
	my (%tip, %startCorner, %endCorner, $pieWidth, $pieHeight, $bigCircle,
		$strokePath);
	my $self = shift;
	my $slice = shift;
	my $offset = shift || 0;
	my $fillColor = shift;

	%tip = (
		x	=> $slice->{tip}->{x},
		y	=> $slice->{tip}->{y} - $offset,
	);
	%startCorner = (
		x	=> $slice->{overallStartCorner}->{x},
		y	=> $slice->{overallStartCorner}->{y} - $offset,
	);
	%endCorner = (
		x	=> $slice->{overallEndCorner}->{x},
		y	=> $slice->{overallEndCorner}->{y} - $offset,
	);

	$pieWidth = $self->get('radius'); 
	$pieHeight = $self->get('radius') * cos(2 * pi * $self->get('tiltAngle') / 360);
	$bigCircle = $slice->{overallBigCircle};

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
	
	$self->drawSide($slice, 'endCorner', $slice->{stopPlaneColor}) if ($slice->{drawStopPlane});
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
	
	$pieWidth = $self->get('radius');
	$pieHeight = $self->get('radius') * cos(2 * pi * $self->get('tiltAngle') / 360);
	$bigCircle = $slice->{bigCircle};
	
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
		primitive       => 'Path',
		stroke          => $slice->{strokeColor},
		points		=> 
			" M $tipBottom{x},$tipBottom{y} ". 
			" L $rimBottom{x},$rimBottom{y} ".
			" L $rimTop{x},$rimTop{y} ".
			" L $tipTop{x},$tipTop{y} ".
			" Z ",
		fill		=> $color,
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

	$self->drawPieSlice($slice, $slice->{topHeight}, $slice->{topColor}) if ($slice->{drawTopPlane});
}

#-------------------------------------------------------------------

=head2 formNamespace ( )

Extends the form namespace for this object. See WebGUI::Image::Graph for
documentation.

=cut

sub formNamespace {
	my $self = shift;

	return $self->SUPER::formNamespace.'_Pie';
}

#-------------------------------------------------------------------

=head2 getSlice ( [ sliceNumber ] )

Returns the sliceNumber'th slice properties hashref. Defaults to the slice last
added.

=head3 sliceNumber

The index of the slice you want.

=cut

sub getSlice {
	my $self = shift;
	my $slice = shift || (scalar(@{$self->{_slices}}) - 1);

	return $self->{_slices}->[$slice];
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

	my $total = $self->dataset->datasetData->[0]->{ total } || 1;

    my $divisor     = $self->dataset->datasetData->[0]->{ coordCount }; # avoid division by zero
	my $stepsize    = ( $self->get('topHeight') + $self->get('bottomHeight') ) / $divisor;

	for my $x ( $self->dataset->getCoords ) {
        my $y = $self->dataset->getDataPoint( $x, 0 );

        # Skip undef or negative values
        next unless $y >= 0;

		$self->addSlice( {
			percentage	=> $y / $total, 
			label		=> $x,
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
	my ($startA, $stopA, $startB, $stopB, $distA, $distB);
	my $self = shift;

	my $aStartAngle = $a->{startAngle};
	my $aStopAngle = $a->{stopAngle};
	my $bStartAngle = $b->{startAngle};
	my $bStopAngle = $b->{stopAngle};

	# If sliceA and sliceB are in different halfplanes sorting is easy...
	return -1 if ($aStartAngle < pi && $bStartAngle >= pi);
	return 1 if ($aStartAngle >= pi && $bStartAngle < pi);

	if ($aStartAngle < pi) {
		if ($aStopAngle <= 0.5*pi && $bStopAngle <= 0.5* pi) {
			# A and B in quadrant I
			return 1 if ($aStartAngle < $bStartAngle);
			return -1;
		} elsif ($aStartAngle >= 0.5*pi && $bStartAngle >= 0.5*pi) {
			# A and B in quadrant II
			return 1 if ($aStartAngle > $bStartAngle);
			return -1;
		} elsif ($aStartAngle < 0.5*pi && $aStopAngle >= 0.5*pi) {
			# A in both quadrant I and II
			return -1;
		} else {
			# B in both quadrant I and II
			return 1;
		}
	} else {
		if ($aStopAngle <= 1.5*pi && $bStopAngle <= 1.5*pi) {
			# A and B in quadrant III
			return 1 if ($aStopAngle > $bStopAngle);
			return -1;
		} elsif ($aStartAngle >= 1.5*pi && $bStartAngle >= 1.5*pi) {
			# A and B in quadrant IV
			return 1 if ($aStartAngle < $bStartAngle);
			return -1;
		} elsif ($aStartAngle <= 1.5*pi && $aStopAngle >= 1.5*pi) {
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

