package Chart::Magick::Axis;

use strict;
use warnings;

####use Class::InsideOut qw{ :std };
use Chart::Magick::ImageMagick;
use List::Util qw{ min max };
use Carp;
use Data::Dumper;
use Text::Wrap;
use Chart::Magick::Legend;
use Moose;
use MooseX::SlaveAttribute;

use constant pi => 3.14159265358979;

####use base qw{ Chart::Magick::Definition };


sub _setupMagickObject {
    my $image = Chart::Magick::ImageMagick->new( size => '1x1' );
    $image->Read( 'xc:white' );
   
    return $image;
}

has charts => (
    is      => 'ro',
    default => sub { [] },
    traits  => [ 'Array' ],
    isa     => 'ArrayRef[Chart::Magick::Chart]',
    handles => {
        addChart    => 'push',
    },
);

has plotOptions => (
    is      => 'rw',
    default => sub { {} },
    isa     => 'HashRef',
);

has im => (
    is      => 'ro',
    isa     => 'Image::Magick',
    builder => '_setupMagickObject',
);

has axisLabels => (
    is      => 'ro',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
);

# TODO: Prolly we need a trigger here that passes $self to the legend that is being set. That, or we make this ro.
has legend => (
    is      => 'rw',
    isa     => 'Chart::Magick::Legend',
    default => sub { Chart::Magick::Legend->new( shift ) },
);

# TODO: Turn this ro.
has isDrawn => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head1 NAME

Chart::Magick::Axis - Base class for coordinate systems to draw charts on.

=head1 SYNOPSIS

my $axis = Chart::Magick::Axis->new();

=head1 DESCRIPTION

The chart modules within the Chart::Magick system draw onto Axis objects, which derive from this base class.

#---------------------------------------------

=head1 PROPERTIES

Chart::Magick::Axis define their properties:

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

# Image dimensions
has width => (
    is      => 'rw',
    default => 400,
);
has height => (
    is      => 'rw',
    default => 300,
);

# Image margins
has margin => (
    is      => 'rw',
    default => 10,
);
has marginLeft => (
    is      => 'rw',
    traits  => ['Slave'],
    master  => 'margin',
    # default => sub { $_[0]->get('margin') },
);    
has marginTop  => ( 
    is      => 'rw',
    traits  => ['Slave'],
    master  => 'margin',
    # default => sub { $_[0]->get('margin') },
);
has marginRight => (
    is      => 'rw',
    traits  => ['Slave'],
    master  => 'margin',
    # default => sub { $_[0]->get('margin') },
);
has marginBottom => (
    is      => 'rw',
    traits  => ['Slave'],
    master  => 'margin',
    # default => sub { $_[0]->get('margin') },
);

# Default font settings
has font => (
    is      => 'rw',
    isa     => 'MagickFont',
    default => 'Courier',
);
has fontSize => (
    is      => 'rw',
    default => 10,
);
has fontColor => (
    is      => 'rw',
    default => 'black',
);

# Title settings
has title => (
    is      => 'rw',
    default => '',
);
has titleFont => (
    is      => 'rw',
    isa     => 'MagickFont',
    traits  => ['Slave'],
    master  => 'font',
    # default => sub { $_[0]->get('font') }, 
);
has titleFontSize => (
    is      => 'rw',
    traits  => ['Slave'],
    master  => 'fontSize',
    # default => sub { $_[0]->get('fontSize') * 3 },
);
has titleColor => (
    is      => 'rw',
    traits  => ['Slave'],
    master  => 'fontColor',
    # default => sub { $_[0]->get('fontColor') },
);
has minTitleMargin => (
    is      => 'rw',
    default => 5,
);

# Label settings
has labelFont => (
    is      => 'rw',
    isa     => 'MagickFont',
    traits  => ['Slave'],
    master  => 'font',
    # default => sub { $_[0]->get('font') }, 
);
has labelFontSize => (
    is      => 'rw',
    traits  => ['Slave'],
    master  => 'fontSize',
    # default => sub { $_[0]->get('fontSize') },
);
has labelColor => (
    is      => 'rw',
    traits  => ['Slave'],
    master  => 'fontColor',
    # default => sub { $_[0]->get('fontColor') },
);

has background => (
    is      => 'rw',
    default => 'xc:white',
);
has chartBackground => (
    is      => 'rw',
    default => 'xc:none',
);
has drawLegend => (
    is      => 'rw',
    default => 1,
);








=head1 METHODS

These methods are available from this class:

=cut

#----------------------------------------------

####sub _buildObject {
####    my $class       = shift;
####    my $self        = {};
####
####    bless       $self, $class;
####    register    $self;
####
####    my $id = id $self;
####
####    # We need to explicitly read an image for QueryFontMetrics and friends to work...
####    # This temp image is deleted and replaced with the right canvas size in draw().
#####    my $image = Chart::Magick::ImageMagick->new( size=>'1x1' );
#####    $image->Read('xc:white');
####
#####    $magick{ $id        } = $image;
#####    $charts{ $id        } = [ ];
#####    $axisLabels{ $id    } = [ ];
#####    $legend{ $id        } = Chart::Magick::Legend->new( $self );
#####    $isDrawn{ $id       } = 0;
####
#####    $self->{ _plotOptions } = {};
####    return $self;
####}

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

    my $currentLabels = $self->axisLabels->[ $index ] || {};

    $self->axisLabels->[ $index ] = {
        %{ $currentLabels   },
        %{ $newLabels       },
    };

    return;
}

#----------------------------------------------

=head2 resolveFont ( font )

Check whether the given font can actually be found by ImageMagick. Testing this is important because passin IM
invalid fontnames or locations will slow the program down to the extreme.

=head3 font

Either the full path to the font or the font name as ImageMagick knows it.

=cut

sub resolveFont {
    my $self = shift;
    my $font = shift;
   
    # We don't know wheter the font is a direct path or a font name, so first let's see if it is an existing file.
    return $font if -e $font;

    # It's not a file so maybe it's a font name, let's ask IM and see if it resolves the font to an existing file.
    my $file = $self->im->QueryFont( $font );
    return $file if -e $file;

    # Otherwise return false.
    return
}

#--------------------------------------------------------------------

=head2 getChartHeight ( )

Returns the height of the chart in pixels.

=cut

sub getChartHeight {
    my $self = shift;

    return $self->plotOption( 'axisHeight' );
    return $self->plotOption( 'axisHeight' ) - $self->marginTop - $self->marginBottom;
}

#--------------------------------------------------------------------

=head2 getChartWidth {

Returns the width of chart in pixels.

=cut

sub getChartWidth {
    my $self = shift;

    return $self->plotOption( 'axisWidth' );
    return $self->plotOption( 'axisWidth' ) - $self->marginLeft - $self->marginRight;
}

#--------------------------------------------------------------------

=head2 getLabelDimensions ( label, wrapWidth )

Returns an arrayref containing the width and height of label wrapped to the given width.

=head3 label

The label to calculate the dimensions of.

=head3 wrapWidth

The width in pixels to which the label should be wrapped before calculation its dimensions.

=cut

sub getLabelDimensions {
    my $self        = shift;
    my $label       = shift;
    my $wrapWidth   = shift || 0;

    return [ 0, 0 ] unless $label;

    if ( exists $self->{ _labeldims }{ $label }{ $wrapWidth } ) {
        return $self->{ _labeldims }{ $label }{ $wrapWidth };
    }

    my %properties = (
        text        => $label,
        font        => $self->labelFont,
        pointsize   => $self->labelFontSize,
    );

    my ($w, $h) = ( $self->im->QueryFontMetrics( %properties ) )[4,5];
    
    if ( $wrapWidth && $w > $wrapWidth ) {
        # This is not guaranteed to work in every case, but it'll do for now.
        local $Text::Wrap::columns = int( $wrapWidth / $w * length $label );
        $properties{ text } = join qq{\n}, wrap( q{}, q{}, $label );

        ($w, $h) = ( $self->im->QueryMultilineFontMetrics( %properties ) )[4,5];
    }

    $self->{ _labeldims }{ $label }{ $wrapWidth } = [ $w, $h ];

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

    my $labels  = $self->axisLabels->[ $index ];

    return { %{ $labels } }     unless defined $coord;
    return $labels->{ $coord }  if exists $labels->{ $coord };
    return;
}

#----------------------------------------------

=head2 inRange ( ) 

=cut

sub inRange {
    my $self = shift;
    my $coord = shift;
    my $value = shift;

    return $self->coordInRange( $coord ) && $self->valueInRange( $value );
}

sub coordInRange {
    return 1;
}

sub valueInRange {
    return 1;
}

#----------------------------------------------

=head2 im ( )

Returns the Image::Magick object that is used for drawing. Will automatically create a new Image::Magick object if
this object has not been associated with one.

=cut

#####----------------------------------------------
####
####=head2 new ( [ properties ] )
####
####Constructor for this class.
####
####=head3 properties
####
####Properties to initially configure the object. For available properties, see C<definition()>
####
####=cut
####
####sub new {
####    my $class       = shift;
####    my $properties  = shift || {};
####   
####    my $self = $class->_buildObject;
####    $self->initializeProperties( $properties );
####
####    return $self;
####}

#####---------------------------------------------
####
####=head2 addChart ( chart, [ chart, [ chart, ... ] ] )
####
####Adds one or more chart(s) to this axis.
####
####=head3 chart
####
####An instantiated Chart::Magick::Chart object.
####
####=cut
####
####sub addChart {
####    my $self    = shift;
####
####    while ( my $chart = shift ) {
####        croak "Cannot add a chart of class $chart to an Axis. All charts mus be isa('Chart::Magick::Chart')." 
####            unless $chart->isa('Chart::Magick::Chart');
####        push @{ $charts{ id $self } }, $chart;
####    }
####
####    return;
####}

#---------------------------------------------

=head2 applyLayoutHints ( hints )

Layout hints are suggestions of Chart plugins to the Axis object to change the values of some of its properties. It
is up to the Axis plugin to do something with these suggestions, but it doesn't have to.

If you subclass can handle some of these hints you should extend this method and process them here.

=head3 hints

Hashref containing the the hints and their value in a hint => value key/value pairs/

=cut

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

=head2 draw ( )

Draws the axis and all charts that are put onto it.

=cut

sub draw {
    my $self    = shift;
####    my $charts  = $charts{ id $self };
    my $charts  = $self->charts;

    # Save state.
#    my $config          = $self->getRaw;
#    my $legendConfig    = $self->legend->getRaw;

    # Delete tmp 1x1 pixel image ( see _buildObj )
    @{ $self->im } = ();

    # Prepare canvas of correct dimensions.
    $self->im->Set( size => $self->width . 'x' . $self->height );
    $self->im->Read( $self->background );

    # Plot the charts;
    foreach my $chart (@{ $charts }) {
        $chart->axis( $self );
        $chart->preprocessData( );
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

    my $chartCanvas = Chart::Magick::ImageMagick->new( size => $self->width . 'x' . $self->height );
    $chartCanvas->Read( $self->chartBackground );

    # Plot the charts;
    foreach my $chart (@{ $charts }) {
        $chart->plot( $chartCanvas );
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

    $self->isDrawn( 1 );

    # Restore state
#    $self->set( $config );
#    $self->legend->set( $legendConfig );

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
    $self->legend->draw if $self->drawLegend;

    return;
};

#---------------------------------------------

=head2 plotTitle ( )

Plots the graph title, set by the title property.

=cut

sub plotTitle {
    my $self = shift;

    $self->im->text(
        text        => $self->title,
        pointsize   => $self->titleFontSize,
        font        => $self->titleFont,
        fill        => $self->titleColor,
        x           => $self->width / 2,
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
# Getter gaat mis hierrrr!! Maar dit moet naar een type!
#        my $font = $self->resolveFont( $self->$_ );
#
#        croak "Font $font (property $_) does not exist or is defined incorrect in the ImageMagick configuration file." 
#            unless $font;
#
#        # Replace the possible font name with its full path. This speeds up annotating significantly!
# Setter gaat ook mis.
#        $self->$_($font );
    }
   
    # Calc title height
    my $minTitleMargin  = $self->minTitleMargin;
    my $titleHeight = $self->title
        ? ( $self->im->QueryFontMetrics( 
                text        => $self->title,
                font        => $self->titleFont,
                pointsize   => $self->titleFontSize,
          ) )[ 5 ]
        : 0;

    # Adjust top margin to fit title
    my $marginTop   = max $self->marginTop, $titleHeight + 2 * $minTitleMargin;
    my $titleOffset = max int ( ( $marginTop - $titleHeight ) / 2 ), $minTitleMargin;

    $self->marginTop( $marginTop );
    $self->plotOption( 'titleOffset', $titleOffset);
   
    if ( $self->drawLegend ) {
        my @legendMargins = $self->legend->getRequiredMargins;

        $self->marginLeft(      $self->marginLeft   + $legendMargins[0] );
        $self->marginRight(     $self->marginRight  + $legendMargins[1] );
        $self->marginTop(       $self->marginTop    + $legendMargins[2] );
        $self->marginBottom(    $self->marginBottom + $legendMargins[3] );
    }

    # global
    my $axisWidth  = $self->width - $self->marginLeft - $self->marginRight;
    my $axisHeight = $self->height - $self->marginTop - $self->marginBottom;

    $self->plotOption( 
        axisWidth    => $axisWidth,
        axisHeight   => $axisHeight,
        chartAnchorX  => $self->marginLeft,
        chartAnchorY  => $self->marginTop,
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
    return { %{ $self->plotOptions } } unless scalar @options;

    # More than one param? Apply the passed key/value pairs on the plot options.
    if ( scalar @options > 1 ) {
        $self->plotOptions( { %{ $self->plotOptions }, @options } );
        return ;
    }

    my $option = $options[0];

    # Uncomment line below when debuggingis finished.
    # return $self->plotOptions->{ $option };

    croak "invalid plot option [$option]\n" unless exists $self->plotOptions->{ $option };
    
    return $self->plotOptions->{ $option };
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

#-------------------------------------------------------------------

=head2 display ( )

Opens a window and displays the chart in it. The window is opened by the Imagemagick Display method and therefore
imagemagick must be compiled to include the risght delegate library for this.

Croaks if no windows could be opened.

=cut

sub display {
    my $self        = shift;

    $self->draw unless $self->isDrawn;

    my $error = $self->im->Display;

    croak "Could not open display because $error" if $error;

    return;
}

1;

