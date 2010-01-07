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
sub axis {
    my $self = shift;

    return $self->{ _axis };
}

#--------------------------------------------------------------------
sub chart {
    my $self = shift;

    return $self->{ _chart };
}

#--------------------------------------------------------------------
sub add {
    my $self    = shift;
    my $chart   = shift;

    $self->axis->addChart( $chart->chart );
};

#--------------------------------------------------------------------
sub write {
    my $self        = shift;
    my $filename    = shift;

    $self->axis->write( $filename );
}

#--------------------------------------------------------------------
sub display {
    my $self = shift;

    $self->axis->display;
}

#--------------------------------------------------------------------
sub matrix {
    my $self    = shift;
    my $width   = shift;
    my $height  = shift;
    my $layout  = shift;

    my $matrix  = Chart::Magick::Matrix->new( $width, $height, 20 );

    foreach my $row (@$layout) {
        push @{ $matrix->rows }, [ map { [ $_->axis, 1 ] } @{ $row } ];

#        my @row;
#
#        foreach my $type ( @$row ) {
#            my $class = "Chart::Magick::Axis::$type";
#
#            my $ok = eval "require $class; 1";
#            die "Cannot instanciate axis class $class because: $@" if !$ok || $@;
#
#            push @row, [ $class->new(), 1 ]
#        }
#
#        push @{ $matrix->rows }, \@row;
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

