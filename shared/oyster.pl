##############################################################################
# Oyster
# ----------------------------------------------------------------------------
# This is the standard CGI launcher, it is not meant for speed, but primarily
# for easy development and testing.
#
# This executable must be run from the shared directory.
#
# TODO:
# * skip ipc stuff, not needed in standard cgi mode
# ----------------------------------------------------------------------------
package launcher;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
    $config->{'mode'} = 'cgi';
}

# load the oyster base class
use oyster 'launcher';

# load oyster
eval { oyster::load($config) };
die "Startup Failed: An error occured while loading Oyster: $@" if $@;

# handle a request
oyster::request_pre();
oyster::request_handler();
oyster::request_cleanup();

# ----------------------------------------------------------------------------
# Copyright
##############################################################################
1;