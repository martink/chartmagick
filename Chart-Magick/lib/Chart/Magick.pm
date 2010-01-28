package Chart::Magick;

use strict;
use warnings;

use Carp;
use Chart::Magick::Matrix;

our $VERSION = '0.1.0';

=head1 NAME

Chart::Magick

=head1 DESCRIPTION

A fully pluggable charting system using Image::Magick as backend. 

=head1 SYNOPSIS

use Chart::Magick;

my $chart = Chart::Magick->line(
    width   => 600,
    height  => 300,
    data    => [ 
        [ \@x1, \@y1 ],
        [ \@x2, \@y2 ],
    ],
);
$chart->write( 'line.png' );

my $bar  = Chart::Magick->bar(
    data    => [
        [ \@x1, \@y3 ],
    ],
);

$chart->add( $bar );
$chart->write( 'line_bar.png' );

=cut

=head1 USAGE

=head2 Introduction

Chart::Magick separates the actual graphs and the coordinate systems they are projected onto. Coordinate systems
are provided by the Chart::Magick::Axis classes while the visualization of the data is taken care of by the
classes in the Chart::Magick::Chart namespace. Data is provided through the Chart::Magick::Data abstraction layer
which allows for NxM dimensional data sets.

In terms of hierarchy data and palette are added to a chart and charts are added to an axis.

=head2 Code examples

Apart from the examples here in the pod there are a number of example scripts in the examples directory in the
distribution. 

=head2 Simple usage

Although Chart::Magick can be used by instanciating all of its components manually, it's often more convenient to
use the Chart::Magick class, which does a lot of work for you. Basically you create a new chart by 

    my $chart = Chart::Magick->chart_type(
        options
    );

where chart_type can be any of the Chart::Magick::Chart subclasses that are supplied with Chart::Magick. Options is
a hash with configuration data which is discussed below.

For instance, for a scatter plot, which is provided by Chart::Magick::Scatter, you'd use:

    my $scatter = Chart::Magick->scatter(
        options
    );

=head3 Configuration

The configuration may contain the following keys listed below. Note that these properties serve merely as overrides
for defaults: none of these keys have to be passed. However, a chart without any data might be not as informational
as you'd like, so the data property is required.

=over 4

=item width

The width of the chart in pixels. This property will be ignored when adding this chart to a matrix (see L<matrix>)
or another chart (see L<add>).

=height 

The height of the chart in pixels. This property will be ignored when adding this chart to a matrix (see L<matrix>)
or another chart (see L<add>).

=data

The data points to be plotted. Pass as an array ref of array refs. Each inner array ref has two elements which are
array refs containing coordinates and values respectively (eg. x and y values), and must have the same number of
elements.

For example:

    # Create some dummy data sets
    @x1     = ( 1, 2, 3     );
    @y1     = ( 2, 7, 19    );
    @x2     = ( 1, 4, 5, 7  );
    @y2     = ( 4, 8, 2, -1 );

    %config = (
        ...
        data => [
            [ \@x1, \@y1 ],
            [ \@x2, \@y2 ],
        ],
        ...
    );

=item chart

Hash ref containing directives to configure the chart object. The configuration properties that are available vary
from chart type to chart type. See the documentation of the definition method for the various
Chart::Magick::Chart::* modules for a list of available properties.

=item axis

Hash ref containing directives to configure the axis object. The configuration properties that are available vary
from axis type to axis type. See the documentation of the definition method for the various Chart::Magick::Axis::*
modules for a list of available properties.

=item legend

Hash ref containing directives to configure the legend of the chart. See the documentation of the definition method
for the Chart::Magick::Legend for a list of available properties.

=item palette

Array ref of hash refs containing the palette definition that you want to use.

=item labels

Array ref of hash refs. Each hash ref defines the labels for one axis in the chart in a value => label fashion.
Eg. (when the axis is Chart::Magick::Axis::Lin):

    [
        { 1 => 2009,    2 => 2010,                  },  # x labels
        { 0 => 'Bad', 2.5 => 'Avarage', 5 => 'Good' },  # y labels
    ]

Note that the hash ref to axis mapping depends is determined by the Chart::Magick::Axis plugin you use.

=item axisType

The Chart::Magick::Axis plugin you want to use to draw this chart. If ommitted the default axis defined by the
chart plugin will be used.

You can either pass a full class name, the classname without the Chart::Magick::Axis part or an instanciated
Chart::Magick::Axis object.

These are equivalent:

    %config = (
        axisType => 'LinLog',
    );

    %config = (
        axisType => 'Chart::Magick::Axis::LinLog',
    );

    $axis   = Chart::Magick::Axis::LinLog->new;
    %config = (
        axisType => $axis,
    );

=back

=cut

#--------------------------------------------------------------------
sub _loadAndInstanciate {
    my $class   = shift;
    my @params  = @_;

    my $result = eval "require $class; 1";

    unless ( $result ) {
        carp "Couldn't load class $class because $@";
        return;
    }

    my $instance = $class->new( @params );

    return $instance;
}

#--------------------------------------------------------------------
sub AUTOLOAD {
    my $class = shift;
	my %params = @_;
    
	our $AUTOLOAD;
	my $name = ucfirst( ( split( /::/, $AUTOLOAD ) )[-1] );

    my $chartClass = "Chart::Magick::Chart::$name";
    
    my $chart   = _loadAndInstanciate( "Chart::Magick::Chart::$name" );
    croak "Cannot load class $chartClass" unless $chart;

    my $axis =
          ref     $params{ axisType }   ? $params{ axisType }
        : defined $params{ axisType }   ? _loadAndInstanciate( "Chart::Magick::Axis::$params{ axisType }" )
        :                                 _loadAndInstanciate( $chart->getDefaultAxisClass ) 
        ;
    croak "Cannot load axis class." unless $axis;

    foreach my $data ( @{ $params{data} } ) {
        $chart->addDataset( @{ $data } );
    }

    if ( $params{ palette } ) {
        $chart->setPalette( $params{ palette } );
    }

    $axis->addChart( $chart );
    $axis->set( width => $params{ width }, height => $params{ height } );

    # Apply settings to chart, axis and legend.
    $chart->set(        $params{ chart  } || {} );
    $axis->set(         $params{ axis   } || {} );
    $axis->legend->set( $params{ legend } || {} ); 

    # Add labels to axis.
    my @labels  = @{ $params{labels} || [] };
    my $index   = 0;
    foreach my $set ( @labels ) {
        $axis->addLabels( $set, $index++ );
    }

    bless { _axis => $axis, _chart => $chart }, $class;
    #return $axis->draw;
}

#--------------------------------------------------------------------
=head2 axis ( )

Returns the Chart::Magick::Axis object for this chart.

=cut

sub axis {
    my $self = shift;

    return $self->{ _axis };
}

#--------------------------------------------------------------------

=head2 chart ( )

Returns the Chart::Magick::Chart object for this chart.

=cut

sub chart {
    my $self = shift;

    return $self->{ _chart };
}

#--------------------------------------------------------------------

=head2 add ( chart ) 

Adds another Chart::Magick chart to this chart. Use this method to make composite charts (eg. bars and lines).

=head3 chart

The instanciated Chart::Magick object to add.

=cut

sub add {
    my $self    = shift;
    my $chart   = shift;

    $self->axis->addChart( $chart->chart );
};

#--------------------------------------------------------------------

=head2 write ( filename )

Writes the chart to the file system. Image format is determined by the extension of the file.

=head3 filename

Full path plus filename to the location where the image should be written.

=cut

sub write {
    my $self        = shift;
    my $filename    = shift;

    $self->axis->write( $filename );
}

#--------------------------------------------------------------------

=head2 display ( )

Opens a window and displays the image. This uses the imagemagick Display method and thus imagemagick should be
compiled with the correct delegate for your windowing system for this to work (eg. --with-x11 on linux systems ).

Dies with an error if the display could not be opened.

=cut

sub display {
    my $self = shift;

    $self->axis->display;
}

#--------------------------------------------------------------------

=head2 matrix ( width, height, layout )

Takes multiple Chart::Magick objects and lays them out in a matrix. Returns a Chart::Magick::Matrix object. See
L<Chart::Magick::Matrix> for more detailed information on the stuff you can do with that.

Note that width and height you potentially pass to the individual Chart::Magick charts are ignored, as the matrix
calculates the dimensions of each chart by itself.

=head3 width

Width of the matrix canvas in pixels.

=head3 height

Height of the matrix canvas in pixels.

=head3 layout

Array ref of array refs. Each array ref represents a row in the matrix and each element must be an instaciated
Chart::Magick object. The number of charts may differ from row to row.

For example:

    Chart::Magick->matrix( 600, 300, [
        [ $chart1, $chart2, $chart3 ],
        [ $chart4                   ],
    ]);

generates a canvas whith three charts of about 200x150 pixels above a chart of about 600x150 pixels. Note that
there are margins between the charts so these dimension are slightly smaller.

=cut

sub matrix {
    my $self    = shift;
    my $width   = shift;
    my $height  = shift;
    my $layout  = shift;

    my $matrix  = Chart::Magick::Matrix->new( $width, $height, 20 );

    foreach my $row (@$layout) {
        push @{ $matrix->rows }, [ map { [ $_->axis, 1 ] } @{ $row } ];
    }

    return $matrix;
}

# Explicitly define DESTROY to prevent AUTOLOAD from trying to load Chart::Magick::Chart::DESTROY.
sub DESTROY {
    my $self = shift;
    undef $self->{ _chart   };
    undef $self->{ _axis    };
}

1;

