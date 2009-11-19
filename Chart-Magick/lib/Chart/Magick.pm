package Chart::Magick;

use strict;
use Image::Magick;
#use Chart::Magick::Axis::LinLog;

our $VERSION = '0.1.0';


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
    my @layout  = @_;

#    my $xc      = shift;
#    my $yc      = shift;
#    my $types   = shift;
    my $m   = 20;

    my $yCount = scalar @layout;

    my $axisHeight  = ( $self->{ options }->{ height } - $m - $m - ($yCount - 1) * $m ) / $yCount;
    my $y = 0;
    foreach my $row (@layout) {
        my $xCount = scalar @$row;

        my $axisWidth   = ( $self->{ options }->{ width } - ( ( 1 + $xCount ) * $m ) ) / $xCount;

        my $x = 0;

        foreach my $type ( @$row ) {
            my $class = "Chart::Magick::Axis::$type";

            my $ok = eval "require $class; 1";
            die "Cannot instanciate axis class $class because: $@" if !$ok || $@;

            $self->addAxis(
                $class->new( { width => $axisWidth, height => $axisHeight } ),
                $x * ( $axisWidth +  $m ) + $m,
                $y * ( $axisHeight + $m ) + $m,
            );
            $x++;
        }

        $y++;
    }

}

    

sub new {
    my $class   = shift;
    my $w       = shift;
    my $h       = shift;

    my $magick  = Image::Magick->new(
        size        => $w.'x'.$h,
    );
    $magick->Read('xc:grey40');

    my $options = {
        width   => $w,
        height  => $h,
    };

    bless { im => $magick, axes => [ ], options => $options }, $class;
}

1;

