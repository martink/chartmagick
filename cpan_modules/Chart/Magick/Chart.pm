package Chart::Magick::Chart;

use strict;

use Class::InsideOut    qw{ :std };
use List::Util          qw{ min max };
use Chart::Magick::Palette;
use Chart::Magick::Color;
use Chart::Magick::Data;

readonly palette    => my %palette;
readonly dataset    => my %dataset;
private  properties => my %properties;

#-------------------------------------------------------------------
sub setData {
    my $self    = shift;
    my $dataset = shift;

    $dataset{ id $self } = $dataset;
}


#sub addDataset {
#    my $self    = shift;
#    my $dataset = shift || return;
#
#    push @{ $datasets{ id $self } }, $dataset;
#
#    # Find extreme values of dataset
#    my $minX    = min @{ $dataset->{x} };
#    my $maxX    = max @{ $dataset->{x} };
#    my $minY    = min @{ $dataset->{y} };
#    my $maxY    = max @{ $dataset->{y} };
#
#    # Update extreme value cache of chart where necessary.
#    $self->set('minX', $minX) if ($minX < $self->get('minX') || !defined $self->get('minX'));
#    $self->set('maxX', $maxX) if $maxX > $self->get('maxX');
#    $self->set('minY', $minY) if ($minY < $self->get('minY') || !defined $self->get('minY'));
#    $self->set('maxY', $maxY) if $maxY > $self->get('maxY');
#
#    $self->{_dsCount} = $self->{_dsCount} ? $self->{_dsCount} + 1 : 1;
#
#    for (0 .. scalar(@{ $dataset->{x} }) -1 ) {
#        $self->{_ds2}->{ $dataset->{x}->[$_] }->{ $self->{_dsCount} } = $dataset->{y}->[$_];
#    }
#
#    return;
#}

#-------------------------------------------------------------------
sub definition {
    return {};
}

#-------------------------------------------------------------------
sub get {
    my $self    = shift;
    my $key     = shift;

    return $properties{ id $self }->{ $key };
}

#-------------------------------------------------------------------
sub getPalette {
    my $self = shift;

    return $palette{ id $self } if $palette{ id $self };
    my @colors = (
        { fillTriplet => '7ebfe5', fillAlpha => '77', strokeTriplet => '7ebfe5', strokeAlpha => 'ff' },
        { fillTriplet => '43EC43', fillAlpha => '77', strokeTriplet => '43EC43', strokeAlpha => 'ff' },
        { fillTriplet => 'EC9843', fillAlpha => '77', strokeTriplet => 'EC9843', strokeAlpha => 'ff' },
        { fillTriplet => 'E036E6', fillAlpha => '77', strokeTriplet => 'E036E6', strokeAlpha => 'ff' },
        { fillTriplet => 'F3EB27', fillAlpha => '77', strokeTriplet => 'F3EB27', strokeAlpha => 'ff' },
    );

    my $palette = Chart::Magick::Palette->new;
    $palette->addColor( Chart::Magick::Color->new( $_ ) ) for @colors;
    
    $palette{ id $self } = $palette;

    return $palette;

}
#-------------------------------------------------------------------
sub new {
    my $class   = shift;
    my $self    = {};

    bless       $self, $class;
    register    $self;

    my $id              = id $self;
    $dataset{ $id }     = Chart::Magick::Data->new;
    $properties{ $id }  = $self->definition || {};

    return $self;
}

#-------------------------------------------------------------------
sub preprocessData {

}

#-------------------------------------------------------------------
sub set {
    my $self    = shift;
    my %update  = ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    my $properties  = $properties{ id $self };

    while ( my ($key, $value) = each %update ) {
        if ( exists $properties->{ $key } ) {
            $properties->{ $key } = $value;
        }
    }
}

1;

