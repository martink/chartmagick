use Chart::Magick;

my $dsx = [ 1 .. 5 ];
my $dsy = [ reverse 1 .. 5 ];

my $noise_x = [ map { $_ / 100 } ( 1 .. 500 ) ];
my $noise_y = [ map { rand     } ( 1 .. 500 ) ];

Chart::Magick->line( 
    width   => 500,
    height  => 300,
    data    => [ 
#        [ $dsx, $dsy, 'DS 1', 'circle', 6 ],
#        [ $dsx, $dsx, 'DS 2', 'square', 6 ],
        [ $noise_x, $noise_y ],
    ],
    legend  => {
        backgroundColor => 'none',
    },
)->Write( 'magick.png' );
