package Chart::Magick;

use strict;
use warnings;

use Carp;
use Chart::Magick::Matrix;

our $VERSION = '0.1.0';

#--------------------------------------------------------------------
sub loadAndInstanciate {
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
    
    my $chart   = loadAndInstanciate( "Chart::Magick::Chart::$name" );
    croak "Cannot load class $chartClass" unless $chart;

    my $axis =
          ref     $params{ axisType }   ? $params{ axisType }
        : defined $params{ axisType }   ? loadAndInstanciate( "Chart::Magick::Axis::$params{ axisType }" )
        :                                 loadAndInstanciate( $chart->getDefaultAxisClass ) 
        ;
    croak "Cannot load axis class." unless $axis;

    foreach my $data ( @{ $params{data} } ) {
        $chart->addDataset( @{ $data } );
    }

    $axis->addChart( $chart );
    $axis->set( width => $params{ width }, height => $params{ height } );


    $chart->set(        $params{ chart  } || {} );
    $axis->set(         $params{ axis   } || {} );
    $axis->legend->set( $params{ legend } || {} ); 

    return $axis->draw;
}

#--------------------------------------------------------------------
sub matrix {
    my $self    = shift;
    my $width   = shift;
    my $height  = shift;
    my $layout  = shift;

    my $matrix  = Chart::Magick::Matrix->new( $width, $height, 20 );

    foreach my $row (@$layout) {
        my @row;

        foreach my $type ( @$row ) {
            my $class = "Chart::Magick::Axis::$type";

            my $ok = eval "require $class; 1";
            die "Cannot instanciate axis class $class because: $@" if !$ok || $@;

            push @row, [ $class->new(), 1 ]
        }

        push @{ $matrix->rows }, \@row;
    }

    return $matrix;
}

1;

