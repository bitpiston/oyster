##############################################################################
# Oyster Console Library
# ----------------------------------------------------------------------------
# This is used by console.pl to execute commands in a Oyster environment.
# ----------------------------------------------------------------------------
package oyster::console;

# use oyster libraries
use exceptions;

# use perl libraries
use Data::Dumper;

# starts a console session
sub start {

    # hello world
    print "Welcome to the Oyster console.\n\n";
    print "The Oyster console allows you to execute perl code directly inside of an Oyster environment.\n\n";
    print "For help type 'help' and hit enter.\n\n";

    # execute input
    my $buffer = '';
    while (print "#>" and my $line = <STDIN>) {
        chomp($line);
        if ($line =~ s!/$!!) {
            $buffer .= "$line\n";
            next;
        }
        try {
            my $out = oyster::_console_execute($buffer . $line);
            $buffer = '';
            if ($@) {
                my $errstr = $@;
                chomp($errstr);
                print "! $errstr\n";
            } else {
                print "\n";
                print Dumper($out) ."\n" if defined $out;
            }
        }
        # TODO: multiple validation errors (see oyster.pm)
        catch 'validation_error', with {
            my $error = shift;
            chomp($error);
            print "Validation Error:\n$error\n";
            abort(1);
        }
        catch 'db_error', with {
            my $error = shift;
            chomp($error);
            print "Database Error:\n$error\n" . misc::trace() . "\n";
            abort();
        }
        catch 'permission_error', with {
            print "Permission Error:\n" . misc::trace() . "\n";
            abort();
        }
        catch 'perl_error', with {
            my $error = shift;
            chomp($error);
            print "Perl Error:\n$error\n" . misc::trace() . "\n";
            abort();
        };
    }
}

package oyster;

# used by oyster::console to eval a statement inside the oyster namespace
sub _console_execute {
    my $cmd = shift;
    return eval $cmd;
}

# simulate a page request
sub request {
    my $url = shift;
    $url = "/$url" unless $url =~ m!^/!;
    $url .= '/'    if     $url !~ m!/$! and length $url > 1;
    $ENV{'REQUEST_URI'} = $url;

    # do initialization work
    oyster::request_pre();

    # handle the user's request
    oyster::request_handler();

    # do housework
    oyster::request_cleanup();

    # return undef so the result isnt Dumper()ed
    return;
}

# login as a user
sub login {

    # get user/pass
    print "Enter your username:\n";
    my $user = <STDIN>;
    chomp($user);
    print "Enter your password:\n";
    my $pass = <STDIN>;
    chomp($pass);

    # validate user/pass and fetch the user's current session if one exists (so you dont log them out in their browser)
    my $query = $DB->query("SELECT id, name, session, ip FROM users WHERE name = ? and password = ? LIMIT 1", $user, hash::secure($pass));
    unless ($query->rows()) {
        print "Invalid username/password combination.";
        return;
    }
    my ($id, $name, $session, $ip) = @{$query->fetchrow_arrayref()};

    # if the user needs a session, create one
    unless ($session) {
        $session = random_string(32);
        $DB->do("UPDATE users SET session = '$session' WHERE id = $id");
    }

    $ENV{'REMOTE_ADDR'} = $ip;
    $ENV{'HTTP_COOKIE'} = "session=$session";

    print "You are now logged in as $name.";
    return;
}

# display the console help
sub help {
    print "Usage:\n";
    print "  Simply enter normal perl code and the result will be dumped.\n";
    print "Example:\n";
    print "  \%CONFIG\n";
    print "Example:\n";
    print "  request 'news/some_category'\n";
    print "Special Commands:\n";
    print "  login               Log in instead of being a Guest\n";
    print "  request(string url) Emulate a request to a given url\n";
    print "  restart             Restarts the console\n";
    print "  search(string)      Searches the code base for a given string,\n";
    print "                      this is interpretted as a regular expression.\n";
    print "Note:\n";
    print "  Multi-line commands can be created by appending \\ to the end of any line.\n";
    print "\n";
    print "To exit this console, type 'exit' and hit enter.\n";

    # return undef so the result isnt Dumper()ed
    return;
}

# search
sub search {
    my $string = shift;
    print `perl script/search.pl $string`;
    return;
}

# module_urls
sub module_urls {
    my $module = shift;
    my $query = $oyster::DB->query("SELECT * FROM $oyster::CONFIG{db_prefix}urls WHERE module = ? ORDER BY LENGTH(url) ASC", $module);
    while (my $url = $query->fetchrow_hashref()) {
        print qq~url::register('url' => '$url->{url}', 'module' => '$url->{module}', 'function' => '$url->{function}', 'title' => '$url->{title}');\n~;
    }
}

1;

# Copyright BitPiston 2008