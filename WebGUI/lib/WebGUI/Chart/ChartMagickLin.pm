package WebGUI::Chart::ChartMagickLin;

use strict;

use base qw{ WebGUI::Chart::ChartMagick };

sub definition {
    my $class       = shift;
    my $session     = shift || die "Need a session!";
    my $definition  = shift || [];

    tie my %axisOptions, 'Tie::IxHash', (
        axisType => {
            fieldType       => 'selectBox',
            label           => 'Coordinate system',
            options         => { 
                'Chart::Magick::Axis::Lin'      => 'Linear',
                'Chart::Magick::Axis::LinLog'   => 'LinLog',
            },
            defaultValue    => 'Chart::Magick::Axis::Lin',
        },
        xUseTicks => {
            fieldType       => 'yesNo',
            label           => 'Use ticks on x-axis?',
            cat             => 'axis',
        },
        xSubtickCount => {
            fieldType       => 'integer',
            label           => 'Number of subticks per interval',
            cat             => 'axis',
        },
    );

    my %properties = (
        name        => 'ChartMagickLin',
        properties  => \%axisOptions,
        className   => 'WebGUI::Chart::ChartMagickLin',
    );
    push @{ $definition }, \%properties;

    return $class->SUPER::definition( $session, $definition );
}

sub _applyConfiguration {
    my $self    = shift;
    my $session = $self->session;

    $self->SUPER::_applyConfiguration( @_ );

    my $font = WebGUI::Image::Font->new( $session, $self->get('font') );
    my $fontFile = $font->getFile;
    $self->axis->set({
        xTitleFont      => $fontFile,
        yTitleFont      => $fontFile,
        xSubtickCount   => 0,
    });
    
}

1;

