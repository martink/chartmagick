use strict;

use Chart::Magick::Axis;

my $im = Chart::Magick::ImageMagick->new( 
    size => "750x750",
);
$im->Read('xc:white');

my %properties = (
    text    => "TEXT\nTE\nTEXT",
    fill    => 'black',
    x       => 100,
    y       => 100,
    pointsize => 10,
    valign  => 'center',
    halign  => 'center',
    align   => 'Center',
    undercolor => 'green',
    font    => '/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf',
);    

for my $ha (0..2) {
    for my $va (0..2) {
        for (1..8) {
            my $x = $_*75;
            my $x1 = $x-25;
            my $x2 = $x + 25;

            my $y = ( $ha * 3 + $va + 1) * 75;
            my $y1 = $y-25;
            my $y2 = $y+25;
            $im->Draw(
                primitive   => 'Path',
                points      => "M $x,$y1 L $x,$y2 M $x1,$y L $x2,$y",
                stroke      => 'red',
            );

print "[$ha][$va][$_]\n";
            $im->text(
                %properties,
                x       => $x,
                y       => $y,
                halign  => ( qw{ left   center  right   } )[$ha],
                valign  => ( qw{ top    center  bottom  } )[$va],
                rotate  => 45*($_ - 1 ),
            );
        }
    }
}

print "KLABZAM!!!!\n";
$im->Write('text.png');

