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

# figure out the destination directory
my $dest = shift;
$dest = '../documentation/source'           unless length $dest;
die "Destination directory does not exist!" unless -d $dest;
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

# directories to spider
#my $i = 0;
#spider_directory($_, ++$i) for ('./lib/', './modules/', './script/');
spider_directory($_) for ('./lib/', './modules/', './script/');

# iterate through directories until none are left
sub spider_directory {
    my $dir   = shift;
    #my $index = shift;

    # retreive files in the current directory
    my @files = <$dir*>;

    # iterate over those files
    #my $i = 0;
    for my $file (@files) {

        # extract just the filename
        my ($filename) = ($file =~ m!^.+/(.+?)$!o);

        # skip files
        next if exists $skip_files{$filename};

        # if the file is a directory
        if (-d $file) {
            #spider_directory($file . '/', $index . '.' . ++$i);
            spider_directory($file . '/');
            #push @dirs, $file . '/';
        }

        # if the file is not a directory
        else {
            my ($filename_noext, $file_ext) = ($filename =~ m!^(.+)\.(.+?)$!o);

            # skip unless this file has an extension we should check
            next unless exists $exts{$file_ext};

            # extract the xml from the file
            print "Extracting XML from '$file'...\n";
            my $xml = extract_xml($file);

            # if any xml was found
            if (length $xml) {
                #$i++;

                # preprocess it
                die "XML does not begin with <document in '$file'." unless $xml =~ /^\s*<document[^<]*>/o;

                # extraction time
                my $attr = 'extract_time="' . datetime::from_unixtime(time()) . '"';
                $xml =~ s/^([\s\S]+?)>/$1 $attr>/ unless ($xml =~ s/^(\s*<document[^<]+>)extract_time=".+?"/$1$attr/o);
                # path
                #$file =~ m!^\./(.+)\.$file_ext$!;
                #my $attr = 'path="' . $1 . '"';
                #$xml =~ s/^([\s\S]+?)>/$1 $attr>/ unless ($xml =~ s/^(\s*<document[^<]+>)path=".+?"/$1$attr/o);
                # source
                my $attr = 'source="' . $file . '"';
                $xml =~ s/^([\s\S]+?)>/$1 $attr>/ unless ($xml =~ s/^(\s*<document[^<]+>)source=".+?"/$1$attr/o);
                # index
                #my $attr = 'index="' . $index . '.' . $i . '"';
                #$xml =~ s/^([\s\S]+?)>/$1 $attr>/ unless ($xml =~ s/^(\s*<document[^<]+>)index=".+?"/$1$attr/o);

                # save it
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