package Chart::Magick::Axis;

use strict;
use Class::InsideOut qw{ :std };
use Image::Magick;

use constant pi => 3.14159265358979;

readonly charts         => my %charts;
private  properties     => my %properties;
private  plotOptions    => my %plotOptions;
private  im             => my %magick;

#----------------------------------------------
sub _buildObject {
    my $class       = shift;
    my $properties  = shift;
    my $magick      = shift;
    my $self        = {};

    bless       $self, $class;
    register    $self;

    my $id = id $self;

    $charts{ $id }  = [];
    $properties{ $id } = { %{ $self->definition }, %{ $properties } } || {};

    return $self;
}

sub im {
    my $self = shift;

    my $im = $magick{ id $self };
    return $im if $im;

    my $width   = $self->get('width')   || die "no height";
    my $height  = $self->get('height')  || die "no width";
    my $magick  = Image::Magick->new(
        size        => $width.'x'.$height,
    );
    $magick->Read('xc:white');
    $magick{ id $self } = $magick;

    return $magick;
}

#----------------------------------------------
=head2 new ( [ properties ] )

Contructor for this axis.

=cut

sub new {
    my $class       = shift;
    my $properties  = shift || {};
    
#    my $width   = $properties->{ width  } || die "no height";
#    my $height  = $properties->{ height } || die "no width";
#    my $magick  = Image::Magick->new(
#        size        => $width.'x'.$height,
#    );
#    $magick->Read('xc:white');
#
#    return $class->_buildObject( $properties, $magick );
    return $class->_buildObject( $properties );
}

#---------------------------------------------
=head2 addChart ( chart )

Adds a chart to this axis.

=head3 chart

An instantiated Chart::Magick::Chart object.

=cut

sub addChart {
    my $self    = shift;
    my $chart   = shift;

#    if ( $chart->axisType eq $self->type ) {
        push @{ $charts{ id $self } }, $chart;
#    }
    
}

#---------------------------------------------
sub definition {
    my $self = shift;

    my %options = (
        width           => 400,
        height          => 300,

        marginLeft      => 40,
        marginTop       => 50,
        marginRight     => 20,
        marginBottom    => 20,

        title           => '',
        titleFont       => '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
        titleFontSize   => 20,
        titleColor      => 'purple',

        labelFont       => '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
        labelFontSize   => 10,
        labelColor      => 'black',
        
    );

    return \%options;
}

#---------------------------------------------
sub draw {
    my $self    = shift;
    my $charts  = $charts{ id $self };

    # Plot the charts;
    foreach my $chart (@{ $charts }) {
        $chart->preprocessData;
    }

    # Preprocess data
    $self->preprocessData;

    # Plot background stuff
    $self->plotFirst;

    # Plot the charts;
    foreach my $chart (@{ $charts }) {
        $chart->plot( $self );
    }

    $self->plotLast;
}


#---------------------------------------------
sub get {
    my $self        = shift;
    my $key         = shift;
    my $properties  = $properties{ id $self };

    if ($key) {
        #### TODO: handle error and don't die?
        die "invalid key: [$key]" unless exists $properties->{ $key };
        return $properties->{ $key };
    }
    else {
        return { %{ $properties } };
    }
}

#---------------------------------------------
sub plotFirst {
    my $self    = shift;

#    foreach my $chart ( @{ $self->charts } ) {
#        $chart->plot( $self );
#    }
}

#---------------------------------------------
sub plotLast {
    my $self = shift;

    $self->text(
        text        => $self->get('title'),
        pointsize   => $self->get('titleFontSize'),
        font        => $self->get('titleFont'),
        fill        => $self->get('titleColor'),
        x           => $self->get('width') / 2,
        y           => 5,
        halign      => 'center',
        valign      => 'top',
    );
};

#---------------------------------------------
sub preprocessData {
    my $self = shift;
    
    # global
    my $axisWidth  = $self->get('width') - $self->get('marginLeft') - $self->get('marginRight');
    my $axisHeight = $self->get('height') - $self->get('marginTop') - $self->get('marginBottom');

    $self->plotOption( axisWidth    => $axisWidth   );
    $self->plotOption( axisHeight   => $axisHeight  );
    $self->plotOption( axisAnchorX  => $self->get('marginLeft') );
    $self->plotOption( axisAnchorY  => $self->get('marginTop')  );
}

#---------------------------------------------
sub set {
    my $self    = shift;
    my %update  = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    my $properties  = $properties{ id $self };

    while ( my ($key, $value) = each %update ) {
        if ( exists $properties->{ $key } ) {
            $properties->{ $key } = $value;
        }
    }
}

#---------------------------------------------
sub plotOption {
    my $self    = shift;
    my $option  = shift;
    my $value   = shift;

    $self->{ _plotOptions }->{ $option } = $value if ( defined $value );

    die "invalid plot option [$option]\n" unless exists $self->{ _plotOptions }->{ $option };

    return $self->{ _plotOptions }->{ $option };
}

#---------------------------------------------
sub transformToPixels {
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;

    return (
        int( $self->transformX( $x ) * $self->getPxPerXUnit ), 
        int( $self->transformY( $y ) * $self->getPxPerYUnit ),
    );
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
	my $self = shift;
	my %properties = @_;

    my %testProperties = %properties;
    delete $testProperties{align};
    delete $testProperties{style};
    delete $testProperties{fill};
    delete $testProperties{alignHorizontal};
    delete $testProperties{alignVertical};
    my ($x_ppem, $y_ppem, $ascender, $descender, $w, $h, $max_advance) = $self->im->QueryMultilineFontMetrics(%testProperties);

    # Convert the rotation angle to radians
    $properties{rotate} ||= 0;
    my $rotation = $properties{rotate} / 180 * pi;

	# Process horizontal alignment
    my $anchorX = 0;
	if ($properties{halign} eq 'center') {
        $anchorX = $w / 2;
	}
	elsif ($properties{halign} eq 'right') {
        $anchorX = $w;
	}

    # Using the align properties will cause IM to shift its anchor point. We'll have to compensate for that...
    if ($properties{align} eq 'Center') {
        $anchorX -= $w / 2;
    }
    elsif ($properties{align} eq 'Right') {
        $anchorX -= $w;
    }

    # IM aparently always anchors at the baseline of the first line of a text block, let's take that into account.
    my $lineHeight = $ascender;
    my $anchorY = $lineHeight;

	# Process vertical alignment
	if ($properties{valign} eq 'center') {
        $anchorY -= $h / 2;
	}
	elsif ($properties{valign} eq 'bottom') {
        $anchorY -= $h;
    }

    # Calc the the angle between the IM anchor and our desired anchor
    my $r       = sqrt( $anchorX**2 + $anchorY**2 );
    my $theta   = atan2( -$anchorY , $anchorX ); 

    # And from that angle we can translate the coordinates of the text block so that it will be alligned the way we
    # want it to.
    my $offsetY = $r * sin( $theta + $rotation );
    my $offsetX = $r * cos( $theta + $rotation );

    $properties{x} -= $offsetX;
    $properties{y} -= $offsetY;

	# We must delete these keys or else placement can go wrong for some reason...
	delete($properties{halign});
	delete($properties{valign});

    $self->im->Annotate(
		#Leave align => 'Left' here as a default or all text will be overcompensated.
		align		=> 'Left',
		%properties,
		gravity		=> 'Center', #'NorthWest',
		antialias	=> 'true',
#        undercolor  => 'red',
	);
}


1;

