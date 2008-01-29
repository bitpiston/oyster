#!/usr/bin/perl
##############################################################################
# Oyster
# ----------------------------------------------------------------------------
# This is the FastCGI launcher.
#
# TODO:
# Investigate if it would be better for memory usage if fork was performed in
# here after including (but not loading) oyster, instead of having fastcgi
# create the daemons.  It would probably lead to more shared memory.
# ----------------------------------------------------------------------------
package launcher;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
    $config->{'mode'} = 'fastcgi';
}

# load the oyster base class
use oyster 'launcher';

# initialize oyster
eval { oyster::load($config) };
die "Startup Failed: An error occured while loading Oyster: $@" if $@;

# import the fastcgi library
eval { require FCGI };
die "Startup Failed: Could not import the FastCGI library. Are you sure you should be using this launcher? $@" if $@;

# accept connections
eval {
    my $request = FCGI::Request();
    while ($request->Accept() >= 0) {

        # do initialization work
        oyster::request_pre();

        # handle the user's request
        oyster::request_handler();

        # end the request
        $request->Finish();

        # do housework
        oyster::request_cleanup();
    }
};
die("An error occured while handling a request: $@") if $@;

# ----------------------------------------------------------------------------
# Copyright
##############################################################################
1;
