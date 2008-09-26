=xml
<document title="Temporary Directory Cleaner">
    <synopsis>
        Deletes files in the tmp directory.
    </synopsis>
=cut
package oyster::script::tmpclean;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

# load the oyster base class
use oyster 'script';

# modified time safety limit
my $age = 3600; # 1 hour

my $now = time();

print "Cleaning up tmp directory...\n";
my @files = <tmp/*>;
for my $file (@files) {
    if (($now - file::mtime($file)) > $age) {
        print "Deleting '$file'...\n";
        unlink($file) or die "Error deleting '$file'.";
    }
}
print "Finished.\n";

=xml
</document>
=cut

1;

# Copyright BitPiston 2008