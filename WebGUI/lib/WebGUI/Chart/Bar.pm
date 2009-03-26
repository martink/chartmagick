package WebGUI::Chart::Bar;

use strict;

use base qw{ WebGUI::Chart::ChartMagickLin };

#---------------------------------------------------------------------
sub definition {
    my $class       = shift;
    my $session     = shift;
    my $definition  = shift || [];

    tie my %options, 'Tie::IxHash', ( 
    );

    push @{ $definition }, {
        name        => 'Bar',
        className   => 'WebGUI::Chart::Bar',
        chartClass  => 'Chart::Magick::Chart::Bar',
        properties  => \%options,
    };

    return $class->SUPER::definition( $session, $definition );
};

##---------------------------------------------------------------------
#sub getAsHtml {
#
#}
#
##---------------------------------------------------------------------
#sub getAsFile {
#
#}
#
##---------------------------------------------------------------------
#sub plot {
#
#}

1;

