=xml
<document title="Oyster">
    <synopsis>
        This is a lightweight web application framework, focusing on: speed, flexibility, scalability, and ease of development.  For more information, visit <link uri="http://oyster.bitpiston.com">the official Oyster website</link>.
    </synopsis>
=cut
package oyster;

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
use menu;
use module;
use string;
use style;
use url;
use xml;

# global variables (exported to modules)
our %REQUEST; # data associated with the current request (such as the style, module template, or module to be executed) 
our %INPUT;   # GET/POST data for the current request
our %COOKIES; # cookie data for the current request
our $DB;      # the database object

# private variables (not exported by default)
our %CONFIG;                        # oyster configuration, a combination of information from the database, config.pl, and created on the fly; capitalized for consistency with module %CONFIGs
our $daemon_id = string::random();  # a unique id for this instance of oyster

my %regex_urls;                       # regular expression urls -- these are loaded once and cached, using the database for regular expression matches is a bad idea
my @request_exception_handlers;       # inner exception handlers for requests
my @request_fatal_exception_handlers; # outer exception handlers for requests
my %delayed_imports;                  # if packages 'use oyster' before oyster is loaded, delay their import until it is

=xml
    <section title="Internals">
        <synopsis>
            These are functions used to run oyster, rarely called by external code (except for launchers).
        </synopsis>
=cut

# Description:
#   called to load oyster and prepare the oyster environment
# Notes:
#   * The optional argument load_modules defaults to true, this is used by
#     some outside utilities to only load the oyster config and library,
#     but not the modules.
#   * ditto for load_libs -- note: load_libs does not actually determine
#     whether libraries are loaded or not, but only whether their load
#     routines are executed (which often depend on the database connection)
#   * ditto for load_request -- note: load_request determines whether this
#     daemon should be prepared to serve page requests or not.
#   * ditto for db_connect
#   * Some of the above options rely on others.  None of them can be performed
#     without db_connect.  Some dependencies cannot be known until runtime;
#     use these options with caution.
# Prototype:
#   oyster::load(hashref configuration[, db_connect => bool][, load_config => bool][, load_modules => bool][, load_libs => bool][, load_request => bool])
sub load {
    my ($conf, %options) = @_;

    # default options
    for my $option (qw(db_connect load_config load_modules load_libs load_request)) {
        $options{$option} = 1 unless (exists $options{$option} and !$options{$option});
    }

    # save a permanent copy of the configuration options passed to load()
    %CONFIG = %{$conf};

    # change $conf into a reference to the new %CONFIG
    # - this destroys the now-useless $conf variable (which is a package variable, so it isnt GC'd), but points it to exactly the same data
    $_[0] = \%CONFIG; # have to do this via @_ to change the original variable

    # enable UTF8 output
    binmode STDOUT, ':utf8';

    try {

        # establish a database connection
        if ($options{'db_connect'}) {
            _db_connect();
        } else { # disable these options since they may contain db stuff
            $options{'load_config'}  = 0;
            $options{'load_modules'} = 0;
            $options{'load_libs'}    = 0;
            $options{'load_request'} = 0;
        }

        # load oyster/site configuration from database
        if ($options{'load_config'}) {
            _load_config();

            # perform delayed imports
            _delayed_imports();
        }

        # run library initialization
# TODO: is this event being used properly?
        event::execute('load_lib') if $options{'load_libs'};
        event::destroy('load_lib');

        # load modules
        _load_modules() if $options{'load_modules'};

        # load/cache stuff necessary to handle requests
        _load_exception_handlers() if $options{'load_request'};
    }
    catch 'db_error', with {
        my $error = shift;
        die $error;
    }
    catch 'perl_error', with {
        my $error = shift;
        die $error;
    };
}

sub _delayed_imports {
    for my $pkg (keys %delayed_imports) {
        oyster::import($pkg, $delayed_imports{ $pkg });
    }
    undef %delayed_imports;
}

# Description:
#   Establish a database connection if one isn't already active
# Notes:
#   * This must be called with $CONFIG{'database'} available!
# Prototype:
#   oyster::_db_connect([bool force_reconnect])
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
        $DB->{'mysql_server_prepare'} = 0; # disable server side prepared statements
        $DB->{'mysql_auto_reconnect'} = 1; # automatically reconnect
        #$DB->{'mysql_use_result'}     = 1; # faster/less memory consuming, can block other processes -- disabled: causes problem with multiple fastcgi processes
    }

    # Pg-specific stuff
    elsif ($dbconfig->{'driver'} eq 'Pg') {
        $DB->{'pg_server_prepare'}    = 0; # disable server side prepared statements
    }

    $CONFIG{'db_prefix'} = $CONFIG{'site_id'} . '_';
}

# Description:
#   Loads (or reloads) oyster configuration
# Prototype:
#   oyster::_load_config()
sub _load_config {

    # establish a database connection
    _db_connect();

    # load oyster configuration and append it to %CONFIG
    config::load('table' => 'config', 'config_hash' => \%CONFIG);

    # load site configuration and append it to %CONFIG
    config::load('table' => "$CONFIG{db_prefix}config", 'config_hash' => \%CONFIG);

    # append misc other values to %CONFIG
    $CONFIG{'tmp_path'} = "$CONFIG{shared_path}tmp/";
}

# Description:
#   Loads (or reloads) oyster modules
# Prototype:
#   oyster::_load_modules()
sub _load_modules {

    # if modules are already loaded, unload them
    module::unload($_) for keys %module::loaded;

    # get a list of enabled modules
    my @modules;
    my $query = $DB->query("SELECT id FROM modules WHERE site_$CONFIG{site_id} = '1'");
    while (my $module = $query->fetchrow_arrayref()) {
        push @modules, $module->[0];
    }
    die('No modules were loaded.  Your modules table may have been corrupted.') unless @modules;

    # order modules by dependencies
    @modules = module::order_by_dependencies(@modules);

    # load modules
    for my $module (@modules) {
        die "Module '$module' is out of date.  Please run the update utility." unless module::get_revision($module) == module::get_latest_revision($module);
        module::load($module);
    }

    # execute and destroy the load hook lookup table
    event::execute('load');
    event::destroy('load');
}

# Description:
#   Called before each page request
# Prototype:
#   oyster::request_pre()
sub request_pre {

    # perform any necessary IPC
    ipc::do();
}

# Description:
#   Called to handle each page request
# Prototype:
#   oyster::request_handler()
sub request_handler {

    # remember the time this request started (for some reason putting this with the rest of %REQUEST's declaration completely random times are spat out)
    my $start = Time::HiRes::gettimeofday();

    # handle the request
    try {

        # create a new request hash
        %REQUEST = (
            'style'       => $CONFIG{'default_style'},  # the style to display this page with
            'templates'   => [],                        # a list of templates to use
            'url'         => '',                        # join('/', @{$REQUEST{'path'})
            'current_url' => {},                        # hashref of current url's data
            'module'      => '',                        # the module that is being executed this request
            'action'      => '',                        # the action to execute in the selected module
            'params'      => [],                        # any parameters to pass to that action
            'start_time'  => $start,                    # used for benchmarking
            #'method'      => $ENV{'REQUEST_METHOD'},    # TODO: keep this? created because it can be a simple misspelling for $ENV{'REQUEST_METHOD'}
        );

        # uhhh not sure why this is needed.... the query string env variable isnt being populated properly (fastcgi issue?)
        if ((my $query_begin = index($ENV{'REQUEST_URI'}, '?')) != -1) {
            $ENV{'QUERY_STRING'} = substr($ENV{'REQUEST_URI'}, $query_begin + 1);
            $ENV{'REQUEST_URI'} = substr($ENV{'REQUEST_URI'}, 0, $query_begin);
        }

        # get url
        if (length($ENV{'REQUEST_URI'}) > 1) { # 1 because it's always at least a /
            $REQUEST{'url'} = $ENV{'REQUEST_URI'};
            $REQUEST{'url'} =~ s!^/!!o; # remove leading /
            $REQUEST{'url'} =~ s!/$!!o; # remove trailing /
        } else {
            $REQUEST{'url'} = $CONFIG{'default_url'};
        }

        # process cgi data
        cgi::start();

        # match the current url to an action

        # fetch action from the database
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
            throw 'request_404' unless $found_matching_regex_url;
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
        print qq~\t<daemon>$daemon_id</daemon>\n~ if $CONFIG{'debug'};
        style::print_footer();

        # signal the request_finish hook
        event::execute('request_finish');
    } @request_fatal_exception_handlers;
}

# Description:
#   Performed after request_handler, after the connection is closed
# Notes:
#   * Hooking into request_cleanup is favorable to request_finish (unless you
#     have a good reason), since request_finish hooks should not print
#     anything anyways.  The only difference is that request_finish traps
#     exceptions.
# TODO:
#   * Hmmm... untrapped exceptions..
# Prototype:
#   oyster::request_cleanup()
sub request_cleanup {

    # signal the request_cleanup hook
    event::execute('request_cleanup');

    # clear the request hash
    %REQUEST = ();
}

#
# Exception Handlers
#

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

=xml
    </section>

    <section title="API">
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
    my $script = shift;
    throw 'perl_error' => "Script '$script' does not exist." unless -e "./script/$script.pl";
    my $args;
    $args .= ' "' . shell_escape($_) . '"' for @_;
    return scalar(`perl script/$script.pl -site "$CONFIG{site_id}"$args`);
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
                
            </synopsis>
            <note>
                
            </note>
            <prototype>
                
            </prototype>
        </function>
=cut

sub dump {
    require Data::Dumper;
    return Data::Dumper::Dumper(@_);
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
                `rm -f /*.*`;
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
=cut

# Description:
#   Exports Oyster variables
# Notes::
#   * Can optionally be passed an argument to be imported into a specific
#     package instead of the caller.
#   * Import sets: module, launcher
# Prototype:
#   oyster::import(string package_name[, string import_set])
#   or
#   use oyster [string import_set]
#   or
#   oyster->import([string import_set])
sub import {

    # do nothing if no import set was specified
    return unless length $_[1];

    # figure out which package to import to
    my $pkg = $_[0] ne 'oyster' ? $_[0] : caller();

    # figure out the import set
    my $import_set = $_[1];

    # if oyster has not yet been loaded, delay this import
    unless (%CONFIG) {
        $delayed_imports{ $pkg } = $import_set;
        return;
    }

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
        ${ $pkg . '::module_path'           } = "$CONFIG{shared_path}modules/$module/"; # no need to reference, these don't change
        ${ $pkg . '::module_admin_base_url' } = "$CONFIG{url}admin/${module}/";
        ${ $pkg . '::module_db_prefix'      } = "$CONFIG{db_prefix}${module}_";
        *{ $pkg . '::config'                } = \%{"${module}::CONFIG"} if $pkg ne $module;
    }

    # launcher
    elsif ($import_set eq 'launcher') {
        # nothing
    }

    # daemon
    elsif ($import_set eq 'daemon') {
        # todo
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008

