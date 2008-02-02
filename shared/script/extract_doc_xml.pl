=xml
<document title="Extract Document XML">
    <synopsis>
        Extracts XML documentation from perl files.
    </synopsis>
    <section title="Command Line Arguments">
        This utility requires a single argument, a directory to extract the documentation to.
    </section>
=cut
package oyster::script::extract_doc_xml;

use lib './lib';
use file;

# directories to spider
my @dirs = ('./lib/', './modules/', './script/');

# figure out the destination directory
my $dest = shift;
die "A destination directory must be specified." unless length $dest;
die "Destination directory does not exist!"      unless -d $dest;
$dest .= '/' unless $dest =~ m!/$!;

# settings
my %skip_files = (
    '.svn' => undef,
);

my %exts = (
    'pl' => undef,
    'pm' => undef,
);

# extract the xml

# iterate through directories until none are left
while (@dirs) {
    my $dir = shift @dirs;

    # retreive files in the current directory
    my @files = <$dir*>;

    # iterate over those files
    for my $file (@files) {

        # extract just the filename
        my ($filename) = ($file =~ m!^.+/(.+?)$!o);

        # skip files
        next if exists $skip_files{$filename};

        # if the file is a directory
        if (-d $file) {
            push @dirs, $file . '/';
        }

        # if the file is not a directory
        else {
            my ($filename_noext, $file_ext) = ($filename =~ m!^(.+)\.(.+?)$!o);

            # skip unless this file has an extension we should check
            next unless exists $exts{$file_ext};

            # extract the xml from the file
            print "Extracing XML from '$file'...\n";
            my $xml = extract_xml($file);

            # if any xml was found, save it
            if (length $xml) {
                my $dest_file = $filename_noext . '.xml';
                my ($dest_dir) = ($file =~ m!^(.+/).+?$!);
                $dest_dir = $dest . $dest_dir;
                print "\tCreating $dest_dir$dest_file...\n";
                file::mkdir($dest_dir) unless -d $dest_dir;
                open(my $fh, '>', $dest_dir . $dest_file) or die "Error creating '$dest_dir$dest_file'.";
                print $fh $xml;
            }
        }
    }
}

# work function
sub extract_xml {
    my $filename = shift;
    open(my $fh, '<', $filename) or die "Could not open file for reading: '$filename'.";
    my $xml = '';
    my $in_pod;
    while (my $line = <$fh>) {
        last if ($line =~ /^__END__/o or $line =~ /^__DATA__/o);
        if ($line =~ /^=xml/o and !$in_pod) {
            $in_pod = 1;
        } elsif ($line =~ /^=cut/o and $in_pod) {
            $in_pod = 0;
        } elsif ($in_pod) {
            $xml .= $line;
        }
    }
    return $xml;
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008