=xml
<document title="Generate Documentation Index XML">
    <synopsis>
        Iterates through the documentation source directory and creates the XML necessary to create the doc index.
    </synopsis>
    <section title="Command Line Arguments">
        Expects one argument, the documentation source directory.
    </section>
=cut
package oyster::script::generate_doc_index_xml;

# figure out the source directory
my $source_path = shift;
$source_path = '../documentation/source' unless length $source_path;
die "Source directory does not exist!"   unless -d $source_path;
$source_path .= '/' unless $source_path =~ m!/$!;

use lib './lib/';

use file;
use exceptions;

my $index_xml;

iter_dir($source_path);

sub iter_dir {
    my $path  = shift;
    my $index = shift;
    my $short_path   = substr($path, length $source_path);
    my $index_prefix = length $index ? $index . '.' : '' ;

    # iterate through files in this directory
    my $i;
    for my $file (<${path}*>) {

        # if the file is a directory
        if (-d $file) {
            iter_dir($file . '/', $index_prefix . ++$i);
        }

        # if the file is xml
        elsif ($file =~ /^$path(.+)\.xml$/) {
            my $name = $1;
            print "$short_path$name\n";

            # add some stuff to the xml
            my $xml = file::read($file);
            die "XML does not begin with <document in '$file'." unless $xml =~ /^\s*<document[^<]*>/o;
            my $attr;
            # path
            $attr = 'path="' . $short_path . '"';
            $xml =~ s/^([\s\S]+?)>/$1 $attr>/ unless ($xml =~ s/^(\s*<document[^<]+>)path=".+?"/$1$attr/o);
            # index
            $attr = 'index="' . $index_prefix . ++$i . '"';
            $xml =~ s/^([\s\S]+?)>/$1 $attr>/ unless ($xml =~ s/^(\s*<document[^<]+>)index=".+?"/$1$attr/o);
            # depth
            my $depth = $short_path;
            $depth =~ s![^/]+!..!g;
            $attr = 'depth="' . $depth . '"';
            $xml =~ s/^([\s\S]+?)>/$1 $attr>/ unless ($xml =~ s/^(\s*<document[^<]+>)depth=".+?"/$1$attr/o);
            # save it
            file::write($file, $xml);

        }
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008