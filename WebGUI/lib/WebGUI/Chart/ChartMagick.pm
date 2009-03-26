package WebGUI::Chart::ChartMagick;

use strict;
use warnings;

use Class::InsideOut qw{ :std };
use WebGUI::Pluggable;
use Data::Dumper;
use WebGUI::Image::Font;


use base qw{ WebGUI::Chart };

readonly axis               => my %axis;
readonly chart              => my %chart;
readonly axisProperties     => my %axisProperties;
readonly chartProperties    => my %chartProperties;

#---------------------------------------------------------------------
sub _applyConfiguration {
    my $self    = shift;
    my $session = $self->session;

$session->log->warn( $self->axisProperties );

    foreach my $definition ( @{ $self->definition( $session ) } ) {
        foreach my $key ( keys %{ $definition->{ properties } } ) {
            if ($definition->{ properties }->{ $key }->{ category } eq 'axis') {
                my $value = exists $self->axisProperties->{ $key }
                    ? $self->axisProperties->{ $key }
                    : $definition->{ properties }->{ $key }->{ defaultValue }
                    ;

                $self->axis->set( { $key => $value } );
            }
            if ($definition->{ properties }->{ $key }->{ category } eq 'chart') {
                my $value = exists $self->chartProperties->{ $key }
                    ? $self->chartProperties->{ $key }
                    : $definition->{ properties }->{ $key }->{ defaultValue }
                    ;

                $self->chart->set( { $key => $value } );
            } 
        }
    }
    

#    foreach my $definition ( @{ $self->definition( $session ) } ) {
#        foreach my $key ( keys %{ $definition->{ axisProperties } } ) {
#            my $value = exists $self->axisProperties->{ $key }
#                ? $self->axisProperties->{ $key }
#                : $definition->{ axisProperties }->{ $key }->{ defaultValue }
#                ;
#
#            $self->axis->set( { $key => $value } );
#        }
#        foreach my $key ( keys %{ $definition->{ chartProperties } } ) {
#            my $value = exists $self->chartProperties->{ $key }
#                ? $self->chartProperties->{ $key }
#                : $definition->{ chartProperties }->{ $key }->{ defaultValue }
#                ;
#
#            $self->chart->set( { $key => $value } );
#        } 
#    }

    my $font = WebGUI::Image::Font->new( $session, $self->get('font') );
    my $fontFile = $font->getFile;
    $self->axis->set({
        titleFont   => $fontFile,
        labelFont   => $fontFile,
    });

    # Set palette;
#    $self->chart->
}

#---------------------------------------------------------------------
sub definition {
    my $class       = shift;
    my $session     = shift || die "No session passed!!!";
    my $definition  = shift || [];

    my $fonts = $session->db->buildHashRef('select fontId, name from imageFont');

    tie my %properties, 'Tie::IxHash', (
        font => {
            fieldType       => 'selectBox',
            label           => 'Font',
            options         => $fonts,
        },
 #   );

#    tie my %axisProperties, 'Tie::IxHash', (
        width => {
            fieldType       => 'integer',
            label           => 'Width (px)',
            defaultValue    => 400,
            category        => 'axis',
        },
        height => {
            fieldType       => 'integer',
            label           => 'Height (px)',
            defaultValue    => 300,
            category        => 'axis',
        },
        marginTop => {
            fieldType       => 'integer',
            label           => 'Margin',
            defaultValue    => 50,
            category        => 'axis',
        },
        title => {
            fieldType       => 'text',
            label           => 'Chart title',
            category        => 'axis',
        },
        titleFont => {
            fieldType       => 'text',
            label           => 'Title font',
            category        => 'axis',
        },
       titleFontSize =>     {
            fieldType       => 'integer',
            label           => 'Title font size',
            default         => 20,
            category        => 'axis',
        },
        titleColor => {
            fieldType       => 'color',
            label           => 'Title color',
            category        => 'axis',
        }
    );

    my %def = (
        name            => 'ChartMagick',
        properties      => \%properties,
        axisProperties  => \%axisProperties,
        className       => 'WebGUI::Chart::ChartMagick',
    );
    push @{ $definition }, \%def;

    return $class->SUPER::definition( $session, $definition );
}

#---------------------------------------------------------------------
sub draw {
    my $self = shift;

    $self->_applyConfiguration;

    # Add datasets to chart
    foreach my $data (@{ $self->datasets }) {
        $self->chart->dataset->addDataset( $data->[0], $data->[1] );
    }

    $self->session->log->warn("-------->". Dumper( $self->axis->get ) );

    $self->axis->addChart( $self->chart );
    $self->axis->draw;
}

#---------------------------------------------------------------------
sub getConfiguration {
    my $self = shift;

    my $config = $self->SUPER::getConfiguration( @_ );

    $config->{ axisProperties   } = $self->axisProperties;
    $config->{ chartProperties  } = $self->chartProperties;

    return $config;
}

#---------------------------------------------------------------------
sub getEditForm {
    my $self    = shift;
    my $session = $self->session;
    
    my $axis    = $self->axis;
    my $chart   = $self->chart;

    my $f = $self->SUPER::getEditForm( @_ );
    foreach my $definition ( @{ $self->definition( $session ) } ) {
        foreach my $key ( keys %{ $definition->{ axisProperties } } ) {
            my $params = $definition->{ axisProperties }->{ $key };
            $params->{ name     } = $key;
            $params->{ value    } = $self->axisProperties->{ $key };
            $f->dynamicField( %{ $params } );
        }
    }
    foreach my $definition ( @{ $self->definition( $session ) } ) {
        foreach my $key ( keys %{ $definition->{ chartProperties } } ) {
            my $params = $definition->{ chartProperties }->{ $key };
            $params->{ name     } = $key;
            $params->{ value    } = $self->chartProperties->{ $key };
            $f->dynamicField( %{ $params } );
        }
    }

    return $f;
}

#---------------------------------------------------------------------
sub new {
    my $class           = shift;
    my $session         = shift || "A session is required";
    my $configuration   = shift || { };
    my $self            = $class->SUPER::new( $session, $configuration );

    # Apply configuration
    $chartProperties{ id $self } = $configuration->{ chartProperties } || { };
    $axisProperties{ id $self  } = $configuration->{ axisProperties  } || { };

    # Instanciate chart object
    my $chartClass = $class->definition( $session )->[0]->{ chartClass };
    $chart{ id $self } = eval { WebGUI::Pluggable::instanciate( $chartClass, 'new', [] ) };
    if ($@) {
        $self->session->log->error("Could not instantiate charting plugin: $@");
        return undef;
    }

    # Instanciate axis object
    my $axisClass = 'Chart::Magick::Axis::Lin'; #$self->get('axisType');
    $axis{ id $self } = eval { WebGUI::Pluggable::instanciate( $axisClass, 'new', [] ) };
    if ($@) {
        $self->session->log->error("Could not instantiate charting plugin: $@");
        return undef;
    }

    return $self;
}

sub processPropertiesFromFormPost {
    my $self    = shift;
    my $session = $self->session;

    $self->SUPER::processPropertiesFromFormPost( @_ );
    my $id      = id $self;

    foreach my $definition ( @{ $self->definition( $session ) } ) {
        # Process axis properties.
        foreach my $key ( keys %{ $definition->{ axisProperties } } ) {
            $axisProperties{ $id }->{ $key } = $session->form->process( 
                $key,
                $definition->{ axisProperties }->{ $key }->{ fieldType },
                $definition->{ axisProperties }->{ $key }->{ defaultValue },
            );
        }

        # Process chart properties.
        foreach my $key ( keys %{ $definition->{ chartProperties } } ) {
            $chartProperties{ $id }->{ $key } = $session->form->process( 
                $key,
                $definition->{ chartProperties }->{ $key }->{ fieldType },
                $definition->{ chartProperties }->{ $key }->{ defaultValue },
            );
        }
    }
    
}

#---------------------------------------------------------------------
sub toHtml {
    my $self = shift;
    
    $self->draw;

    my $storage     = WebGUI::Storage->createTemp( $self->session );
    my $filename    = $storage->getPath('chart.png');
    $self->axis->im->Write( $filename );

    my $url = $storage->getUrl('chart.png');
    return qq{<img src="$url" />};
}

#---------------------------------------------------------------------
sub toFile {
    my $self        = shift;
    my $filename    = shift;

    $self->axis->im->Write( $filename );

    return $filename;
}

1;

