package Chart::Magick;

use strict;
use Image::Magick;
use Chart::Magick::Axis::LinLog;

sub addAxis {
    my $self    = shift;
    my $axis    = shift;
    my $x       = shift;
    my $y       = shift;

    push @{ $self->{axes} }, { x => $x, y => $y, axis => $axis };
}


sub draw {
    my $self = shift;

    foreach my $axis ( @{ $self->{axes} } ) {
        $axis->{axis}->draw;

        $self->im->Composite(
            x       => $axis->{x},
            y       => $axis->{y},
            image   => $axis->{axis}->im,
        );
    }
}

sub getAxis {
    my $self    = shift;
    my $index   = shift;

    die "invalid axis" if $index >= scalar( @{ $self->{ axes } } );

    return $self->{ axes }->[ $index ]->{ axis };
}

sub im {
    my $self = shift;

    return $self->{ im };
}

sub matrix {
    my $self    = shift;
    my $xc      = shift;
    my $yc      = shift;
    my $types   = shift;
    my $m   = 20;

    my $axisWidth   = ( $self->{ options }->{ width } - $m - $m - ($xc - 1) * $m ) / $xc;
    my $axisHeight  = ( $self->{ options }->{ height } - $m - $m - ($yc - 1) * $m ) / $yc;
    


    for my $y ( 0 .. $yc-1 ) {
        for my $x ( 0 .. $xc -1 ) {
            my $class;
            if ( exists $types->{ $y * $xc + $x } ) {
                $class = $types->{ $y * $xc + $x };
                eval { "require $class" };
            }
            else {
                $class = 'Chart::Magick::Axis::Lin';
            }

            eval { "require $class" };
            $self->addAxis(
                $class->new( { width => $axisWidth, height => $axisHeight } ),
#                Chart::Magick::Axis::Lin->new( { width => $axisWidth, height => $axisHeight } ),
                $x * ( $axisWidth + $m ) + $m,
                $y * ( $axisHeight + $m ) + $m,
            );
        }
    }
}

    

sub new {
    my $class   = shift;
    my $w       = shift;
    my $h       = shift;

    my $magick  = Image::Magick->new(
        size        => $w.'x'.$h,
    );
    $magick->Read('xc:white');

    my $options = {
        width   => $w,
        height  => $h,
    };

    bless { im => $magick, axes => [ ], options => $options }, $class;
}

1;

