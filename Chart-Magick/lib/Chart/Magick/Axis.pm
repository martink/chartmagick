package Chart::Magick::Axis;

use strict;
use warnings;

use Class::InsideOut qw{ :std };
use Chart::Magick::ImageMagick;
use List::Util qw{ min max };
use Carp;
use Data::Dumper;
use Text::Wrap;
use Chart::Magick::Legend;

use constant pi => 3.14159265358979;

use base qw{ Chart::Magick::Definition };

readonly charts         => my %charts;
private  plotOptions    => my %plotOptions;
readonly im             => my %magick;
private  axisLabels     => my %axisLabels;
readonly legend         => my %legend;
readonly isDrawn        => my %isDrawn;

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

    # We need to explicitly read an image for QueryFontMetrics and friends to work...
    # This temp image is deleted and replaced with the right canvas size in draw().
    my $image = Chart::Magick::ImageMagick->new( size=>'1x1' );
    $image->Read('xc:white');

    $magick{ $id        } = $image;
    $charts{ $id        } = [ ];
    $axisLabels{ $id    } = [ ];
    $legend{ $id        } = Chart::Magick::Legend->new( $self );
    $isDrawn{ $id       } = 0;

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

    return;
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

#--------------------------------------------------------------------
sub getChartHeight {
    my $self = shift;

    return $self->plotOption( 'axisHeight' );
    return $self->plotOption( 'axisHeight' ) - $self->get('marginTop') - $self->get('marginBottom');
}

#--------------------------------------------------------------------
sub getChartWidth {
    my $self = shift;

    return $self->plotOption( 'axisWidth' );
    return $self->plotOption( 'axisWidth' ) - $self->get('marginLeft') - $self->get('marginRight');
}

#--------------------------------------------------------------------
sub getLabelDimensions {
    my $self        = shift;
    my $label       = shift;
    my $wrapWidth   = shift || 0;

    return [ 0, 0 ] unless $label;

    my %properties = (
        text        => $label,
        font        => $self->get('labelFont'),
        pointsize   => $self->get('labelFontSize'),
    );

    my ($w, $h) = ( $self->im->QueryFontMetrics( %properties ) )[4,5];
    
    if ( $wrapWidth && $w > $wrapWidth ) {
        # This is not guaranteed to work in every case, but it'll do for now.
        local $Text::Wrap::columns = int( $wrapWidth / $w * length $label );
        $properties{ text } = join qq{\n}, wrap( q{}, q{}, $label );

        ($w, $h) = ( $self->im->QueryMultilineFontMetrics( %properties ) )[4,5];
    }

    return [ $w, $h ];
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
    return;
}

#----------------------------------------------

=head2 im ( )

Returns the Image::Magick object that is used for drawing. Will automatically create a new Image::Magick object if
this object has not been associated with one.

=cut

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

    return;
}

#---------------------------------------------
sub applyLayoutHints {
    return;
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
        margin          => 10,
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

        background      => 'xc:white',
        chartBackground => 'xc:none',
        drawLegend      => 1,
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

    # Delete tmp 1x1 pixel image ( see _buildObj )
    @{ $self->im } = ();

    # Prepare canvas of correct dimensions.
    $self->im->Set( size => $self->get('width') . 'x' . $self->get('height') );
    $self->im->Read( $self->get('background') );

    # Plot the charts;
    foreach my $chart (@{ $charts }) {
        $chart->setAxis( $self );
        $chart->preprocessData( ); #$self );
        $chart->addToLegend;

        $self->applyLayoutHints( $chart->layoutHints );
    }

    $self->legend->preprocess;

    # Preprocess data
    $self->preprocessData;

    foreach my $chart (@{ $charts }) {
        $chart->autoRange;
    }

    # Plot background stuff
    $self->plotFirst;

    my $chartCanvas = Chart::Magick::ImageMagick->new( size => $self->get('width') . 'x' . $self->get('height') );
    $chartCanvas->Read( $self->get('chartBackground') );

    # Plot the charts;
    foreach my $chart (@{ $charts }) {
        $chart->plot( $chartCanvas ); #$self );
    }

    $chartCanvas->Crop(
        x       => $self->plotOption('chartAnchorX') + 1,
        y       => $self->plotOption('chartAnchorY') + 1,
        width   => $self->getChartWidth - 1, # - 1,
        height  => $self->getChartHeight - 1,
    );

    $self->im->Composite(
        image   => $chartCanvas,
        gravity => 'NorthWest',
        x       => $self->plotOption('chartAnchorX') + 1,
        y       => $self->plotOption('chartAnchorY') + 1,
    );

    $self->plotLast;

    $isDrawn{ id $self } = 1;

    return $self->im;
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
    return;
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
    $self->legend->draw if $self->get('drawLegend');

    return;
};

#---------------------------------------------

=head2 plotTitle ( )

Plots the graph title, set by the title property.

=cut

sub plotTitle {
    my $self = shift;

    $self->im->text(
        text        => $self->get('title'),
        pointsize   => $self->get('titleFontSize'),
        font        => $self->get('titleFont'),
        fill        => $self->get('titleColor'),
        x           => $self->get('width') / 2,
        y           => $self->plotOption( 'titleOffset' ),
        halign      => 'center',
        valign      => 'top',
    );

    return;
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
    my $titleHeight = $self->get('title')
        ? ( $self->im->QueryFontMetrics( 
                text        => $self->get('title'),
                font        => $self->get('titleFont'),
                pointsize   => $self->get('titleFontSize'),
          ) )[ 5 ]
        : 0;

    # Adjust top margin to fit title
    my $marginTop   = max $self->get('marginTop'), $titleHeight + 2 * $minTitleMargin;
    my $titleOffset = max int ( ( $marginTop - $titleHeight ) / 2 ), $minTitleMargin;

    $self->set( 'marginTop', $marginTop );
    $self->plotOption( 'titleOffset', $titleOffset);
   
    if ( $self->get('drawLegend') ) {
        my @legendMargins = $self->legend->getRequiredMargins;
        $self->set( 
            marginLeft      => $self->get('marginLeft'  ) + $legendMargins[0],
            marginRight     => $self->get('marginRight' ) + $legendMargins[1],
            marginTop       => $self->get('marginTop'   ) + $legendMargins[2],
            marginBottom    => $self->get('marginBottom') + $legendMargins[3],
        );
    }

    # global
    my $axisWidth  = $self->get('width') - $self->get('marginLeft') - $self->get('marginRight');
    my $axisHeight = $self->get('height') - $self->get('marginTop') - $self->get('marginBottom');

    $self->plotOption( 
        axisWidth    => $axisWidth,
        axisHeight   => $axisHeight,
        chartAnchorX  => $self->get('marginLeft'),
        chartAnchorY  => $self->get('marginTop'),
    );


    return;
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
    my $self        = shift;
    my $coord       = shift;
    my $value       = shift;
    my $chartCoords = shift;
    
    return join ",", map { int } $self->project( $coord, $value ); #, $chartCoords );
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
    my ( $self, @options ) = @_;

    # No params? Return a safe copy of all plot options.
    return { %{ $self->{ _plotOptions } } } unless scalar @options;

    # More than one param? Apply the passed key/value pairs on the plot options.
    if ( scalar @options > 1 ) {
        $self->{ _plotOptions } = { %{ $self->{ _plotOptions } }, @options };
        return ;
    }

    my $option = $options[0];

    # Uncomment line below when debuggingis finished.
    # return $self->{ _plotOptions }->{ $option };

    croak "invalid plot option [$option]\n" unless exists $self->{ _plotOptions }->{ $option };
    
    return $self->{ _plotOptions }->{ $option };
}

#-------------------------------------------------------------------

=head2 project ( coord, value )

Projects a coord/value pair onto the canvas and returns the x/y pixel values of the projection.

Each Axis plugin must overload this method.

=head3 coord

Arrayref containing the coord.

=head3 value

Arrayref containing the value, corresponding to the coord.

=cut

sub project {
    croak "Chart::Magick::Axis->project must be overloaded by sub class";
}

#-------------------------------------------------------------------

=head2 write ( filename )

Writes the chart and its charts to a file.

=head3 filename

Full path to the file to which the chart must be written.

=cut

sub write {
    my $self        = shift;
    my $filename    = shift || croak 'No filename passed';

    $self->draw unless $self->isDrawn;

    my $error = $self->im->Write( $filename );

    croak "Could not write file $filename because $error" if $error;

    return;
}

sub display {
    my $self        = shift;

    $self->draw unless $self->isDrawn;

    my $error = $self->im->Display;

    croak "Could not open display because $error" if $error;

    return;
}

1;

