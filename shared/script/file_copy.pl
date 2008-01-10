=xml
<document title="File Copy Utility">
    <synopsis>
        Moves/renames a file just like the system command, but in an OS-neutral way.
    </synopsis>
    <section title="Command Line Arguments">
        This utility requires two arguments, the file to copy and the destination filename.
    </section>
=cut
package oyster::script::file_copy;

# use Perl's File::Copy module to do this platform independently.
use File::Copy;

# parse command line arguments
my ($from, $dest) = @ARGV;

# if the source is a directory
if (-d $from) {

    # add trailing slashes if necessary
    $from .= '/' unless substr($from, -1, 1) eq '/';
    $dest .= '/' unless substr($dest, -1, 1) eq '/';

    # copy the directory
    recursive_copy($from, $dest);

    # indicate success and exit
    success();
}

# otherwise, the source is a file
else {

    # remove an existing file if present
    if (-f $dest) { unlink($dest) or error() }

    # copy the file
    copy($from, $dest) or error();
    #copy($from, $dest) or die $!;

    # indicate success and exit
    success();
}

#
# Functions
#

# recursively copy a directory
sub recursive_copy {
    my ($from, $dest) = @_; # expects $from and $dest to end in /

    # if the destination directory does not exist, create it    
    unless (-d $dest) { mkdir($dest) or error() }

    # iterate through the source directory
    opendir(my $dir, $from) or error();
    while (my $file = readdir($dir)) {
        next if ($file eq '.' or $file eq '..'); # skip . and ..

        # if the file is a directory
        if (-d "$from$file") {
            unless (-d "$dest$file") {
                mkdir("$dest$file") or error();
            }
            recursive_copy("$from$file/", "$dest$file/");
        }

        # otherwise, copy the file
        else {
        
            # remove an existing file if present
            if (-f "$dest$file") { unlink("$dest$file") or error() }

            # copy the file
            copy("$from$file", "$dest$file") or error();
            #copy("$from$file", "$dest$file") or die $!;
        }
    }
}

# used to indicate success
sub success {
    print "1\n";
    exit;
}

# used to indicate failure
sub error {
    print "0\n";
    exit;
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008