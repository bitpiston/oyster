=xml
<document title="SOAP Functions">
    <synopsis>
        Send a SOAP 1.1 request and parse/return the response.
    </synopsis>
    <note>
        This module requires installing IO::Socket::SSL from CPAN to use request_ssl().
    </note>
    <todo>
        BUG: http headers must be under 8 kb!
    </todo>
=cut

package soap;

use exceptions;
use xml::parser;

our $timeout = 15;         # default timeout
our $max_kb  = 500;        # default largest amount of data to fetch
our $crlf    = "\015\012"; # header line endings

=xml
    <function name="request">
        <synopsis>
            Constructs a SOAP request and parses the response.
        </synopsis>
        <note>
            Expects a complex hash to maintain the order since most SOAP servers care about the order.
        </note>
        <note>
            Returns a hash of the xml response keyed by elements.
        </note>
        <prototype>
            soap::request(['url' => 'string url', 'xmlns' => ' string xmlns'], string action, string name ['param' => [ 0, 'string value']][, 'param' => [ 1, 'string value']]...)
        </prototype>
    </function>
=cut

sub request_legacy {
    require IO::Socket;

    # parse arguments
    my ($conf, $action, $name, $request) = @_;
    $name = $name . $conf->{'xmlns'};
    $options{'timeout'} = $timeout unless exists $options{'timeout'};
    $options{'max_kb'}  = $max_kb  unless exists $options{'max_kb'};  # should use $cgi::max_post_size, but this module may be used without cgi
    my $content;

    # get host, port, and path from url
    throw 'validation_error' => "Invalid url: '$conf->{url}'." unless $conf->{'url'} =~ m!^(?:http|https)://([a-zA-Z](?:[a-zA-Z\-]+\.)+(?:[a-zA-Z]{2,5}))(?::(\d+))?((?:/[\S\s]+?)/?)?$!o;
    my $host = $1;
    my $port = $2 || 80;
    my $path = $3;
    $path = "/$path" unless $path =~ m{^/}; # lead the path with a / if it isn't already
    
    # Contruct the XML from the content hash
    $content .= '<?xml version="1.0" encoding="utf-8"?>' . "\n" . 
                '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' . "\n" .  
                "\t<soap:Body>\n";
    $content .= print_vars($name, $request, 2);
    $content .= "\t</soap:Body>\n" . 
                '</soap:Envelope>' . "\n";

    # open a connection
    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => $options{'timeout'},
    ) or throw 'validation_error' => "Error connecting to host '$host'.";
    $sock->autoflush(); # disable output buffering on this connection

    # post the request
    print $sock join($crlf,
        "POST $path HTTP/1.1",
        "Host: $host" . ( $port != 80 ? ":$port" : '' ),
        'Content-Type: text/xml; charset=utf-8',
        'Content-Length: ' . length($content),
        'Connection: close',
        "SOAPAction: \"$action\"",
        '', '', # end header
    ) . $content;
            
    # process, parse and return the response
    my $response = _process_response($sock, $conf->{'url'}, \%options);
    
    return $response;
}

=xml
    <function name="request_ssl">
        <synopsis>
            Constructs a secure SOAP request and parses the response.
        </synopsis>
        <note>
            Expects a complex hash to maintain the order since most SOAP servers care about the order.
        </note>
        <note>
            Returns a hash of the xml response keyed by elements.
        </note>
        <note>
            Credentials must be base64 encoded.
        </note>
        <prototype>
            soap::request(['url' => 'string url', 'xmlns' => ' string xmlns', 'auth' => 'string base64 user:password', 'ssl_key' => 'string path, 'ssl_cert' => 'string path'], string action, string name, ['param' => [ 0, 'string value']][, 'param' => [ 1, 'string value']]...)
        </prototype>
        <todo>
            Move SSL key/cert paths to module configuration.
        </todo>
    </function>
=cut

sub request {
    # parse arguments
    my ($request) = @_;
    $options{'timeout'} = $timeout unless exists $options{'timeout'};
    $options{'max_kb'}  = $max_kb  unless exists $options{'max_kb'};  # should use $cgi::max_post_size, but this module may be used without cgi
    my ($sock, $host, $port, $path, $ssl, $response);
    
    # get host, port, and path from url
    throw 'validation_error' => "Invalid url: '$request->{'url'}'." unless $request->{'url'} =~ m!^(http|https)://([a-zA-Z](?:[a-zA-Z\-]+\.)+(?:[a-zA-Z]{2,5}))(?::(\d+))?((?:/[\S\s]+?)/?)?$!o;
    $ssl  = $1 eq 'https' ? 1 : 0;
    $host = $2;
    $port = $ssl ? $3 || 443 : $3 || 80;
    $path = $4;
    $path = "/$path" unless $path =~ m{^/}; # lead the path with a / if it isn't already
    
    my $opened = try {
            
        # open a connection
        if ($ssl) {
            require IO::Socket::SSL;
            #use IO::Socket::SSL qw(debug9);
                
            $request->{'ssl'}->{'PeerAddr'} = $host;
            $request->{'ssl'}->{'PeerPort'} = $port;
            $request->{'ssl'}->{'Proto'}    = 'tcp';
            $request->{'ssl'}->{'Timeout'}  = $options{'timeout'};
            $sock = IO::Socket::SSL->new(%{ $request->{'ssl'} }) or throw 'soap_error' => "Error connecting to host '$host': $@";
        }
        else {
            require IO::Socket;
                
            $sock = IO::Socket::INET->new(
                    PeerAddr => $host,
                    PeerPort => $port,
                    Proto    => 'tcp',
                    Timeout  => $options{'timeout'},    # only for connect/accept
                ) or throw 'soap_error' => "Error connecting to host '$host': $@";
        }
    }
    catch 'soap_error', with {
        my $error = shift;
            
        log::error("SOAP Error: " . $error);
        abort(1);
    };
        
    if ($opened) {
        
        $sock->autoflush(); # disable output buffering on this connection
        
        # post the request
        my $headers;
        foreach my $header (@{ $request->{'headers'} }) {
            $headers .= $header . $crlf;
        }
        print $sock join($crlf,
            "POST $path HTTP/1.1",
            "Host: $host:$port",
            'Connection: close',
            'Accept-Encoding: gzip,deflate',
            'Content-Length: ' . length($request->{'xml_header'} . $request->{'xml_body'} . $request->{'xml_footer'}),
            'Content-Type: text/xml; charset=utf-8',
            $headers,
            '', # end header
        ) . $request->{'xml_header'} . $request->{'xml_body'} . $request->{'xml_footer'};
        
        # process, parse and return the response
        $response = _process_response($sock, $request->{'url'}, \%options);
    }
    
    return $response;
}

=xml
    <function name="_process_response">
        <synopsis>
            Processes the SOAP response to our requests - secure or not.
        </synopsis>
    </function>
=cut

sub _process_response {
    my ($sock, $url, $options, $max_bytes) = @_;
    my $max_bytes = $options->{'max_kb'} * 1024;
    
    # read the returned response
    my $buffer     = ''; # total file buffer
    my $buf        = ''; # file chunk buffer
    my $read_bytes = 0;  # total number of bytes read
    my $n;               # number of bytes read for the current chunk
    
    # Make sure the socket doesn't cause a timeout as it is blocking and timeout param only works for connect/accept, not sysread/syswrite
    try {
        local $SIG{'ALRM'} = sub { throw 'soap_error' => "Timeout waiting on host."; };
        alarm $options{'timeout'};
        
        while ($n = sysread($sock, $buf, 8 * 1024)) {
            
            # if this is the first chunk, check for http headers (TODO: BUG: http headers must be under 8 kb!)
            unless ($read_bytes) {
                throw 'soap_error' => "'$url' returned no HTTP headers." unless $buf =~ m!^HTTP/\d+\.\d+\s+(\d+)[^\012]*\012!o;
                
                # check for a redirect
                my $status_code = $1;
                if ($status_code =~ /^30[1237]/o and $buf =~ /\012Location:\s*(\S+)/io) {
                    my $redirect = $1;
                    return http::get($redirect, $options);
                }
                
                # check for non-success status codes
                throw 'soap_error' => "'$url' contained a malformed header." unless $status_code =~ /^2/o; # TODO: check for more status codes
                # remove header from buffer
                throw 'soap_error' => "'$url' contained a malformed header." unless $buf =~ s/^[\s\S]+?\015?\012\015?\012//o;
            }
            
            # incremeent total read bytes
            $read_bytes += $n;
            
            # check max file size
            throw 'soap_error' => "'$url' exceeded the maximum file size, $options->{max_kb}kb." if $read_bytes > $max_bytes;
            
            # save it to a buffer to be returned
            $buffer .= $buf;
        }
        throw 'soap_error' => "'$url' is an empty file." unless $read_bytes;
        
        alarm 0;
    }
    catch 'soap_error', with {
        my $error = shift;
            
        log::error("SOAP Error: " . $error);
        abort(1);
    };
    
    alarm 0;    # race condition protection
    
    if ($buffer) {
        
        # parse the response in our buffer and return a hash of the xml
        # elements are the keys 
        my $data;
        my %structure;
        my @structure_stack = (\%structure);
        $parser = new xml::parser;
        $parser->{'data_pointer'} = \$data;
        $parser->set_handler('node_start', sub {
            my($parser, $namespace, $node_name, %attributes) = @_;
            $structure_stack[$#structure_stack]->{$node_name} = {};
            push(@structure_stack, $structure_stack[$#structure_stack]->{$node_name});
        });
        $parser->set_handler('node_end', sub {
            my($parser, $namespace, $node_name) = @_;
            pop(@structure_stack);
            if(length $data) {
                $structure_stack[$#structure_stack]->{$node_name} = $data;
                $data = '';
            }
        });
        $parser->parse_string($buffer);
        
        return \%structure;
    }
}

=xml
    <function name="print_vars">
        <synopsis>
            Like xml::print_var but the hash is complex and ordered. Also handles multiple xml name spaces properly.
        </synopsis>
    </function>
=cut

sub print_vars {
    my $name   = shift;
    my $value  = shift;
    my $depth  = shift || 2;
    my $indent = "\t" x $depth;
    my $type   = ref $value;
    my $buffer;
    my $xmlns;
    my @values;
    
    # Split xmlns from name 
    #($name, $xmlns, $xmlns_url) = split(/( xmlns(?:\:[a-zA-Z0-9]+)?=)/, $name);
    #$xmlns = $xmlns . $xmlns_url if $xmlns;
    ($name, @values) = split(/( xmlns(?:\:[a-zA-Z0-9]+)?=)/, $name);
    foreach my $value (@values) {
        $xmlns .= $value if $value;
    }
    
    if ($type eq '') {
       $buffer .= "$indent<$name$xmlns>" . xml::entities($value) . "</$name>\n";
    }
    elsif ($type eq 'HASH') {
        $buffer .= "$indent<$name$xmlns>\n";
        my @sorted_keys = sort { $value->{$a}->[0] <=> $value->{$b}->[0] } keys %{$value};
           for my $key (@sorted_keys) {
            $buffer .= print_vars($key, $value->{$key}->[1], $depth + 1);
        }
        $buffer .= "$indent</$name>\n";
    }
    return $buffer;
}

# Copyright BitPiston 2012
1;
=xml
</document>
=cut
