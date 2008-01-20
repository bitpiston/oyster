=xml
<document title="Oyster Web Server">
    <synopsis>
        A simple, quick and dirty, web server that can (and should only!) be used to deploy quick development environments.
    </synopsis>
    <section title="Command Line Arguments">
        <dl>
            <dt>-site (optional)</dt>
            <dd>Specifies a particular site ID to use</dd>
            <dt>-env (optional)</dt>
            <dd>Specifies a particular configuration environment to use</dd>
            <dt>-host (optional)</dt>
            <dd>Specifies an ip address or host to bind to, defaults to to 127.0.0.1</dd>
            <dt>-port (optional)</dt>
            <dd>Specifies a port to bind to, defaults to 80</dd>
        </dl>
        <p>
        	Host and port can alternatively be passed as a single string, without a name.  For example:
        	<code type="conf">
        		perl script/server.pl 192.168.1.100:82
        	</code>
        	<code type="conf">
        		perl script/server.pl 192.168.1.100
        	</code>
        	<code type="conf">
        		perl script/server.pl 82
        	</code>
        </p>
    </section>
=cut
package oyster::script::server;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

# load the oyster base class
use oyster 'launcher';

# load oyster
eval { oyster::load($config, load_modules => 0, load_libs => 1) };
die "Startup Failed: An error occured while loading Oyster: $@" if $@;

# load web server class
eval { require oyster::webserver };
die "Startup Failed: Could not locate oyster web server library. $@" if $@;

my $server_last_conf = './tmp/server_last_conf.txt';
unless ($oyster::config::args{''} or $oyster::config::args{'host'} or $oyster::config::args{'port'}) {
    $oyster::config::args{''} = file::read($server_last_conf) if -e $server_last_conf;
}

# parse some command line arguments
if ($oyster::config::args{''}) {
    my $arg = $oyster::config::args{''};
    if ($arg =~ /:/) {             # arg is both a host and a port
        ($oyster::config::args{'host'}, $oyster::config::args{'port'}) = ($arg =~ /^(.+):(.+?)$/);
    } elsif ($arg =~ /^[0-9]+$/) { # arg is just a port
        $oyster::config::args{'port'} = $arg;
    } else {                       # arg is just a host
        $oyster::config::args{'host'} = $arg;
    }
}

# save this configuration
if ($oyster::config::args{'host'} or $oyster::config::args{'port'}) {
    file::write($server_last_conf, $oyster::config::args{'host'} . ':' . $oyster::config::args{'port'});
}

# start the web server
oyster::webserver::start('port' => $oyster::config::args{'port'}, 'host' => $oyster::config::args{'host'});

=xml
</document>
=cut

1;

# Copyright BitPiston 2008