package WebGUI::Chart;

use strict;

use Class::InsideOut qw{ :std };
use WebGUI::Pluggable;
use JSON qw{ to_json };
use Data::Dumper;

readonly datasets   => my %datasets;
readonly session    => my %session;
private  options    => my %options;

sub addDataset {
    my $self    = shift;
    my $values  = shift;
    my $coords  = shift;
    my $labels  = shift;

    if ($values && !$coords) {
        $coords = [ ( 1 .. scalar @{ $values } ) ];
    };

    push @{ $datasets{ id $self } }, [ $coords, $values, $labels ];
}

sub definition {
    my $class       = shift;
    my $session     = shift;
    my $definition  = shift || [ ];

    return $definition;
}

sub new {
    my $class           = shift;
    my $session         = shift || die "No session passed";
    my $configuration   = shift || {};
    my $self  = {};

    bless $self, $class;
    register $self;

    my $properties = {};
    foreach my $definition ( @{ $self->definition( $session ) } ) {
        foreach my $key ( keys %{ $definition->{properties} } ) {
            $properties->{ $key } = 
                $configuration->{ properties }->{ $key } 
                || $definition->{ properties }->{ $key }->{ defaultValue };
        }

    }

    my $id = id $self;
    $datasets{ $id }    = [];
    $session{ $id }     = $session;
    $options{ $id }     = $properties;

    return $self;
}

sub newByConfiguration {
    my $class           = shift;
    my $session         = shift;
    my $configuration   = shift;

    my $class = $configuration->{ className };

    my $plugin = eval { WebGUI::Pluggable::instanciate( $class, 'new', [ $session, $configuration ] ) };
    if ($@) {
        $session->log->error( "Could not instantiate Charting plugin [$class]. Reason: $@" );

        return undef;
    }
    
    return $plugin;
}

sub get {
    my $self    = shift;
    my $key     = shift;

    my $parameters = $options{ id $self };

    if ($key) {
        return $parameters->{ $key } if exists $parameters->{ $key };

        die "WG::Chart: tried to get invalid key [$key]";
    }
    
    return { %{ $parameters } };
}


sub chartingTabJS {
    return <<EOJS;
<script type="text/javascript">
function switchGraphingForm ( e ) {
    for (var i = 0; i < this.options.length; i++) {
        var container = document.getElementById( 'graph-' + this.options[i].value );

        // Find all children that can be disabled.
        var children = YAHOO.util.Dom.getElementsBy( function (elem) { return elem.disabled != null }, null, container );
        if (this.selectedIndex == i) {
            // Enable the form inputs 
            for (var c = 0; c < children.length; c++) {
                children[c].disabled = false;
            }

            // And make them visible
            container.style.display = '';
        }
        else {
            // Disable the form inputs
            for (var c = 0; c < children.length; c++) {
                children[c].disabled = true;
            }

            // And turn them invisible
            container.style.display = 'none';
        }   
    }
}
YAHOO.util.Event.onDOMReady( 
    function () {
        YAHOO.util.Event.addListener( 'graph_classNameSelector', 'change', switchGraphingForm );
    }

);
</script>
EOJS
}

sub getChartingTab {
    my $class           = shift;
    my $session         = shift;
    my $configuration   = shift || {};

    my $plugins = $session->config->get('chartingPlugins');

    my $options = {};
    my $pluginForms = WebGUI::HTMLForm->new( $session );
 #   $pluginForms->raw( qq{</tbody></table>} );
    my $classProcessed;
    my $isaTrail = {};

    foreach my $namespace (@$plugins) {
        my $chart       = eval { WebGUI::Pluggable::instanciate( $namespace, 'new', [ $session, $configuration ] ) }; 
        $session->log->warn("Could not instanciate plugin $namespace: $@") if ($@);

        $options->{ $namespace } = $chart->definition( $session )->[0]->{ name };

        foreach my $part ( @{ $chart->definition( $session ) } ) {
            (my $className = $part->{ className } ) =~ s/::/_/g;
            push @{ $isaTrail->{ $namespace } }, $className;
            next if $classProcessed->{ $className };

            $pluginForms->trClass( $className );

            foreach my $field ( keys %{ $part->{ properties } } ) {
                my $params = $part->{ properties }->{ $field };
                $params->{ value  } = $chart->get( $field );
                $params->{ name   } = $field;
                $params->{ extras } .= " class=\"$className\"";
                $pluginForms->dynamicField( %{ $params } );
            }

            $classProcessed->{ $className } = 1;
        }

#        $pluginForms->raw( qq{<table id="graph-$namespace"><tbody>} );
#        $pluginForms->raw( $chart->getEditForm->printRowsOnly );
#        $pluginForms->raw( qq{</tbody></table>} );
    }
#    $pluginForms->raw( qq{<table><tbody} );

#   $session->style->setRawHeadTags( $class->chartingTabJS );
    $session->style->setScript( $session->url->extras('chartingTabSwitcher.js'), { type=>'text/javascript' } );
    my $constituentsJSON = to_json( $isaTrail );

    my $f = WebGUI::HTMLForm->new( $session );
    $f->selectBox(
        name    => "graph_className",
        label   => "Graph type",
        options => $options,
        id      => 'graph_classNameSelector',
    );
    $f->raw( $pluginForms->printRowsOnly );
    $f->readOnly(
        value   => <<EOJS
           <script type="text/javascript">
                var switchert = new WebGUI.ChartFormSwitcher('graph_classNameSelector', $constituentsJSON);
           </script>
EOJS
    );

    return $f->printRowsOnly;
}

sub getConfiguration {
    my $self = shift;

    return {
        className   => $self->definition( $self->session )->[0]->{ className },
        properties  => $self->get,
    };
}

sub getEditForm {
    my $self = shift;

    my $f = WebGUI::HTMLForm->new( $self->session );
    foreach my $part ( @{ $self->definition( $self->session ) } ) {
        (my $class = $part->{ className } ) =~ s/::/_/g;
        foreach my $field ( keys %{ $part->{ properties } } ) {
            my $params = $part->{ properties }->{ $field };
            $params->{ value  } = $self->get( $field ),
            $params->{ name   } = $field,
            $params->{ extras } .= " class=\"$class\"",

            $f->dynamicField( $params );
        }
    }
#    $f->dynamicForm( $self->definition( $self->session ), 'properties', $self );

    return $f;
}

sub processEditForm {
    my $class   = shift;
    my $session = shift;

    my $class   = $session->form->process('graph_className');
    my $plugin  = eval { WebGUI::Pluggable::instanciate( $class, 'new', [ $session ] ) };
    if ($@) {
        $session->log->error("Could not instanciate charting plugin $class in processEditForm because: $@");
        return undef;
    }

    $plugin->processPropertiesFromFormPost;

    return $plugin;
}

sub processPropertiesFromFormPost {
    my $self    = shift;
    my $session = $self->session;

    foreach my $definition ( @{ $self->definition( $session ) } ) {
        foreach my $property ( keys %{ $definition->{ properties } } ) {
            $self->set({
                $property => $session->form->process(
                    $property,
                    $definition->{ properties }->{ $property }->{ fieldType     },
                    $definition->{ properties }->{ $property }->{ defaultValue  },
                )
            });
        }
    }
}

sub set {
    my $self    = shift;
    my $update  = shift;

    return unless $update;

    my $options = $options{ id $self };
    %{ $options } = ( %{ $options }, %{ $update } );
}

1;
