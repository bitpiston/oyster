=xml
<document title="Common Gateway Interface Functions">
    <synopsis>
        Functions associated with processing Common Gateway Interface requests
    </synopsis>
    <todo>
        clean up multipart parsing, check out cgi::lite to cover weird corner cases
    </todo>
    <todo>
        clean up this api a bit, some things are needlessly put into functions
    </todo>
    <todo>
        Private/Public sections documentation
    </todo>
=cut

package cgi;

use exceptions;
use event; # necessary because this library is included before event.pm

our @tmp_files; # tmp files created by file uploads
our $max_post_size = 1048576 * 10; # 10 mb

sub uri_encode {
    my $string = shift;
    $string =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;
    return $string;
}

sub uri_decode {
    my $string = shift;
    $string =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $string;
}

=xml
    <function name="start">
        <synopsis>
           Begins a CGI request, processes POST, GET, and COOKIES 
        </synopsis>
        <note>
            Modules should never need to call this function directly, it is called automatically each request.
        </note>
        <prototype>
            cgi::start()
        </prototype>
    </function>
=cut

sub start {

    # process form data
    if ($ENV{'REQUEST_METHOD'} eq 'POST') { # give POST priority over get
        _process_form_get();
        _process_form_post();
    } else {
        _process_form_post();
        _process_form_get();
    }

    # process namespaces
    #_process_namespaces();

    # process cookies
    _process_cookies();
}

=xml
    <function name="end">
        <synopsis>
            Ends a CGI request, cleans up after cgi::start()
        </synopsis>
        <note>
            Modules should never need to call this function directly, it is called automatically each request.
        </note>
        <prototype>
            cgi::end()
        </prototype>
    </function>
=cut

event::register_hook('request_cleanup', 'end', 100);

sub end {

    # delete temporary files
    unlink for @tmp_files; # files may be moved before this is reached, test for failure? test for existence? let it fail?

    # clear cookies/form data (no point in storing it between requests)
    %oyster::INPUT   = ();
    %oyster::COOKIES = ();
}

=xml
    <function name="_process_namespaces">
        <warning>
            Unimplemented
        </warning>
        <synopsis>
            Processes namespaces from the url
        </synopsis>
        <note>
            This is a private function used internally by the Oyster library. Modules should never need to call this function.
        </note>
        <note>
            Namespaces allow you to emulate the query string using the directory path.
        </note>
        <note>
            Oyster urls should never have : in them unless you mean to use namespaces!
        </note>
        <prototype>
            _process_namespaces()
        </prototype>
    </function>
=cut

#sub _process_namespaces {
#    return unless index($REQUEST{'path'}->[-1], ':') > -1;
#    my $namespaces = pop @{$REQUEST{'path'}};
#    my @pairs = split(/;/, $namespaces);
#    for (@pairs) {
#        my ($name, $value) = split /:/;
#        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
#        $value =~ s/\r//g; # fastcgi cant handle carriage returns?
#        $INPUT{$name} = $value;
#    }
#}

=xml
    <function name="_process_form_post">
        <synopsis>
            Processes POST data
        </synopsis>
        <note>
            This is a private function used internally by the Oyster library. Modules should never need to call this function.
        </note>
        <prototype>
            _process_form_post()
        </prototype>
        <todo>
            test multipart processing with more browsers (tested and working: FF/IE/Opera)
        </todo>
    </function>
=cut

sub _process_form_post {

    # process post data if there is any
    return unless $ENV{'CONTENT_LENGTH'};
    my $buffer;
    my $len = 0;
    binmode(STDIN);

    # check for memory consuming attacks
    if ($ENV{'CONTENT_LENGTH'} > $max_post_size) {
        throw 'fatal_error' => "POST data exceeded $max_post_size bytes.";
        my $buffer;
        while (read(STDIN, $buffer, 1024 * 50)) { }
    }

    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

    my ($type) = ($ENV{'CONTENT_TYPE'} =~ /^(.+?);/o);

    # multipart encrypted (for file uploads)
    if ($type eq 'multipart/form-data') {
        my ($boundary) = ($ENV{'CONTENT_TYPE'} =~ /boundary=(\S+)/o);
        chomp($boundary);

        # process $buffer until it is empty
        PROCESS_MULTIPART: while (length($buffer)) {

            # if this a form field
            if ($buffer =~ /^((?:--)?$boundary\015\012([\s\S]+?)\015\012\015\012([\s\S]*?)\015\012)(?:--)?$boundary/) {
                my ($headers, $content) = ($2, $3);

                # remove whatever was read from the buffer
                substr($buffer, 0, length($1), '');

                # parse headers
                my @headers = split(/;\s+?|(?:\015\012)/o, $headers); # most entries are separated by '; ' but Content-Type is on its own line
                my %headers;
                for my $header (@headers) {
                    my ($name, $value) = ($header =~ /^(.+?)\s*(?::|=)\s*(.+)$/o); # some entries are divided by ': ' some by '='
                    if (substr($value, 0, 1) eq '"') { # if the value is quoted
                        $value = substr($value, 1, length($value) - 2); # remove surrounding quotes
                        $value =~ s/\\(?=")//og; # remove escapes before quotes in the value
                    }
                    $headers{lc($name)} = $value;
                }

                # if it is a file
                if ($headers{'filename'}) {

                    # save the temporary file
                    my $tmp_name = file::tmp_name();
                    open(my $tmp_file, '>', $tmp_name);
                    binmode($tmp_file);
                    print $tmp_file $content;
                    close($tmp_file);

                    # add data to %INPUT
                    $oyster::INPUT{$headers{'name'}} = {
                        'filename'     => $headers{'filename'},
                        'content_type' => $headers{'content-type'},
                        'tmp_name'     => $tmp_name,
                    };

                    # make sure the temporary file is deleted at the end of the request
                    push(@tmp_files, $tmp_name);
                }

                # this is a regular form field
                else {

                    # add data to %INPUT
                    $content =~ s/\r\n/\n/og;
                    $content =~ s/\r/\n/og;
                    $oyster::INPUT{$headers{'name'}} = $content;
                }
            }

            # if this is the end of submitted data
            elsif ($buffer =~ /^(?:--)?$boundary--/) {
                last PROCESS_MULTIPART;
            }

            else {
                throw 'fatal_error' => 'Malformed headers.';
            }
        }
    }

    # normal post data
    else {
        my @pairs = split(/&/o, $buffer);
        for (@pairs) {
            my ($name, $value) = split /=/;
            $value =~ tr/+/ /;
            $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/oeg;
            $value =~ s/\r\n/\n/og;
            $value =~ s/\r/\n/og;
            $oyster::INPUT{$name} = $value;
        }
    }
}

=xml
    <function name="_process_form_get">
        <synopsis>
            Processes GET data
        </synopsis>
        <note>
            This is a private function used internally by the Oyster library. Modules should never need to call this function.
        </note>
        <prototype>
            _process_form_get()
        </prototype>
    </function>
=cut

sub _process_form_get {

    # process the query string (if necessary)
    return unless length $ENV{'QUERY_STRING'};
    my @pairs = split(/&/, $ENV{'QUERY_STRING'});
    for (@pairs) {
        my ($name, $value) = split /=/;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/oeg;
        $value =~ s/\r//og; # fastcgi cant handle carriage returns?
        $oyster::INPUT{$name} = $value;
    }
}

=xml
    <function name="_process_cookies">
        <synopsis>
            Processes cookie data
        </synopsis>
        <note>
            This is a private function used internally by the Oyster library. Modules should never need to call this function.
        </note>
        <prototype>
            _process_cookies()
        </prototype>
    </function>
=cut

sub _process_cookies {
    return unless length $ENV{'HTTP_COOKIE'};
    my @pairs = split(/\; /o, $ENV{'HTTP_COOKIE'});
    my $pair;
    foreach $pair (@pairs) {
        my ($key, $value) = split(/=/o, $pair);
        $oyster::COOKIES{$key} = $value;
    }
}

=xml
    <function name="set_cookie">
        <synopsis>
            Sets a cookie
        </synopsis>
        <note>
            If no expiration time is set, the cookie is usually removed when the browser window is closed.
        </note>
        <prototype>
            cgi::set_cookie(string name, string value[, int expires_minutes][, string path][, string domain])
        </prototype>
        <example>
            cgi::set_cookie('last_page_view_time', gmtime(), 60);
        </example>
    </function>
=cut

sub set_cookie {
    my ($name, $value, $expires, $path, $domain) = @_;
    my $cookie = "$name=$value; ";
    $cookie .= 'expires=' . _cookie_date( $expires * 60 ) . '; ' if $expires;
    $cookie .= "path=$path; "     if $path;
    $cookie .= "domain=$domain; " if $domain;
    http::header("Set-Cookie: $cookie");
}

=xml
    <function name="_cookie_date">
        <synopsis>
            Returns a date formatted to be used in a cookie expiration date
        </synopsis>
        <note>
            This is a private function used internally by the Oyster library. Modules should never need to call this function.
        </note>
        <prototype>
            string date = _cookie_date(int epoch_seconds)
        </prototype>
    </function>
=cut

sub _cookie_date {
    my ($day, $month, $num, $time, $year) = split(/\s+/, scalar(gmtime(time() + shift())));
    $num = "0$num" if length($num) == 1;
    return "$day $num-$month-$year $time GMT";
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
