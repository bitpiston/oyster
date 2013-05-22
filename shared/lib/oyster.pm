=xml
<document title="Oyster">
    <synopsis>
        This is a lightweight web application framework, focusing on: speed, flexibility, scalability, and ease of development.  For more information, visit <link uri="http://oyster.bitpiston.com">the official Oyster website</link>.
    </synopsis>
=cut
package oyster;

# our source is UTF-8 ...unless someone is using a bad editor!
#use utf8;

# assume UTF-8 filehandle streams unless told otherwise 
#use open ':encoding(UTF-8)';

# import libraries (can't implement these myself, sadly ;-P)
use DBI;
use Time::HiRes;

# import oyster libraries
use buffer;
use cgi;
use config;
use database;
use datetime;
use email;
use event;
use exceptions;
use file;
use hash;
use http;
use image;
use ipc;
use log;
use math;
use menu;
use module;
use string;
use style;
use url;
use xml;

=xml
    <section title="Global Variables">
        <synopsis>
            These are exported to modules.
        </synopsis>
        <dl>
            <dt>%REQUEST</dt>
            <dd>Data associated with the current request (such as the style, templates, module, action, etc).  This is a good place to store data that you want to persist for only the current request; but be careful to avoid conflicts.</dd>
            <dt>%INPUT</dt>
            <dd>GET/POST data for the current request</dd>
            <dt>%COOKIES</dt>
            <dd>Cookie data for the current request</dd>
            <dt>$DB</dt>
            <dd>The database object</dd>
            <dt>%CONFIG</dt>
            <dd>The Oyster configuration, a combination of config.pl, information from the database, and some values added when Oyster is loaded</dd>
        </dl>
    </section>
=cut

# global variables (exported to modules)
our %REQUEST; # data associated with the current request (such as the style, module template, or module to be executed)
our %INPUT;   # GET/POST data for the current request
our %COOKIES; # cookie data for the current request
our $DB;      # the database object
our %CONFIG;  # oyster configuration, a combination of information from the database, config.pl, and created on the fly; capitalized for consistency with module %CONFIGs

# private variables
my %regex_urls;                       # regular expression urls -- these are loaded once and cached, using the database for regular expression matches is a bad idea
my @request_exception_handlers;       # inner exception handlers for requests
my @request_fatal_exception_handlers; # outer exception handlers for requests

=xml
    <section title="Internals">
        <synopsis>
            These are functions used to run oyster, rarely called by external code (except for launchers).
        </synopsis>
=cut

=xml
        <function name="import">
            <synopsis>
                Exports Oyster variables
            </synopsis>
            <note>
                Can optionally be passed an argument to be imported into a specific package instead of the caller.
            </note>
            <note>
                Import sets: module, launcher, test, daemon (some are NYI or dont export anything)
            </note>
            <prototype>
                oyster::import(string package_name[, string import_set])
            </prototype>
            <prototype>
                use oyster [string import_set]
            </prototype>
            <prototype>
                oyster->import([string import_set])
            </prototype>
        </function>
=cut

sub import {

    # do nothing if oyster has not been loaded yet
    return unless %CONFIG;

    # do nothing if no import set was specified
    return unless length $_[1];

    # figure out which package to import to
    my $pkg = $_[0] ne 'oyster' ? $_[0] : caller();

    # figure out the import set
    my $import_set = $_[1];

    # module
    if ($import_set eq 'module') {

        # functions
        *{ $pkg . '::confirm'      } = \&confirm;
        *{ $pkg . '::confirmation' } = \&confirmation;

        # global variables
        *{ $pkg . '::BASE_URL'       } = \$CONFIG{'url'};
        *{ $pkg . '::DB_PREFIX'      } = \$CONFIG{'db_prefix'};
        *{ $pkg . '::TMP_PATH'       } = \$CONFIG{'tmp_path'};
        *{ $pkg . '::REQUEST'        } = \%REQUEST;
        *{ $pkg . '::COOKIES'        } = \%COOKIES;
        *{ $pkg . '::INPUT'          } = \%INPUT;
        ${ $pkg . '::DB'             } = $DB;
        *{ $pkg . '::CONFIG'         } = \%CONFIG;
        ${ $pkg . '::ADMIN_BASE_URL' } = "$CONFIG{url}admin/";

        # module-specific variables
        my ($module) = ( $pkg =~ /::/ ? ($pkg =~ /^(.+?)::/) : $pkg );
        ${ $pkg . '::module_path'           } = "./modules/$module/"; # no need to reference, these don't change
        ${ $pkg . '::module_admin_base_url' } = "$CONFIG{url}admin/${module}/";
        ${ $pkg . '::module_db_prefix'      } = "$CONFIG{db_prefix}${module}_";
        *{ $pkg . '::config'                } = \%{"${module}::CONFIG"} if $pkg ne $module;
    }

    # launcher
    elsif ($import_set eq 'launcher') {
        # nothing
    }

    # script
    elsif ($import_set eq 'script') {
        $exceptions::disable_logging = 1;

        # global variables
        *{ $pkg . '::BASE_URL'       } = \$CONFIG{'url'};
        *{ $pkg . '::DB_PREFIX'      } = \$CONFIG{'db_prefix'};
        *{ $pkg . '::TMP_PATH'       } = \$CONFIG{'tmp_path'};
        *{ $pkg . '::REQUEST'        } = \%REQUEST;
        *{ $pkg . '::COOKIES'        } = \%COOKIES;
        *{ $pkg . '::INPUT'          } = \%INPUT;
        ${ $pkg . '::DB'             } = $DB;
        *{ $pkg . '::CONFIG'         } = \%CONFIG;
        ${ $pkg . '::ADMIN_BASE_URL' } = "$CONFIG{url}admin/";
    }

    # daemon
    elsif ($import_set eq 'daemon') {
        # todo
    }

    # test
    elsif ($import_set eq 'test') {
        # todo
    }
}

=xml
        <function name="load">
            <synopsis>
                Load Oyster and prepares the oyster environment
            </synopsis>
            <note>
                The optional arguments can be used to tell Oyster to only load certain things.  This can be useful for certain scripts that only need a minimal Oyster environment.
            </note>
            <note>
                All optional arguments default to true.
            </note>
            <note>
                'load_config' determines whether additional configuration data should be loaded from the database.
            </note>
            <note>
                'load_libs' does not determine whether libraries are imported or not, but whether their load event routines are called.
            </note>
            <note>
                'load_request' determines whether Oyster should be prepared to serve page requests.
            </note>
            <note>
                'load_modules' determines whether modules will be loaded.
            </note>
            <prototype>
                oyster::load(hashref configuration[, db_connect => bool][, load_config => bool][, load_modules => bool][, load_libs => bool][, load_request => bool])
            </prototype>
        </function>
=cut

sub load {
    *CONFIG = shift; # alias %CONFIG to the configuration hash passed in, so that the program calling load() gets the full config
    my %options = @_;

    # append misc other values to %CONFIG
    $CONFIG{'tmp_path'}  = './tmp/';
    $CONFIG{'db_prefix'} = $CONFIG{'site_id'} . '_';
    $CONFIG{'daemon_id'} = string::random();

    # enable UTF-8 output and UTF-8 input 
    binmode STDOUT, ':encoding(UTF-8)';
    binmode STDIN, ':encoding(UTF-8)'; # HTTP POST only?

    # load oyster
    try {

        # establish a database connection
        if (!exists $options{'db_connect'} or $options{'db_connect'}) {
            _db_connect();
        }

        # if a database connection was not established, do no more
        else {
            abort();
        }

        # load oyster/site configuration from database
        _load_config() if (!exists $options{'load_config'} or $options{'load_config'});

        # run library initialization event
        if (!exists $options{'load_libs'} or $options{'load_libs'}) {
            event::execute('load_lib');
            event::destroy('load_lib');
        }

        # load modules
        _load_modules($options{'skip_outdated_modules'}) if (!exists $options{'load_modules'} or $options{'load_modules'});

        # load/cache stuff necessary to handle requests
        _load_exception_handlers() if (!exists $options{'load_request'} or $options{'load_request'});
    }
    catch 'db_error', with {
        die shift();
    }
    catch 'perl_error', with {
        die shift();
    };
}

=xml
        <function name="_db_connect">
            <synopsis>
                Establishes a database connection if one isn't already active
            </synopsis>
            <todo>
                Ensure the 'force_reconnect' argument properly re-uses the same database object.
            </todo>
            <prototype>
                _db_connect([bool force_reconnect])
            </prototype>
        </function>
=cut

sub _db_connect {
    return if $DB->{'Active'} and !$_[0]; # note: this autovififies $DB into a hashref if it isn't one

    # establish database connection
    my $dbconfig = $CONFIG{'database'};
    $DB = database::connect(
        'driver'   => $dbconfig->{'driver'},
        'host'     => $dbconfig->{'host'},
        'user'     => $dbconfig->{'user'},
        'password' => $dbconfig->{'pass'},
        'database' => $dbconfig->{'db'},
        'port'     => $dbconfig->{'port'},
    );

    # mysql-specific stuff
    if ($dbconfig->{'driver'} eq 'mysql') {
        $DB->do('set names "utf8"');       # return unicode strings
        $DB->{'AutoCommit'}           = 1; # enable autocommit (required for auto_reconnect)
        $DB->{'mysql_server_prepare'} = 1; # enable server side prepared statements
        $DB->{'mysql_auto_reconnect'} = 1; # automatically reconnect
        #$DB->{'mysql_use_result'}     = 1; # faster/less memory consuming, can block other processes -- disabled: causes problem with multiple fastcgi processes
    }

    # Pg-specific stuff
    elsif ($dbconfig->{'driver'} eq 'Pg') {
        $DB->{'pg_server_prepare'}    = 1; # enable server side prepared statements
    }
}

=xml
        <function name="_load_config">
            <synopsis>
                Loads (or reloads) oyster configuration
            </synopsis>
            <prototype>
                _load_config()
            </prototype>
        </function>
=cut

sub _load_config {

    # load oyster configuration and append it to %CONFIG
    config::load('table' => 'config', 'config_hash' => \%CONFIG);

    # load site configuration and append it to %CONFIG
    config::load('table' => "$CONFIG{db_prefix}config", 'config_hash' => \%CONFIG);
}

=xml
        <function name="_load_modules">
            <synopsis>
                Loads (or reloads) oyster modules
            </synopsis>
            <prototype>
                _load_modules()
            </prototype>
        </function>
=cut

sub _load_modules {
    my $skip_outdated = shift;
    
    # if modules are already loaded, unload them
    module::unload($_) for keys %module::loaded;

    # get a list of enabled modules
    my @modules = module::get_enabled();
    die('No modules were loaded.  Your modules table may have been corrupted.') unless @modules;

    # determine module paths
    module::get_paths(@modules);

    # order modules by dependencies
    @modules = module::order_by_dependencies(@modules);

    # load modules
    my $i = 0;
    for my $module (@modules) {

        # if the module is up to date
        if (module::get_revision($module) == module::get_latest_revision($module)) {

            # if skip_outdated is enabled, ensure all of this module's prereqs have been loaded (they may have been skipped because they are out of date)
            if ($skip_outdated) {
                 my $meta = module::get_meta($module);
                 my $failed_deps = 0;
                 for my $dep (@{$meta->{'requires'}}) {
                     unless (exists $module::loaded{$dep}) {
                         $failed_deps = 1;
                         last;
                     }
                 }
                 module::load($module) unless $failed_deps;
            }

            # otherwise, just load the module as normal
            else {
                module::load($module);
            }
        }

        # if the module needs to be updated
        else {
            die "Module '$module' is out of date.  Please run the update utility." unless $skip_outdated
        }
    } continue { $i++ }

    # execute and destroy the load hook lookup table
    event::execute('load');
    event::destroy('load');
}

=xml
    </section>
    
    <section title="Request Handling">
        <synopsis>
            These functions deal with handling page requests.  Like the above internal functions, should rarely be called by outside code (except for launchers).
        </synopsis>
=cut

=xml
        <function name="request_pre">
            <synopsis>
                Called before each page request
            </synopsis>
            <note>
                This is primarily used to perform updates necessary to keep daemons in sync before the next page should be served.
            </note>
            <prototype>
                oyster::request_pre()
            </prototype>
        </function>
=cut

sub request_pre {

    # signal the request_pre hook
    event::execute('request_pre');
}

=xml
        <function name="request_handler">
            <synopsis>
                Called to handle each page request
            </synopsis>
            <prototype>
                oyster::request_handler()
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

sub request_handler {

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
        event::execute('request_start') if $REQUEST{'handler'} ne 'ajax';
        #event::execute('request_start');

        # execute the selected module and action
        try {
            &{"$REQUEST{module}::$REQUEST{action}"}(@{$REQUEST{'params'}});
        } @request_exception_handlers;
        
        # end the print buffer and save its contents
        my $content = buffer::end_clean();

        # print the header
        style::print_header() if $REQUEST{'handler'} ne 'ajax';
        #style::print_header();

        # print the buffer
        print $content;
        
        # print the navigation menu
        url::print_navigation_xml() if $REQUEST{'handler'} ne 'ajax';
        #url::print_navigation_xml();

        # signal the request_end hook
        event::execute('request_end') if $REQUEST{'handler'} ne 'ajax';
        #event::execute('request_end');

        # print the footer
        print qq~\t<daemon>$CONFIG{daemon_id}</daemon>\n~ if $CONFIG{'debug'} and $REQUEST{'handler'} ne 'ajax';
        #print qq~\t<daemon>$CONFIG{daemon_id}</daemon>\n~ if $CONFIG{'debug'};
        style::print_footer() if $REQUEST{'handler'} ne 'ajax';
        #style::print_footer();

        # signal the request_finish hook
        event::execute('request_finish');
    } @request_fatal_exception_handlers;
}

=xml
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
    url::update_cache() if $CONFIG{'mode'} eq 'fastcgi' and length $REQUEST{'current_url'}->{'module'};     # length check to avoid caching a 404

    # signal the request_cleanup hook
    event::execute('request_cleanup');

    # clean up after any cgi stuff
    cgi::end();

    # clear the request hash
    %REQUEST = ();
}

=xml
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
        http::clear_headers();
        http::header("HTTP/1.1 404 Not Found");
        style::print_header();
        event::execute('request_start');
        my $url = $ENV{'REQUEST_URI'};
        my $referer = xml::entities($ENV{'HTTP_REFERER'}, 'safe');
        $url =~ s!^/!!o;
        $url = xml::entities($CONFIG{'full_url'} . $url, 'safe');
        my $hash = hash::fast($REQUEST{'url'});
        log::status("404 Request\nURL: " . $url . "\nHash: " . $hash. "\nReferer: " . $referer) if $CONFIG{'log_404s'};
        print "\t<error status=\"404\" url=\"" . $url . "\" hash=\"" . $hash . "\" referer=\"" . $referer . "\" />\n";
        url::print_navigation_xml();
        event::execute('request_end');
        #print "\t<url hash=\"" . hash::fast($REQUEST{'url'}) . "\">\n";
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

=xml
    </section>

    <section title="Public API">
        <synopsis>
            The oyster API is a set of functions available to all oyster code and oyster modules.
        </synopsis>
=cut

=xml
        <function name="execute_script">
            <synopsis>
                Executes a script in the shared_path/script/ directory, under the current site ID.
            </synopsis>
            <note>
                The first argument is the filename without the .pl extension.
            </note>
            <prototype>
                string output = oyster::execute_script(string script_name[, array args])
            </prototype>
            <example>
                print execute_script('xslcompiler');
            </example>
        </function>
=cut

sub execute_script {
    my $site   = ($_[0] eq '~nosite' and shift) ? '' : " -site \"$CONFIG{site_id}\"";
    my $script = shift;
    throw 'perl_error' => "Script '$script' does not exist." unless -e "./script/$script.pl";
    my $args;
    $args .= ' "' . shell_escape($_) . '"' for @_;
    return `perl script/$script.pl$site$args`;
}

=xml
        <function name="restart">
            <synopsis>
                Restarts the current script.
            </synopsis>
            <prototype>
                oyster::restart()
            </prototype>
        </function>
=cut

sub restart {
    exec($0, @ARGV);
    exit;
}

=xml
        <function name="perl_require">
            <synopsis>
                Performs a 'require' without Oyster's library search paths.
            </synopsis>
            <note>
                This cannot be used like 'require IO::Socket', you must use 'IO/Socket.pm' instead.
            </note>
            <prototype>
                oyster::perl_require(string filename)
            </prototype>
            <todo>
                Is this necessary? The fact that all of our libs are lowercase should stop conflicts anyways.  This is only a slower, less flexible, version of 'require'
            </todo>
        </function>
=cut

sub perl_require {
    my $file = shift; # the file to include

    # save the current @INC list
    my @OYSTER_INC = @INC;

    # restore the original @INC list
    @INC = @lib::ORIG_INC;

    # include the file
    require $file;

    # restore Oyster's @INC
    @INC = @OYSTER_INC;
}

=xml
        <function name="shell_escape">
            <synopsis>
                Escapes characters to avoid injection when executing shell commands.
            </synopsis>
            <note>
                Currently only escapes double quotes.  The data passed to this function
                assumes that it will be placed inside double quotes when it is passed to
                the shell.
            </note>
            <prototype>
                string escaped_string = oyster::shell_escape(string)
            </prototype>
            <todo>
                Make this better, should have different mechanics for different shells.
            </todo>
        </function>
=cut

sub shell_escape {
    my $string = shift;
    $string =~ s/"/\"/g;
    return $string;
}

=xml
        <function name="dump">
            <synopsis>
                Uses Data::Dumper to return a dump of a variable.
            </synopsis>
            <note>
                This is simply here for convenience.
            </note>
            <note>
                It is probably not a good idea to use this in production code, as it loads Data::Dumper once it is called, which requires a significant amount of memory.
            </note>
            <note>
                Like Data::Dumper::Dumper, be sure to pass a ref.
            </note>
            <prototype>
                string = oyster::dump(ref)
            </prototype>
        </function>
=cut

sub dump {
    require Data::Dumper;
    return Data::Dumper::Dumper(@_);
}

sub parse_user_agent {
    return if exists $REQUEST{'parsed_user_agent'};
    my $ua = $ENV{'HTTP_USER_AGENT'};
    if    ($ua =~ m!Presto/(\d+.\d+.\d+)!o) {
        $REQUEST{'ua_render_engine'}         = 'presto';
        $REQUEST{'ua_render_engine_version'} = $1;
        if ($ua =~ m!Opera/(?:(\d+)\.\d+)!o) {
            $REQUEST{'ua_browser'}           = 'opera';
            $REQUEST{'ua_browser_version'}   = $1;
        }
    }
    elsif ($ua =~ m!MSIE (?:(\d+)\.(\d+))!o) {
        $REQUEST{'ua_render_engine'}         = 'trident';
        $REQUEST{'ua_render_engine_version'} = $1 . '.' . $2;
        $REQUEST{'ua_browser'}               = 'msie_' . $1;
        $REQUEST{'ua_browser_version'}       = $1;
    }
    elsif ($ua =~ m!Gecko/(\d+)!o) {
        $REQUEST{'ua_render_engine'}         = 'gecko';
        $REQUEST{'ua_render_engine_version'} = $1;
        if ($ua =~ m!Camino/(?:(\d+)\.\d+\.\d+) \(like Firefox!o) {
            $REQUEST{'ua_browser'}           = 'camino';
            $REQUEST{'ua_browser_version'}   = $1;
        }
        elsif ($ua =~ m!Firefox/(\d+)!o) {
            $REQUEST{'ua_browser'}           = 'firefox';
            $REQUEST{'ua_browser_version'}   = $1;
        }
    }
    #elsif ($ua =~ m!AppleWebKit(?:/(\d(?:\.\d)+))?!o) {
    elsif ($ua =~ m!AppleWebKit(?:/(\d(?:\.\d)?))?!o) {
        $REQUEST{'ua_render_engine'}         = 'webkit';
        $REQUEST{'ua_render_engine_version'} = $1;
        if ($ua =~ m!Chrome\/(?:(\d+)\.\d+\.\d+\.\d+) Safari!o) {
            $REQUEST{'ua_browser'}           = 'chrome';
            $REQUEST{'ua_browser_version'}   = $1;
        }
        elsif ($ua =~ m!Version/(?:(\d+)\.\d+(?:\.\d+)?)(?: Mobile/\w+)? Safari!o) {
            $REQUEST{'ua_browser'}           = 'safari';
            $REQUEST{'ua_browser_version'}   = $1;
        }
        
    }
    #elsif ($ua =~ m!KHTML(?:/(\d(?:\.\d)+))?!o) {
    elsif ($ua =~ m!KHTML(?:/(\d(?:\.\d)?))?!o) {
        $REQUEST{'ua_render_engine'}         = 'khtml';
        $REQUEST{'ua_render_engine_version'} = $1;
    }
    
    $REQUEST{'ua_browser'} = 'other' if !defined $REQUEST{'ua_browser'};
    
    # Check for the OS
    my %systems = (
        'iOS'            => qr/(?:iPhone)|(?:iPad)|(?:iOS)/o,
        'Windows 3.11'   => qr/Win16/o,
        'Windows 95'     => qr/(?:Windows 95)|(?:Win95)|(?:Windows_95)/o, 
        'Windows 98'     => qr/(?:Windows 98)|(?:Win98)/o,
        'Windows 2000'   => qr/(?:Windows NT 5.0)|(?:Windows 2000)/o,
        'Windows XP'     => qr/(?:Windows NT 5.1)|(?:Windows XP)/o,
        'Windows 2003'   => qr/(?:Windows NT 5.2)/o,
        'Windows Vista'  => qr/(?:Windows NT 6.0)|(?:Windows Vista)/o,
        'Windows 7'      => qr/(?:Windows NT 6.1)|(?:Windows 7)/o,
        'Windows NT' => qr/(?:Windows NT 4.0)|(?:WinNT4.0)|(?:WinNT)|(?:Windows NT)/o,
        'Windows ME'     => qr/Windows ME/o,
        'OpenBSD'        => qr/OpenBSD/o,
        'FreeBSD'        => qr/FreeBSD/o,
        'SunOS'          => qr/SunOS/o,
        'Linux'          => qr/(?:Linux)|(?:X11)/o,
        'Mac'            => qr/(?:Mac_PowerPC)|(?:Macintosh)/o,
        'QNX'            => qr/QNX/o,
        'BeOS'           => qr/BeOS/o,
        'OS/2'           => qr/OS\/2/o,
        'Search Bot'     => qr/(?:nuhk)|(?:Googlebot)|(?:Yammybot)|(?:Openbot)|(?:Slurp\/cat)|(?:msnbot)|(?:ia_archiver)/o
    );
    foreach my $os (keys %systems) { 
        if ($ua =~ $systems{$os}) {
            $REQUEST{'ua_os'} = $os;
            last;
        }
    }
    $REQUEST{'parsed_user_agent'} = undef;
}

=xml
    </section>

    <section title="Exported Functions">
        <synopsis>
            Similar in purpose to the Oyster API, but these are automatically exported to modules.
        </synopsis>
=cut

=xml
        <function name="confirm">
            <synopsis>
                Prompts a user for confirmation.  If confirmation has not been gotten,
                calls abort().  If confirmation has been gotten, does nothing.
            </synopsis>
            <note>
                This uses the &lt;confirm&gt; xml node, styled in shared/styles/source.xsl
            </note>
            <prototype>
                confirm(string message)
            </prototype>
            <todo>
                This should preserve POST data.
            </todo>
            <example>
                confirm("Are you sure you want to delete everything on your hard drive?");
                `rm -rdf /*`;
            </example>
        </function>
=cut

sub confirm {
    return if ($ENV{'REQUEST_METHOD'} eq 'POST' and $oyster::INPUT{'confirm'});
    my $text = shift;
    print "\t<confirm>$text</confirm>\n";
    abort();
}

=xml
    <function name="confirmation">
        <synopsis>
            Prints a confirmation message.
        </synopsis>
        <prototype>
            confirmation(string confirmation_message[, forward_options])
        </prototype>
        <example>
            confirmation('Something happened.', $BASE_URL => 'Return to the home page.');
        </example>
    </function>
=cut

sub confirmation {
    my ($message, %options) = @_;
    if (%options) {
        print "\t<confirmation>\n";
        print "\t\t$message\n";
        print "\t\t<options>\n";
        foreach (keys %options) {
            print "\t\t\t<option url=\"$options{$_}\">$_</option>\n";
        }
        print "\t\t</options>\n";
        print "\t</confirmation>\n";
    } else {
        print "\t<confirmation>$message</confirmation>\n";
    }
}

=xml
    </section>
</document>
=cut

1;

# Copyright BitPiston 2008

