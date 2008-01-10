
# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

# use oyster libraries
use exceptions;

try {
    throw 'foo' => '1';
}
catch 'foo', with {
    print $_[0];
};

