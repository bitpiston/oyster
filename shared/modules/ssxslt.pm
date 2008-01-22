##############################################################################
# Server Side XSLT Module
# ----------------------------------------------------------------------------
# Does XSL processing using the Gnome LibXSLT libraries
#
# TODO:
# * Update to new url mechanics
# * Only parse styles if they are requested, will save memory on styles
#   that are rarely used.
# ----------------------------------------------------------------------------

# declare module name
package ssxslt;

# import oyster globals
use oyster 'module';

# load oyster libraries
use exceptions;

#
# Initialization
#

our $disable_ssxslt;

# load module
event::register_hook('load', 'hook_load');
sub hook_load {

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
    our $xml_parser  = XML::LibXML->new();
    our $xslt_parser = XML::LibXSLT->new();

    # load all enabled-styles' styles
    our %styles;
    for my $style_id (keys %style::styles) {
        eval { $styles{$style_id} = $xslt_parser->parse_stylesheet($xml_parser->parse_file("$CONFIG{site_path}styles/$style_id/server_base.xsl")) };
        log::error("Error parsing style' $CONFIG{site_path}styles/$style_id/server_base.xsl': $@") if ($@ and $CONFIG{'debug'});
    }
}

# ----------------------------------------------------------------------------
# Hooks
# ----------------------------------------------------------------------------

event::register_hook('request_init', 'hook_request_init', 110);
sub hook_request_init {
    return if $disable_ssxslt;

    $REQUEST{'server_side_xslt'} = 0;
    if    ($ENV{'HTTP_USER_AGENT'} =~ /MSIE (\d+\.\d+)/) {              # IE 5.5 or greater (all versions of IE need a diff mime type for xhtml)
           $REQUEST{'server_side_xslt'} = 1 unless ($1 >= 5.5 and $ENV{'HTTP_USER_AGENT'} !~ /Opera/);
           $REQUEST{'mime_type'} = 'text/html';
    }
    elsif ($ENV{'HTTP_USER_AGENT'} =~ /Firefox/) {}                     # all versions of firefox
    elsif ($ENV{'HTTP_USER_AGENT'} =~ /Opera\/(\d+\.\d+)/) {}           # opera >= 9
    elsif ($ENV{'HTTP_USER_AGENT'} =~ /^Mozilla\/5\.0.+Gecko\/\d+$/) {} # all versions of the mozilla suite
    elsif ($ENV{'HTTP_USER_AGENT'} =~ /^Mozilla\/5\.0.+Camino/) {}      # moz camino (crazy mac users)
    elsif ($ENV{'HTTP_USER_AGENT'} =~ /Netscape/) {}                    # Netscape > 6
    elsif ($ENV{'HTTP_USER_AGENT'} =~ /SeaMonkey/) {}                   # seamonkey suite
    #elsif ($ENV{'HTTP_USER_AGENT'} =~ /Safari/) {}                     # safari --- apple says 1.3 and up support xslt -- why is it not working?
    else {
        $REQUEST{'server_side_xslt'} = 1;
    }

    # query string overrides
    if ($INPUT{'ssxslt'} eq 'on') {
        $REQUEST{'server_side_xslt'} = 1;
    } elsif ($INPUT{'ssxslt'} eq 'off') {
        $REQUEST{'server_side_xslt'} = 0;
    }

    # capture output
    if ($REQUEST{'server_side_xslt'} == 1) {
        $REQUEST{'mime_type'} = 'application/xhtml+xml' unless $REQUEST{'mime_type'};
        buffer::start();
    }
}

event::register_hook('request_finish', 'hook_request_finish', -110);
sub hook_request_finish {
    return unless $REQUEST{'server_side_xslt'};

    my $buffer = buffer::end_clean();
    $buffer =~ s/^.+\n.+\n//; # strip first two lines out (xml version and stylesheet)
    my $source = eval { $xml_parser->parse_string($buffer) };
    if ($@) {
        log::error("Error parsing xml on url '$ENV{REQUEST_URI}': $@");
        return;
    }

# TODO: proper errors for the end user if something goes wrong
# TODO: should be a debugging switch for the evals

    # transform xml using the current style
    my $style = eval { $styles{$REQUEST{'style'}}->transform($source) };
    if ($@) {
        log::error("Error parsing style '$REQUEST{style}' url '$ENV{REQUEST_URI}': $@");
        return;
    }

    # print output
    #http::header("Content-Type: $REQUEST{mime_type}", 1);
    print $styles{$REQUEST{'style'}}->output_string($style);
    print "\n<!-- Full Execution Time (with server side XSLT): " . sprintf('%0.5f', Time::HiRes::gettimeofday() - $REQUEST{'start_time'}) . " sec -->\n";
}

# ----------------------------------------------------------------------------
# Copyright Synthetic Designs 2006
##############################################################################
1;