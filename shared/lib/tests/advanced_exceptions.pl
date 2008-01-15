
# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

use oyster 'launcher';

# use oyster libraries
use exceptions;

try {
    throw 'meow' => 'wtf'; # test aborting a single block
}
catch 'meow', with {
    my $foo = shift;
    abort()
};

# put a try block that does nothing first, to ensure that the stack is properly cleared after it is executed

try {
    try {
        throw 'foo' => '1'; # test aborting an outer block from an inner one (print "2" is never reached)
    };
    print '2';
}
catch 'foo', with {
    print shift;
    abort();
};

try {
    try {
        throw 'bar' => 'a'; # test aborting an inner block from an outer block's catch
    };
    print 'c';
}
catch 'bar', with {
    print shift;
    abort(1);
}
