package Chart::Magick::Axis;

use strict;
use Class::InsideOut qw{ :std };
use Image::Magick;
use List::Util qw{ min max };
use Carp;
use Data::Dumper;
use Text::Wrap;

use constant pi => 3.14159265358979;

use base qw{ Chart::Magick::Definition };

readonly charts         => my %charts;
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
    my $self        = {};

    bless       $self, $class;
    register    $self;

    my $id = id $self;

    $charts{ $id }      = [];
    $axisLabels{ $id }  = [ ];

    $self->{ _plotOptions } = {};
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

=head2 checkFont ( font )

Check whether the given font can actually be found by ImageMagick. Testing this is important because passin IM
invalid fontnames or locations will slow the program down to the extreme.

=head3 font

Either the full path to the font or the font name as ImageMagick knows it.

=cut

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
   
    my $self = $class->_buildObject;
    $self->initializeProperties( $properties );

    return $self;
}

#---------------------------------------------

=head2 addChart ( chart, [ chart, [ chart, ... ] ] )

Adds one or more chart(s) to this axis.

=head3 chart

An instantiated Chart::Magick::Chart object.

=cut

sub addChart {
    my $self    = shift;

    while ( my $chart = shift ) {
        croak "Cannot add a chart of class $chart to an Axis. All charts mus be isa('Chart::Magick::Chart')." 
            unless $chart->isa('Chart::Magick::Chart');
        push @{ $charts{ id $self } }, $chart;
    }
}

#---------------------------------------------

=head2 charts ( ) 

Returns an array ref containing the charts that have been added to this axis.

=cut

#---------------------------------------------

=head2 getCoordDimension ( )

Returns the dimension (ie. the number of components) of a coordinate in this axis.

=cut

sub getCoordDimension {
    return 0;
}

#---------------------------------------------

=head2 getValueDimension ( )

Returns the dimension (ie. the number of components) of a value in this axis.

=cut

sub getValueDimension {
    return 0;
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
        # Image dimensions
        width           => 400,
        height          => 300,

        # Image margins
        margin          => 30,
        marginLeft      => sub { $_[0]->get('margin') },
        marginTop       => sub { $_[0]->get('margin') }, 
        marginRight     => sub { $_[0]->get('margin') },
        marginBottom    => sub { $_[0]->get('margin') },

        # Default font settings
        font            => 'Courier',
        fontSize        => 10,
        fontColor       => 'black',

        # Title settings
        title           => '',
        titleFont       => sub { $_[0]->get('font') }, 
        titleFontSize   => sub { $_[0]->get('fontSize') * 3 },
        titleColor      => sub { $_[0]->get('fontColor') },
        minTitleMargin  => 5,

        # Label settings
        labelFont       => sub { $_[0]->get('font') }, 
        labelFontSize   => sub { $_[0]->get('fontSize') },
        labelColor      => sub { $_[0]->get('fontColor') },
        
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
        $chart->setAxis( $self );
        $chart->preprocessData( ); #$self );
    }

    # Preprocess data
    $self->preprocessData;

    # Plot background stuff
    $self->plotFirst;

    # Plot the charts;
    foreach my $chart (@{ $charts }) {
        $chart->plot( ); #$self );
    }

    $self->plotLast;
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
}

#---------------------------------------------

=head2 plotLast ( )

This method is called in the last phase of the drawing procedure. Extend it if you need to draw stuff in this
phase.

You'll probably never call this method by yourself.

=cut

sub plotLast {
    my $self = shift;

    $self->plotTitle;
};

#---------------------------------------------

=head2 plotTitle ( )

Plots the graph title, set by the title property.

=cut

sub plotTitle {
    my $self = shift;

    $self->text(
        text        => $self->get('title'),
        pointsize   => $self->get('titleFontSize'),
        font        => $self->get('titleFont'),
        fill        => $self->get('titleColor'),
        x           => $self->get('width') / 2,
        y           => $self->plotOption( 'titleOffset' ),
        halign      => 'center',
        valign      => 'top',
    );
}

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
   
    # Calc title height
    my $minTitleMargin  = $self->get('minTitleMargin');
    my $titleHeight = [ 
        $self->im->QueryFontMetrics( 
            text        => $self->get('title'),
            font        => $self->get('titleFont'),
            pointsize   => $self->get('titleFontSize'),
        )
    ]->[ 5 ];

    # Adjust top margin to fit title
    my $marginTop   = max $self->get('marginTop'), $titleHeight + 2 * $minTitleMargin;
    my $titleOffset = max int ( ( $marginTop - $titleHeight ) / 2 ), $minTitleMargin;

    $self->set( 'marginTop', $marginTop );
    $self->plotOption( 'titleOffset', $titleOffset);

    # global
    my $axisWidth  = $self->get('width') - $self->get('marginLeft') - $self->get('marginRight');
    my $axisHeight = $self->get('height') - $self->get('marginTop') - $self->get('marginBottom');

    $self->plotOption( 
        axisWidth    => $axisWidth,
        axisHeight   => $axisHeight,
        axisAnchorX  => $self->get('marginLeft'),
        axisAnchorY  => $self->get('marginTop'),
    );
}

#-------------------------------------------------------------------

=head2 toPx ( coords, values )

Shorthand method that calls the project method and returns the x and y value joined by a comma as scalar. This
string can be directly used in ImageMagick path definitions.

=head3 coords

Array ref containing the coordinates of the spot to be projected.

=head3 value

Array ref containing the values of the spot to be projected.

=cut

sub toPx {
    my $self    = shift;
    
    return join ",", map { int } $self->project( @_ );
}

#---------------------------------------------

=head2 plotOption ( key, value )

Plot options are values and numbers that are used for plotting the graph and are automatically calculated by the
Axis plugins.

If no parameters are passed a safe copy of the plot options hash is returned.

=head3 key

Plot option name.

=head3 value

Plot option value.

=cut

sub plotOption {
    my $self    = shift;

    # No params? Return a safe copy of all plot options.
    return { %{ $self->{ _plotOptions } } } unless scalar @_;

    # More than one param? Apply the passed key/value pairs on the plot options.
    if ( scalar @_ > 1 ) {
        $self->{ _plotOptions } = { %{ $self->{ _plotOptions } }, @_ };
        return ;
    }

    # Uncomment line below when debuggingis finished.
    # return $self->{ _plotOptions }->{ $_[0] };

    my $option = shift;
    croak "invalid plot option [$option]\n" unless exists $self->{ _plotOptions }->{ $option };
    
    return $self->{ _plotOptions }->{ $option };
}

#-------------------------------------------------------------------

sub project {
    croak "Chart::Magick::Axis->project must be overloaded by sub class";
}

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
    my $textWidth   = [ $self->im->QueryFontMetrics( %properties ) ]->[4];
 
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

    return unless length $prop{ text };

    # Wrap text if necessary
    $prop{ text } = $self->wrapText( %prop ) if $prop{ wrapWidth };

    # Find width and height of resulting text block
    my ( $ascender, $width, $height ) = ( $self->im->QueryMultilineFontMetrics( %prop ) )[ 2, 4, 5 ];

	# Process horizontal alignment
    my $anchorX  =
          $prop{ halign } eq 'center'   ? $width / 2
        : $prop{ halign } eq 'right'    ? $width
        : 0;

    # Using the align properties will cause IM to shift its anchor point. We'll have to compensate for that...
    $anchorX     -=
          !defined $prop{ align }       ? 0
        : $prop{ align }  eq 'Center'   ? $width / 2
        : $prop{ align }  eq 'Right'    ? $width
        : 0;


    # IM aparently always anchors at the baseline of the first line of a text block, let's take that into account.
    my $anchorY =
          $prop{ valign } eq 'center'   ? $ascender - $height / 2
        : $prop{ valign } eq 'bottom'   ? $ascender - $height
        : $ascender;

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

    $self->im->Annotate(
		#Leave align => 'Left' here as a default or all text will be overcompensated.
		align		=> 'Left',
		%prop,
		gravity		=> 'Center', #'NorthWest',
		antialias	=> 'true',
	);
}

1;

