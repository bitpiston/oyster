=xml
<document title="Clean Documentation Directory">
    <synopsis>
        
    </synopsis>
    <section title="Command Line Arguments">
        Expects one argument, the documentation directory.
    </section>
=cut
package oyster::script::clean_docs;

# figure out the source directory
my $doc_path = shift;
$doc_path    = '../documentation/'              unless length $doc_path;
die "Documentation directory does not exist!"   unless -d $doc_path;
$doc_path .= '/' unless $doc_path =~ m!/$!;

%skip_files = (
    '.'    => undef,
    '..'   => undef,
    '.svn' => undef,
);

sub clean_dir {
    my $path = shift;
    my @subdirs;
    print "$path\n";
    opendir(my $dh, $path) or die "Could not open '$path': $!";
    while (defined(my $file = readdir($dh))) {
        next if exists $skip_files{$file};
        my $fullfile = $path . $file;

        if (-d $fullfile) {
            push @subdirs, $fullfile . '/';
        }

        elsif ($file =~ /\.x?html$/o) {
            print "\tDeleting '$fullfile'...\n";
            unlink $fullfile or die "Could not delete file '$fullfile': $!";
        }

        elsif ($file eq 'index.xml') {
            print "\tDeleting '$fullfile'...\n";
            unlink $fullfile or die "Could not delete file '$fullfile': $!";
        }

        elsif ($file =~ /\.xml$/o) {
            open(my $fh, '<', $fullfile) or die "Could not delete file '$fullfile': $!";
            my $firstline = <$fh>;
            if ($firstline =~ /^\s*<document[^>]*extract_time="[^"]*"/o) {
                print "\tDeleting '$fullfile'...\n";
                unlink $fullfile or die "Could not delete file '$fullfile': $!";
            }
        }
    }

    clean_dir($_) for @subdirs;
}

clean_dir($doc_path);

=xml
</document>
=cut

1;

# Copyright BitPiston 2008