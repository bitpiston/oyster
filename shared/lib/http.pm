=xml
<document title="HTTP Functions">
    <synopsis>
        Various functions that don't (yet) warrant their own categories
    </synopsis>
=cut

package http;

use exceptions;

our $timeout = 15;         # default timeout
our $max_kb  = 500;        # default largest amount of data to fetch
our $crlf    = "\015\012"; # header line endings

=xml
    <function name="get">
        <synopsis>
            Fetches a remote file and saves it locally.
        </synopsis>
        <note>
            Throws a 'validation_error' if the file could not be fetched.
        </note>
        <note>
            Throws a 'perl_error' if the destination file could not be created or
            opened.
        </note>
        <note>
            'data_handler' can be used to parse a remote file in pieces, never
            writing the entire file to memory or disk.  If this argument is defined,
            the file is not saved, and the contents are not returned, but as the
            file is retreived, pieces are sent as arguments to the handler sub
            routine.
            
            If the data handler routine returns -1, the connection will be
            immediately closed and the rest of the file will be ignored.
        </note>
        <note>
            The return value of this function varies depending on its arguments.  If
            'file' or 'data_handler' are defined, http::get() returns 1 for
            success.  Otherwise, the contents of the fetched file are returned.
        </note>
        <prototype>
            http::get(string url, ['file' => string local_file][, 'max_size' => int max_size_in_kb][, 'data_handler' => subref])
        </prototype>
        <todo>
            BUG: http headers must be under 8 kb!
        </todo>
        <todo>
            more efficient to get a lexical subref if we are calling this a lot? (removes one de-reference op per pass)
        </todo>
    </function>
=cut

sub get {
    require IO::Socket;

    # parse arguments
    my ($url, %options) = @_;
    $options{'timeout'} = $timeout unless exists $options{'timeout'};
    $options{'max_kb'}  = $max_kb  unless exists $options{'max_kb'};  # should use $cgi::max_post_size, but this module may be used without cgi
    my $max_bytes       = $options{'max_kb'} * 1024;

    # get host, port, and path from url
    #return $url =~ m!^(?:ht|f)tps?://[a-zA-Z](?:[a-zA-Z\-]+\.)+([a-zA-Z]{2,5})(?::\d+)?(?:/[\S\s]+?)?/?$!o;
    #throw 'validation_error' => "Invalid url: '$url'." unless $url =~ m!^http://([^/:\@]+)(?::(\d+))?(/\S*)?$!;
    throw 'validation_error' => "Invalid url: '$url'." unless $url =~ m!^http://([a-zA-Z](?:[a-zA-Z\-]+\.)+(?:[a-zA-Z]{2,5}))(?::(\d+))?((?:/[\S\s]+?)/?)?$!o;
    #throw 'validation_error' => "Invalid url: '$url'." unless url::is_valid($url);
    my $host = $1;
    my $port = $2 || 80;
    my $path = $3;
    $path = "/$path" unless $path =~ m{^/}; # lead the path with a / if it isn't already

    # open a connection
    my $sock = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => $options{'timeout'},
    ) or throw 'validation_error' => "Error connecting to host '$host'.";
    $sock->autoflush(); # disable output buffering on this connection

    # request the file
    print $sock join($crlf,
        "GET $path HTTP/1.0",
        #"Host: $host:$port",
        "Host: $host" . ( $port != 80 ? ":$port" : '' ),
        'User-Agent: oyster-http-get/1.0',
        '', '', # end header
    );

    # if this is being saved to a file, open the file
    my $dest_fh;
    if (exists $options{'file'}) {
        open($dest_fh, '>', $options{'file'}) or throw 'perl_error' => "Error opening destination file for '$url': $!\n";
        binmode($dest_fh);
    }

    # read the file
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

        # if this is being saved to a file
        if (exists $options{'file'}) {
            print $dest_fh $buf;
        }

        # if this is being sent to a handler
        elsif (exists $options{'data_handler'}) {
            my $status = $options{'data_handler'}->($buf); # TODO: more efficient to get a lexical subref if we are calling this a lot? (removes one de-reference op per pass)
            return -1 if $status == -1; # close connection prematurely
        }

        # otherwise, save it to a buffer to be returned
        else {
            $buffer .= $buf;
        }
    }
    throw 'validation_error' => "'$url' is an empty file." unless $read_bytes;

    # if the file was sent to a handler
    if (exists $options{'data_handler'}) {
        $options{'data_handler'}->(); # call with no data to signal eof
        return 1;
    }

    # if the url was saved to a file
    elsif (exists $options{'file'}) {
        return 1;
    }

    # otherwise return the contents of the file
    else {
        return $buffer;
    }
}

=xml
    <function name="header">
        <synopsis>
            Prints an http header.
        </synopsis>
        <prototype>
            http::header(string header)
        </prototype>
        <example>
            http::header("Content-Type: text/plain");
        </example>
        <todo>
            
        </todo>
    </function>
=cut

sub header {
    my $header = shift;
    return unless length $header;
    push @{$oyster::REQUEST{'http_headers'}}, $header;
}

=xml
    <function name="clear_headers">
        <todo>
            Documentation
        </todo>
    </function>
=cut

sub clear_headers {
    @{$oyster::REQUEST{'http_headers'}} = ();
}

=xml
    <function name="print_headers">
        <todo>
            do with a join?
        </todo>
        <todo>
            Documentation
        </todo>
    </function>
=cut

sub print_headers {
    print STDOUT join($crlf, @{ $oyster::REQUEST{'http_headers'} }, '', '');
    clear_headers();
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
