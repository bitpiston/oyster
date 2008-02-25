package oyster::request;

=xl
        <function name="pre">
            <synopsis>
                Called before each page request
            </synopsis>
            <note>
                This is primarily used to perform updates necessary to keep daemons in sync before the next page should be served.
            </note>
            <prototype>
                oyster::request::pre()
            </prototype>
        </function>
=cut

sub pre {
    ipc::update();
}

=xl
        <function name="handler">
            <synopsis>
                Called to handle each page request
            </synopsis>
            <prototype>
                oyster::request::handler()
            </prototype>
            <note>
                <p>
                    The output buffer used here is a necessary evil (the header
                    must know which .xsl file to include, but that is not known
                    until the action is executed). However, it is a
                    vulnerability.  Perl cannot free memory back to the operating
                    system once it has claimed it, so if the buffer becomes
                    excessively large, the process will hog memory even after the
                    buffer is cleared.
                </p>
                <p>
                    This is possible to work around by wrapping your action in the
                    following code:
                    <example>
                        # style::include() all necessary styles before doing this...
                        buffer::end();
                        print::header();
                        # code here that may potentially print lots of xml
                        buffer::start();
                    </example>
                </p>
                <p>
                    However, this will NOT help if the request requires SSXSLT.
                    There is currently no way to work around this.
                </p>
            </note>
            <todo>
                Possibly make an option that will buffer to a file instead of
                to memory.
            </todo>
        </function>
=cut

sub handler {

    # remember the time this request started (for some reason putting this with the rest of %REQUEST's declaration causes completely random times to be spat out)
    my $start = Time::HiRes::gettimeofday();

    # handle the request
    try {

        # create a new request hash
        %REQUEST = (
            'style'       => $CONFIG{'default_style'},  # the style to display this page with
            'templates'   => [],                        # a list of templates to use
            'url'         => '',                        # the current url, without leading or trailing slashes
            'current_url' => {},                        # hashref of current url's meta data
            'module'      => '',                        # the module that is being executed this request
            'action'      => '',                        # the action to execute in the selected module
            'params'      => [],                        # any parameters to pass to that action
            'start_time'  => $start,                    # used for benchmarking
            #'method'      => $ENV{'REQUEST_METHOD'},    # TODO: keep this? created because it can be a simple misspelling for $ENV{'REQUEST_METHOD'}
        );

        # uhhh not sure why this is needed.... the query string env variable isnt being populated properly (fastcgi issue?)
        if ((my $query_begin = index($ENV{'REQUEST_URI'}, '?')) != -1) {
            $ENV{'QUERY_STRING'} = substr($ENV{'REQUEST_URI'}, $query_begin + 1);
            $ENV{'REQUEST_URI'}  = substr($ENV{'REQUEST_URI'}, 0, $query_begin);
        }

        # get url
        if (length $ENV{'REQUEST_URI'} > 1) { # 1 because it's always at least a /
            $REQUEST{'url'} = $ENV{'REQUEST_URI'};
            $REQUEST{'url'} =~ s!^/!!o; # remove leading /
            $REQUEST{'url'} =~ s!/$!!o; # remove trailing /
        } else {
            $REQUEST{'url'} = $CONFIG{'default_url'};
        }

        # process cgi data
        cgi::start();

        # match the current url to an action

        # if the url is cached
        if (exists $url::cache{ $REQUEST{'url'} }) {
            $REQUEST{'current_url'} = $url::cache{ $REQUEST{'url'} };
            $REQUEST{'module'}      = $REQUEST{'current_url'}->{'module'};
            $REQUEST{'action'}      = $REQUEST{'current_url'}->{'function'};
            push @{$REQUEST{'params'}}, split(/\0/, $REQUEST{'current_url'}->{'params'}) if length $REQUEST{'current_url'}->{'params'}; # TODO: is this if necessary?
        }

        # fetch action from the database
        else {
            $url::fetch_by_hash->execute(hash::fast($REQUEST{'url'}));
            if ($url::fetch_by_hash->rows() == 1) {
                my $params;
                $REQUEST{'current_url'} = $url::fetch_by_hash->fetchrow_hashref();
                $REQUEST{'module'}      = $REQUEST{'current_url'}->{'module'};
                $REQUEST{'action'}      = $REQUEST{'current_url'}->{'function'};
                push @{$REQUEST{'params'}}, split(/\0/, $REQUEST{'current_url'}->{'params'}) if length $REQUEST{'current_url'}->{'params'}; # TODO: is this if necessary?
            } else {
                my $found_matching_regex_url = 0; # could remove this and just check for $REQUEST{'current_url'}
                for my $url_regex (keys %url::regex_urls) {
                    next unless $REQUEST{'url'} =~ /$url_regex/; # should cache these
                    $REQUEST{'current_url'} = $url::regex_urls{$url_regex};
                    $REQUEST{'module'}      = $REQUEST{'current_url'}->{'module'};
                    $REQUEST{'action'}      = $REQUEST{'current_url'}->{'function'};
                    push @{$REQUEST{'params'}}, $1, $2, $3, $4, $5, $6, $7, $8, $9;
                    $found_matching_regex_url = 1;
                    last;
                }
                throw 'request_404' unless $found_matching_regex_url == 1;
            }
        }

        # set the handler if this is an ajax request
        $REQUEST{'handler'} = 'ajax' if $INPUT{'handler'} eq 'ajax';

        # signal the request_init hook
        event::execute('request_init');

        # begin a print buffer (Why: a print buffer is necessary because the .xsl file to use is not known until an action is executed, and that must be printed in the header)
        buffer::start();

        # signal the request_start hook
        #event::execute('request_start') if $REQUEST{'handler'} ne 'ajax';
        event::execute('request_start');

        # execute the selected module and action
        try {
            &{"$REQUEST{module}::$REQUEST{action}"}(@{$REQUEST{'params'}});
        } @request_exception_handlers;

        # end the print buffer and save its contents
        my $content = buffer::end_clean();

        # print the header
        style::print_header();

        # print the buffer
        print $content;

        # print the navigation menu
        url::print_navigation_xml();

        # signal the request_end hook
        #event::execute('request_end') if $REQUEST{'handler'} ne 'ajax';
        event::execute('request_end');

        # print the footer
        print qq~\t<daemon>$CONFIG{daemon_id}</daemon>\n~ if $CONFIG{'debug'};
        style::print_footer();

        # signal the request_finish hook
        event::execute('request_finish');
    } @request_fatal_exception_handlers;
}

=xl
        <function name="request_cleanup">
            <synopsis>
                Performed after request_handler, after the connection is closed
            </synopsis>
            <note>
                Hooking into request_cleanup is favorable to request_finish (unless you have a good reason), since request_finish hooks should not print anything anyways.
            </note>
            <warning>
                request_cleanup does NOT trap exceptions! (TODO!)
            </warning>
            <prototype>
                oyster::request_cleanup()
            </prototype>
        </function>
=cut

sub request_cleanup {

    # update the url cache
    url::update_cache() if $CONFIG{'mode'} eq 'fastcgi';

    # signal the request_cleanup hook
    event::execute('request_cleanup');

    # clean up after any cgi stuff
    cgi::end();

    # clear the request hash
    %REQUEST = ();
}

=xl
        <function name="_load_exception_handlers">
            <synopsis>
                Prepares the exception handlers necessary to serve a page request.
            </synopsis>
            <prototype>
                _load_exception_handlers()
            </prototype>
        </function>
=cut

sub _load_exception_handlers {

    @request_exception_handlers =
    catch 'validation_error', with {
        my @msgs = @_;
        for my $msg (@msgs) {
            my $error = xml::entities($msg);
            print "\t<error>$error</error>\n";
        }
        abort(1);
    }
    catch 'db_error', with {
        my $log_msg = shift;
        print "\t<internal_error" . (length $CONFIG{'error_message'} ? ">$CONFIG{'error_message'}</internal_error" : ' /' ) . ">\n";
        if ($CONFIG{'debug'}) {
            print "\t<literal>";
            print "Executing Function:\n$REQUEST{module}::$REQUEST{action} (" . join(', ', @{$REQUEST{'params'}}) . ")\n";
            print "Database Error:\n" . xml::entities($log_msg) . "\n";
            print "Trace:\n" . exceptions::trace();
            print "</literal>\n";
        }
        log::error("Executing: $REQUEST{module}::$REQUEST{action} (" . join(', ', @{$REQUEST{'params'}}) . ")\n$log_msg\n") if $log_msg;
        abort();
    }
    catch 'permission_error', with {
        print "\t<error>You do not have permission to access this page.</error>\n";
        abort();
    }
    catch 'perl_error', with {
        my $error = shift;
        print "\t<internal_error" . (length $CONFIG{'error_message'} ? ">$CONFIG{'error_message'}</internal_error" : ' /' ) . ">\n";
        if ($CONFIG{'debug'}) {
            print "\t<literal>";
            print "Executing Function:\n$REQUEST{module}::$REQUEST{action} (" . join(', ', @{$REQUEST{'params'}}) . ")\n";
            print "Perl Error:\n" . xml::entities($error);
            print "Trace:\n" . exceptions::trace();
            print "</literal>\n";
        }
        log::error("Executing: $REQUEST{module}::$REQUEST{action} (" . join(', ', @{$REQUEST{'params'}}) . ")\n$error\n");
        abort();
    };

    @request_fatal_exception_handlers =
    catch 'request_404', with {
        buffer::end_clean();
        event::execute('request_init');
        #http::header("HTTP/1.1 404 Not Found"); # sending this makes the web server use its own 404 page -- TODO: make that an option?
        style::print_header();
        event::execute('request_start');
        print "\t<error status=\"404\" />\n";
        event::execute('request_end');
        style::print_footer();
        event::execute('request_finish');
        abort();
    }
    # these errors don't use $CONFIG{error_message} since it may contain xhtml
    catch 'db_error', with {
        my $error = shift;
        buffer::end_all_clean();
        http::clear_headers();
        http::header("Content-Type: text/plain");
        http::print_headers();
        print "An internal error has occured.\n";
        if ($CONFIG{'debug'}) {
            print "\nDatabase Error:\n$error\n";
            print "\n" . exceptions::trace() . "\n";
        }
        log::error($error);
        abort();
    }
    catch 'fatal_error', with { # this is used for fatal errors that are not really perl or database errors (such as malformed http headers)
        my $error = shift;
        buffer::end_all_clean();
        http::clear_headers();
        http::header("Content-Type: text/plain");
        http::print_headers();
        print "Fatal Error:\n$error\n";
        if ($CONFIG{'debug'}) {
            print "\n$error\n";
            print "\n" . exceptions::trace() . "\n";
        }
        abort();
    }
    catch 'perl_error', with {
        my $error = shift;
        buffer::end_all_clean();
        http::clear_headers();
        http::header("Content-Type: text/plain");
        http::print_headers();
        print "An internal error has occured.\n";
        if ($CONFIG{'debug'}) {
            print "Perl Error:\n$error\n";
            print "\n" . exceptions::trace() . "\n";
        }
        log::error($error);
        abort();
    };
}

1;
