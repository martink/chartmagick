package Chart::Magick::Marker;

use strict;

sub new {
    my $class   = shift;
    my $size    = shift;

    bless { size => $size };
}

sub draw {
    my $self    = shift;
    my $x       = shift;
    my $y       = shift;
    my $im      = shift;
    my $color   = shift || 'lightgray';

    my $size    = $self->{ size };

    my $marker1 = [
        [ 'M', 0,    0      ],
        [ 'L', 0.5, -0.75   ],
        [ 'L', 1,    0      ],
        [ 'Z'               ],
    ];

    my $marker2 = [
        [ 'M',  0,   0      ],
        [ 'L',  1,   0      ],
        [ 'L',  1,   1      ],
        [ 'L',  0,   1      ],
        [ 'Z'               ],
    ];

    my $path = join(' ', map { $_->[0] .' '.  $size*$_->[1] .','. $size*$_->[2] } @$marker2);


    my $translateX = int( $x - 0.5*$size + 0.5 );
    my $translateY = int( $y - 0.5*$size + 0.5 );

    $im->Draw(
       primitive    => 'Path',
       stroke       => $color,
       strokewidth  => 1,
       points       => $path,
       fill         => 'none',
       # Use an affine transform here, since the translate option doesn't work at all...
#       translate    => [ 100, 100 ], #"$translateX,$translateY",
       affine       => [ 1, 0, 0, 1, $translateX,$translateY ],
       antialias    => 'true',
    );

}    

1;

