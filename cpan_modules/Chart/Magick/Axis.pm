package Chart::Magick::Axis;

use strict;
use Class::InsideOut qw{ :std };
use Image::Magick;
use List::Util qw{ min max };
use Carp;
use Data::Dumper;

use constant pi => 3.14159265358979;

readonly charts         => my %charts;
private  properties     => my %properties;
private  plotOptions    => my %plotOptions;
private  im             => my %magick;
private  axisLabels     => my %axisLabels;

=head1 NAME

Chart::Magick::Axis - Base class for coordinate systems to draw charts on.

=head1 SYNOPSIS

my $axis = Chart::Magick::Axis->new();

=head1 DESCRIPTION

The chart modules within the Chart::Magick system draw onto Axis objects, which derive from this base class.

=head1 METHODS

These methods are available from this class:

=cut

#----------------------------------------------
sub _buildObject {
    my $class       = shift;
    my $properties  = shift;
    my $magick      = shift;
    my $self        = {};

    bless       $self, $class;
    register    $self;

    my $id = id $self;

    $charts{ $id }      = [];
    $properties{ $id }  = { %{ $self->definition }, %{ $properties } } || {};
    $axisLabels{ $id }  = [ ];

    return $self;
}

#----------------------------------------------
=head2 addLabels ( labels, [ axisIndex ] )

Adds labels for an axis identified by axisIndex. Labels are passed as a hashref in which the keys indicate the
location on the axis of the label which is passed as the value.

Which axis is tied to which value of axisIndex is defined by each Axis plugin. See the docs of the plugin you're
using. In general, though, the axisIndex is ordered logically. eg for a xy coordinate system it's logical to have
x = 0 and y = 1.

=over 4

=item labels

A hashref containing the labels belonging to axis values. Use the form:

    {
        value   => label,
        value   => label,
        ...
        value   => label,
    }

=item axisIndex

Defines which axis you are adding labels for. See documentation of the Axis plugin you are using which axis is tied
to which axisIndex. Default to 0.

=back

=cut

sub addLabels {
    my $self        = shift;
    my $newLabels   = shift;
    my $index       = shift || 0;

    my $currentLabels = $axisLabels{ id $self }->[ $index ] || {};

    $axisLabels{ id $self }->[ $index ] = {
        %{ $currentLabels   },
        %{ $newLabels       },
    };
}

#----------------------------------------------

sub checkFont {
    my $self = shift;
    my $font = shift;
   
    # We don't know wheter the font is a direct path or a font name, so first let's see if it is an existing file.
    return 1 if -e $font;

    # It's not a file so maybe it's a font name, let's ask IM and see if it resolves the font to an existing file.
    return -e $self->im->QueryFont( $font );
}


#----------------------------------------------

=head2 getLabels ( [ axisIndex, value ] )

Returns either a hashref of all labels tied to an axis or the label at a specific value of the selected axis.

=over 4

=item axisIndex

The axis you are retrieving labels for. See the documentation of the Axis plugin you're using to see to what index
each axis is mapped. Defaults to 0.

=item value

If passed the label at this value for the selected axis is returned. If no label is defined at this point, undef is
returned. If omitted, a hashref containing all value/label pairs on the selected axis is returned.

=back

=cut

sub getLabels {
    my $self    = shift;
    my $index   = shift || 0;
    my $coord   = shift;

    my $labels  = $axisLabels{ id $self }->[ $index ];

    return { %{ $labels } }     unless defined $coord;
    return $labels->{ $coord }  if exists $labels->{ $coord };
    return undef;
}

#----------------------------------------------
=head2 im ( )

Returns the Image::Magick object that is used for drawing. Will automatically create a new Image::Magick object if
this object has not been associated with one.

=cut

sub im {
    my $self = shift;

    my $im = $magick{ id $self };
    return $im if $im;

    my $width   = $self->get('width')   || croak "no height";
    my $height  = $self->get('height')  || croak "no width";
    my $magick  = Image::Magick->new(
        size        => $width.'x'.$height,
    );
    $magick->Read('xc:white');
    $magick{ id $self } = $magick;

    return $magick;
}

#----------------------------------------------
=head2 new ( [ properties ] )

Constructor for this class.

=head3 properties

Properties to initially configure the object. For available properties, see C<definition()>

=cut

sub new {
    my $class       = shift;
    my $properties  = shift || {};
    
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

    push @{ $charts{ id $self } }, $chart;
}

#---------------------------------------------

=head2 definition ( )

Chart::Magick::Axis define their properties and default values in this this method. Returns a hash ref.

The following properties can be set:

=over 4

=item width

The width of the coordinate system in pixels.

=item height

The height of the coordinate system in pixels.

=item marginLeft
=item marginTop
=item marginRight
=item marginBottom

The width of the left, top, right and bottom margin in pixels respectively.

=item title

The title of the chart.

=item titleFont

The font in which the chart title should be rendered.

=item titleFontSize

The font size of the chart title.

=item titleColor

The font title color.

=item labelFont
=item labelFontSize
=item labelColor

The font, font size and color in which the axis labels should be rendered.

=back

=cut 

sub definition {
    my $self = shift;

    my %options = (
        width           => 400,
        height          => 300,

        marginLeft      => 40,
        marginTop       => 50,
        marginRight     => 20,
        marginBottom    => 20,

        title           => 'Ze Title',
        titleFont       => 'Courier', #'/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
        titleFontSize   => 20,
        titleColor      => 'purple',

        labelFont       => 'DejaVuSans', #'/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
        labelFontSize   => 10,
        labelColor      => 'black',
        
    );

    return \%options;
}

#---------------------------------------------
=head2 draw ( )

Draws the axis and all charts that are put onto it.

=cut

sub draw {
    my $self    = shift;
    my $charts  = $charts{ id $self };

    # Plot the charts;
    foreach my $chart (@{ $charts }) {
        $chart->preprocessData( $self );
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

=head2 get ( [ property ] )

Returns a hash ref of all properties in the Axis object. If a specific property is passed only the value belong to
that property is returned.

=head3 property

The property whose value should be returned.

=cut 

sub get {
    my $self        = shift;
    my $key         = shift;
    my $properties  = $properties{ id $self };

    if ($key) {
        #### TODO: handle error and don't croak?
        croak "invalid key: [$key]" unless exists $properties->{ $key };
        return $properties->{ $key };
    }
    else {
        return { %{ $properties } };
    }
}

#---------------------------------------------

=head2 getDataRange ( )

Returns an array ref containing the lower and upper bounds of the coordinates and values the charts require. Note
that these four array elements are all arrayref containing data for each dimension in the coordinate and value
spaces.

=cut

sub getDataRange {
    my $self = shift;
    my ( @minCoord, @maxCoord, @minValue, @maxValue );

    my @extremes = map { [ $_->getDataRange ] } @{ $self->charts };

    for my $i ( 0 .. $self->getCoordDimension - 1 ) {
        push @minCoord, min map { $_->[ 0 ]->[ $i ] } @extremes;
        push @maxCoord, max map { $_->[ 1 ]->[ $i ] } @extremes;
    }
    for my $i ( 0 .. $self->getValueDimension - 1 ) {
        push @minValue, min map { $_->[ 2 ]->[ $i ] } @extremes;
        push @maxValue, max map { $_->[ 3 ]->[ $i ] } @extremes;
    }
     
    return ( \@minCoord, \@maxCoord, \@minValue, \@maxValue );
}

#---------------------------------------------

=head2 plotFirst ( )

This method is executed in the first phase of the drawing procedure. Extend it if you need to draw stuff in this
phase.

You'll probably never call this method by yourself.

=cut

sub plotFirst {
    my $self    = shift;
}

#---------------------------------------------

=head2 plotLast ( )

This method is called in the last phase of the drawing procedure. Extend it if you need to draw stuff in this
phase.

You'll probably never call this method by yourself.

=cut

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

=head2 preprocessData ( )

This method is used to massage data and plotting properties into something plottable. It is automatically called
prior to drawing the axis. Extend this method if your module needs some data massaging too.

=cut

sub preprocessData {
    my $self = shift;

    # Check if the fonts are actually findable. If not IM slows down incredibly and will not draw labels so bail
    # out in that case.
    for ( qw{ titleFont labelFont } ) { 
        my $font = $self->get( $_ );
        croak "Font $font (property $_) does not exist or is defined incorrect in the ImageMagick configuration file." 
            unless $self->checkFont( $font );
    }
    
    # global
    my $axisWidth  = $self->get('width') - $self->get('marginLeft') - $self->get('marginRight');
    my $axisHeight = $self->get('height') - $self->get('marginTop') - $self->get('marginBottom');

    $self->plotOption( axisWidth    => $axisWidth   );
    $self->plotOption( axisHeight   => $axisHeight  );
    $self->plotOption( axisAnchorX  => $self->get('marginLeft') );
    $self->plotOption( axisAnchorY  => $self->get('marginTop')  );
}

#---------------------------------------------

=head2 set ( properties )

Applies the passed properties to this object.

head3 properties

Either a hash or a hash ref containing the property names as keys and intended values as values.

=cut

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

=head2 plotOption ( key, value )

Plot options are values and numbers that are used for plotting the graph and are automatically calculated by the
Axis plugins.

=head3 key

Plot option name.

=head3 value

Plot option value.

=cut

sub plotOption {
    my $self    = shift;
    my $option  = shift;
    my $value   = shift;

    if ( defined $value ) {
        $self->{ _plotOptions }->{ $option } = $value;
    }
    else {
        croak "invalid plot option [$option]\n" unless exists $self->{ _plotOptions }->{ $option };
    }

    return $self->{ _plotOptions }->{ $option };
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

