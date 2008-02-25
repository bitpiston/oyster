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
use log;

my %directory_titles = (
    'lib/'         => 'Library API',
    'lib/oyster/'  => 'Oyster',
    'lib/console/' => 'Console',
    'lib/xml/'     => 'XML',
    'modules/'     => 'Modules',
    'script/'      => 'Scripts and Utilities',    
);

my @index_xml;
push @index_xml, '<index>';
iter_dir($source_path);
push @index_xml, '</index>';
print "\nWriting ${source_path}index.xml...\n";
file::write($source_path . 'index.xml', join("\n", @index_xml));

sub iter_dir {
    my $path  = shift;
    my $index = shift;
    my $short_path   = substr($path, length $source_path);
    my $indent_depth = $short_path =~ tr~/~/~;
    my $indent       = "\t" x $indent_depth;
    my $i;
    my $index_prefix = length $index ? $index . '.' : '' ;

    my $heading_added;
    my $add_index_heading = sub {
        return if length $short_path == 0 or $heading_added;
        push @index_xml, qq~$indent<directory path="$short_path" title="$directory_titles{$short_path}" index="$index">~;
        #push @index_xml, qq~$indent<directory path="$short_path" title="$directory_titles{$short_path}">~ if length $short_path;
        $heading_added = 1;
    };

    # iterate through files in this directory
    for my $file (<${path}*>) {

        # skip index.xml created by this script
        next if $file eq $source_path . 'index.xml';

        # if the file is a directory
        if (-d $file) {
            $add_index_heading->();
            iter_dir($file . '/', $index_prefix . ++$i);
        }

        # if the file is xml
        elsif ($file =~ /^$path(.+)\.xml$/) {
            $add_index_heading->();
            my $name = $1;
            print "$short_path$name\n";

            # add some stuff to the xml
            my $xml = file::read($file);
            CORE::die "XML does not begin with <document in '$file'." unless $xml =~ /^\s*<document[^<]*>/o;
            my $attr;
            # path
            $attr = qq~path="$short_path"~;
            $xml =~ s/^([\s\S]+?)>/$1 $attr>/o unless ($xml =~ s/^(\s*<document[^>]+)path="[^"]*"/$1$attr/o);
            # index
            $attr = 'index="' . $index_prefix . ++$i . '"';
            $xml =~ s/^([\s\S]+?)>/$1 $attr>/o unless ($xml =~ s/^(\s*<document[^>]+)index="[^"]*"/$1$attr/o);
            # depth
            my $depth = $short_path;
            $depth =~ s![^/]+!..!g;
            $attr = qq~depth="$depth"~;
            $xml =~ s/^([\s\S]+?)>/$1 $attr>/o unless ($xml =~ s/^(\s*<document[^>]+)depth="[^"]*"/$1$attr/o);
            # file
            $attr = qq~file="$name"~;
            $xml =~ s/^([\s\S]+?)>/$1 $attr>/o unless ($xml =~ s/^(\s*<document[^>]+)file="[^"]*"/$1$attr/o);
            # save it
            file::write($file, $xml);

            $xml =~ m!^\s*(<document[\s\S]*?>)!;
            my $doc_xml = $1;
            $doc_xml =~ s!([^/])>!$1 />!o;
            push @index_xml, "\t$indent$doc_xml";
        }
    }

    push @index_xml, qq~$indent</directory>~ if $heading_added;

    return $i;
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008