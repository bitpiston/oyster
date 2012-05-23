=xml
<document title="SOAP Functions">
    <synopsis>
        Send a SOAP request and return the response.
    </synopsis>
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
            soap::request(string url, string action, string name ['param' => [ 0, 'string value']][, 'param' => [ 1, 'string value']]...)
        </prototype>
        <todo>
            BUG: http headers must be under 8 kb!
        </todo>
    </function>
=cut

sub request {
    require IO::Socket;

    # parse arguments
    my ($url, $action, $name, %content) = @_;
    $options{'timeout'} = $timeout unless exists $options{'timeout'};
    $options{'max_kb'}  = $max_kb  unless exists $options{'max_kb'};  # should use $cgi::max_post_size, but this module may be used without cgi
    my $max_bytes       = $options{'max_kb'} * 1024;
	my $content;

    # get host, port, and path from url
    throw 'validation_error' => "Invalid url: '$url'." unless $url =~ m!^http://([a-zA-Z](?:[a-zA-Z\-]+\.)+(?:[a-zA-Z]{2,5}))(?::(\d+))?((?:/[\S\s]+?)/?)?$!o;
    my $host = $1;
    my $port = $2 || 80;
    my $path = $3;
    $path = "/$path" unless $path =~ m{^/}; # lead the path with a / if it isn't already
	
	# Contruct the XML from the content hash
	$content .= '<?xml version="1.0" encoding="utf-8"?>' . "\n" . 
				'<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' . "\n" .  
	    		"\t<soap:Body>\n";
	$content .= print_vars($name, \%content, 2);
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
		"SOAPAction: \"$action\"",
        '', '', # end header
    ) . $content;
	
	# read the returned response
    my $buffer     = ''; # total file buffer
    my $buf        = ''; # file chunk buffer
    my $read_bytes = 0;  # total number of bytes read
    my $n;               # number of bytes read for the current chunk
    while ($n = sysread($sock, $buf, 8 * 1024)) {

        # if this is the first chunk, check for http headers (TODO: BUG: http headers must be under 8 kb!)
        unless ($read_bytes) {
            throw 'validation_error' => "'$url' returned no HTTP headers." unless $buf =~ m!^HTTP/\d+\.\d+\s+(\d+)[^\012]*\012!o;

            # check for a redirect
            my $status_code = $1;
            if ($status_code =~ /^30[1237]/o and $buf =~ /\012Location:\s*(\S+)/io) {
                my $redirect = $1;
                return http::get($redirect, %options);
            }

            # check for non-success status codes
            throw 'validation_error' => "'$url' contained a malformed header." unless $status_code =~ /^2/o; # TODO: check for more status codes
            # remove header from buffer
            throw 'validation_error' => "'$url' contained a malformed header." unless $buf =~ s/^[\s\S]+?\015?\012\015?\012//o;
        }

        # incremeent total read bytes
        $read_bytes += $n;

        # check max file size
        throw 'validation_error' => "'$url' exceeded the maximum file size, $options{max_kb}kb." if $read_bytes > $max_bytes;

        # save it to a buffer to be returned
        $buffer .= $buf;
    }
    throw 'validation_error' => "'$url' is an empty file." unless $read_bytes;

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

=xml
    <function name="print_vars">
        <synopsis>
		Like xml::print_var but the hash is complex and ordered.
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
	
	# Split xmlns from name 
	($name, $xmlns) = split(/ xmlns=/, $name);
	$xmlns          = ' xmlns=' . $xmlns if $xmlns;
	
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
