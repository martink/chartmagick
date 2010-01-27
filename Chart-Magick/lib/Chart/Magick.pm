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

=head2 USAGE

Although Chart::Magick can be used by instanciating all of its components manually, it's often more convenient to
use the Chart::Magick class, which does a lot of work for you. Basically you create a new chart by 

    my $chart = Chart::Magick->chart_type(
        options
    );

Where chart_type can be any of the Chart::Magick::Chart subclasses that are supplied with Chart::Magick.

For instance for a scatter plot, which is provided by Chart::Magick::Scatter, you'd use:

    my $scatter = Chart::Magick->scatter(
        options
    );



=cut

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

