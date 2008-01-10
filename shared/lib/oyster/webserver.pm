##############################################################################
# Synthetic Web Server Library
# ----------------------------------------------------------------------------
# This is used by server.pl
# ----------------------------------------------------------------------------
package oyster::webserver;

# use perl libraries
use IPC::Open3;       # used to execute oyster
use IO::Socket::INET; # used to handle socket connections
use Encode;           # for unicode support

# mime types
our %mime_types = (
    '.xsl' => 'application/xml',
    '.js'  => 'text/javascript',
    '.css' => 'text/css',
    '.png' => 'image/png',
    '.jpg' => 'image/jpg',
    '.txt' => 'text/plain',
);

our (%config, $last_ip, $last_request, $oyster_executions);
our $crlf = $http::crlf;

# starts the web server
sub start {
    %config = @_;
    $config{'port'} ||= 80;
    $config{'host'} = '127.0.0.1' unless length $config{'host'};
    accept_connections();
}

# accept connections
sub accept_connections {

    # listen on a socket
    my $sock = IO::Socket::INET->new(
        Listen    => 10,
        LocalAddr => $config{'host'},
        LocalPort => $config{'port'},
        Proto     => 'tcp',
    ) or die $!;

    print "You can terminate this server at any time by pressing CTRL + C.\n\n";

    print "Listening to port $config{port} on host $config{host}\n\n";

    print "Request Method: Request Path\n";

    # create multiple daemons
    #fork for 1..3;
    # TODO: add proper child reaping

    # handle incoming connections
    while (my ($client, $client_addr) = ($sock->accept())[ 0 .. 1 ]) {
        SERVE_REQUEST: { serve_request($client, $client_addr) };
        close $client;
    }
}

# a fatal error occurs while handling a request
sub error {
    print "  Error: $_[0]\n";
    last SERVE_REQUEST;
}

# a 404 page
sub request_404 {
    my $client = shift;

    # print http response
    print {$client} "HTTP/1.1 404$crlf";

    # print content-type and end header
    print {$client} "Content-Type: text/plain$crlf$crlf";

    # print 404 error page
    print {$client} "404 - File could not be found.\n";
}

# serves a file
sub serve_file {
    my ($file, $client) = @_;

    # print http response
    print {$client} "HTTP/1.1 200$crlf";

    # print mime type
    my ($ext) = ($file =~ /(\.\w+)$/);
    my $mime_type = $mime_types{$ext} ? $mime_types{$ext} : $mime_types{''};
    print ${client} "Content-Type: $mime_type$crlf$crlf";

    # open and send file to client
    open(my $fh, '<', $file);
    binmode $fh;
    local $/;
    my $content = <$fh>;
    print {$client} $content;
}

# displays a directory listing
sub dir_listing {
    my ($dir, $dir_url, $client) = @_;
    $dir .= '/' unless $dir =~ m!/$!;
    $dir_url .= '/' unless $dir_url =~ m!/$!;

    # print http response
    print {$client} "HTTP/1.1 200$crlf";

    # print mime type
    my ($ext) = ($file =~ /(\.\w+)$/);
    print ${client} "Content-Type: text/html$crlf$crlf";

    # list files
    print ${client} "<html>\n";
    print ${client} "\t<head>\n";
    print ${client} "\t\t<title>Directory Listing</title>\n";
    print ${client} "\t</head>\n";
    print ${client} "\t<body>\n";
    print ${client} "\t\t<h1>$dir_url</h1>\n";
    opendir(my $dh, $dir);
    while (my $file = readdir($dh)) {
        next if $file eq '.' or $file eq '..';
        if (-d "$dir$file") {
            print {$client} "\t\t<a href=\"$dir_url$file\">$file</a><br />\n";
        } else {
            print {$client} "\t\t<a href=\"$dir_url$file\">$file</a><br />\n";
        }
    }
    print ${client} "\t</body>\n";
    print ${client} "</html>\n";
}

# handle a request
sub serve_request {
    my ($client, $client_addr) = @_;

    # print the date/time if necessary
    print "\n" . localtime() . "\n" if (!$last_request or $last_request < time() - 5);
    $last_request = time();

    # get ip info and print it if it has changed
    my $client_ip = inet_ntoa((sockaddr_in($client_addr))[1]);
    if ($client_ip ne $last_ip) {
        $last_ip = $client_ip;
        print "$client_ip\n";
    }

    # fetch header
    my ($header, %headers, $method, $get, $query_string);
    while (my $line = <$client>) {
        last if $line eq $crlf;
        $line =~ s/$crlf$//o or error('An error occured while parsing request headers.');

        # environmental variables
        if (%headers) {
            error('An error occured while parsing request headers.') unless $line =~ /^(\S+):\s+([\s\S]+)$/o;
            my ($name, $value) = (lc($1), $2);
            $name =~ tr/-/_/;
            $name = "http_$name" unless ($name eq 'content_type' or $name eq 'content_length');
            $headers{$name} = $value;
        }

        # get/post header
        else {
            error('An error occured while parsing request headers.') unless $line =~ /^(GET|POST) ([^?\s]+)\??(\S+)?/o;
            ($method, $get, $query_string) = ($1, $2, $3);
            $headers{'request_uri'}    = $get;
            $headers{'query_string'}   = $query_string if $query_string;
            $headers{'request_method'} = $method;

            # security check (this could be better... but this is a quick and dirty web server ;-P)
            if (scalar(@{[($get =~ m!\.\.!g)]}) >= scalar(@{[($get =~ m!/!g)]})) {
                request_404($client);
                last SERVE_REQUEST;
            }
        }
    }

    # add ip to headers
    $headers{'remote_addr'} = $client_ip;

    # parse header
    print "$method: $get" . ( $query_string ? "?$query_string" : "" ) . "\n";

    # if get is for a style file
    if ($get =~ /^$oyster::CONFIG{styles_url}([\s\S]*)$/) {
        my $file = $1;

        # if the file exists
        if (-f "$oyster::CONFIG{site_path}styles/$file") {
            print "\tServing style.\n";
            serve_file("$oyster::CONFIG{site_path}styles/$file", $client);
        }
        
        # if the file is a directory
        elsif (-d "$oyster::CONFIG{site_path}styles/$file") {
            print "\tDisplaying directory listing.\n";
            dir_listing("$oyster::CONFIG{site_path}styles/$file", $get, $client);
        }

        # a 404 page
        else {
            print "\tStyle file not found, displaying 404 error.\n";
            request_404($client);
        }
    }

    # if the request is for a site file
    elsif ($get =~ /^$oyster::CONFIG{site_file_url}([\s\S]*)$/) {
        my $file = $1;

        # if the file exists
        if (-f "$oyster::CONFIG{site_file_path}$file") {
            print "\tServing file.\n";
            serve_file("$oyster::CONFIG{site_file_path}$file", $client);
        }

        # if the file is a directory
        elsif (-d "$oyster::CONFIG{site_file_path}$file") {
            print "\tDisplaying directory listing.\n";
            dir_listing("$oyster::CONFIG{site_file_path}$file", $get, $client);
        }

        # a 404 page
        else {
            print "\tFile not found, displaying 404 error.\n";
            request_404($client);
        }
    }

    # if the request is for a shared file
    elsif ($get =~ /^$oyster::CONFIG{shared_file_url}([\s\S]+)$/) {
        my $file = $1;

        # if the file exists
        if (-f "$oyster::CONFIG{shared_file_path}$file") {
            print "\tServing file.\n";
            serve_file("$oyster::CONFIG{shared_file_path}$file", $client);
        }

        # if the file is a directory
        elsif (-d "$oyster::CONFIG{shared_file_path}$file") {
            print "\tDisplaying directory listing.\n";
            dir_listing("$oyster::CONFIG{shared_file_path}$file", $get, $client);
        }

        # a 404 page
        else {
            print "\tFile not found, displaying 404 error.\n";
            request_404($client);
        }
    }

    # otherwise, the request goes to oyster
    else {

        # disable output buffering
        local $/;

        # save a copy of the current environment (so things dont spill over between requests)
        my %old_env = %ENV;

        # add variables from the HTTP header to %ENV
        for my $name (keys %headers) {
            $ENV{uc $name} = $headers{$name};
        }

        # execute oyster
        $oyster_executions++;
        print "\tDispatching to Oyster [$oyster_executions]... ";
        my ($pid, $cms_in, $cms_out, $cms_err);
        $pid = open3($cms_in, $cms_out, $cms_err, "perl oyster.pl -site $ENV{oyster_site_id}") or die "$!";
        if ($headers{'content_length'}) {
            my $post = '';
            read $client, $post, $headers{'content_length'};
            print $cms_in $post;
        }

        # get oyster output
        my $out = <$cms_out>;
        Encode::_utf8_on($out);

        # parse out and print http header
        print $client "HTTP/1.1 200$crlf";
        # TODO: uh... why does the header end with 15 12 15 15?
        if ($oyster::CONFIG{'os'} eq 'windows') { # i have no idea why windows does this
            #$out =~ s/^([\s\S]+?)\015\012\015\015\s+//o;
            # TODO: this needs more investigation... something weird is going on
            $out =~ s/^([\s\S]+?)[\015\012]{4}\s+//o;
            print $client $1;
            print $client $crlf . $crlf;
        }
        print $client $out;
        waitpid($pid, 0);
        print "Done.\n";

        # restore the old %ENV
        %ENV = %old_env;
    }
}

# ----------------------------------------------------------------------------
# Copyright
##############################################################################
1;
