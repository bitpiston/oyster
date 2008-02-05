=xml
<document title="Server Side XSLT Module">
    <synopsis>
        Does XSL processing using the Gnome LibXSLT libraries
    </synopsis>
    <todo>
        Add alternatives to Gnome LibXSLT/XML
    </todo>
    <todo>
       Drop cached styles after a given time period, to prevent rarely-used styles from permanentally hogging memory.
    </todo>
=cut
package ssxslt;

# import oyster libraries
use oyster 'module';
use exceptions;

#
# Initialization
#

our ($disable_ssxslt, $xml_parser, $xslt_parser, %styles, %style_parse_times, $loaded);

# load module
sub load {

    # server side xml/xslt libraries
    eval {
        require XML::LibXSLT;
        require XML::LibXML;
    };
    if ($@) {
        $disable_ssxslt = 1;
        log::status('Server side XSLT module ignored.  Required libraries are not available.') unless $CONFIG{'debug'};
        return; # proceed no further in loading
    }

    # create xml/xslt processor objects
    $xml_parser  = XML::LibXML->new();
    $xslt_parser = XML::LibXSLT->new();

    $loaded = 1;
}

# ----------------------------------------------------------------------------
# Hooks
# ----------------------------------------------------------------------------

event::register_hook('request_init', 'hook_request_init', 110);
sub hook_request_init {
    return if $disable_ssxslt;

    # figure out of the user's engine and version can handle xml/xslt
    my $engine  = $REQUEST{'ua_render_engine'};
    my $version = $REQUEST{'ua_render_engine_version'};
    if    ($engine eq 'msie'  and $version > 5.5) { return }
    elsif ($engine eq 'opera' and $version >= 9)  { return }
    elsif ($engine eq 'gecko')                    { return }
    elsif ($engine eq 'applewebkit')              { return }
    elsif ($engine eq 'khtml')                    { return }
    else { $REQUEST{'server_side_xslt'} = 1 }

    # capture output
    if (exists $REQUEST{'server_side_xslt'}) {
        $REQUEST{'mime_type'} = $engine eq 'msie' ? 'text/html' : 'application/xhtml+xml'; # IE requires text/html for xhtml
        buffer::start();
    }
}

event::register_hook('request_finish', 'hook_request_finish', -110);
sub hook_request_finish {
    return unless exists $REQUEST{'server_side_xslt'};

    load() unless $loaded;

    my $buffer = buffer::end_clean();
    $buffer =~ s/^.+\n.+\n//; # strip first two lines out (xml version and stylesheet)
    my $source = eval { $xml_parser->parse_string($buffer) };
    if ($@) {
        log::error("Error parsing xml on url '$ENV{REQUEST_URI}': $@");
        return;
    }

    my $style_id = $REQUEST{'style'};

    # reparse server_base.xsl if necessary
    _parse_server_base($style_id) if (!exists $style_parse_times{$style_id} or ($oyster::CONFIG{'compile_styles'} and file::mtime("$CONFIG{site_path}styles/$style_id/server_base.xsl") > $style_parse_times{$style_id}));

# TODO: proper errors for the end user if something goes wrong
# TODO: should be a debugging switch for the evals

    # transform xml using the current style
    my $style = eval { $styles{$style_id}->transform($source) };
    if ($@) {
        log::error("Error parsing style '$style_id' url '$ENV{REQUEST_URI}': $@");
        return;
    }

    # print output
    #http::header("Content-Type: $REQUEST{mime_type}", 1);
    print $styles{$style_id}->output_string($style);
    print "\n<!-- Full Execution Time (with server side XSLT): " . sprintf('%0.5f', Time::HiRes::gettimeofday() - $REQUEST{'start_time'}) . " sec -->\n";
}

sub _parse_server_base {
    my $style_id = shift;
    return unless -e "$CONFIG{site_path}styles/$style_id/server_base.xsl";
    $style_parse_times{$style_id} = time(); # TODO: if file::mtime is changed to gmt, this will have to be changed to datetime::gmtime()
    eval { $styles{$style_id} = $xslt_parser->parse_stylesheet($xml_parser->parse_file("$CONFIG{site_path}styles/$style_id/server_base.xsl")) };
    log::error("Error parsing style' $CONFIG{site_path}styles/$style_id/server_base.xsl': $@") if ($@ and $CONFIG{'debug'});
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008