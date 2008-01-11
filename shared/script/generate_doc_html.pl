=xml
<document title="Generate Documentation (X)HTML">
    <synopsis>
        Converts documentation XML to XHTML.
    </synopsis>
    <section title="Command Line Arguments">
        Expects two arguments, the source directory and destination directory.
    </section>
=cut
package oyster::script::generate_doc_html;

# figure out the source directory
my $source_path = shift;
die "A source directory must be specified." unless length $source_path;
die "Source directory does not exist!"      unless -d $source_path;
$source_path .= '/' unless $source_path =~ m!/$!;

# figure out the destination directory
my $dest_path = shift;
die "A destination directory must be specified." unless length $dest_path;
die "Destination directory does not exist!"      unless -d $dest_path;
$dest_path.= '/' unless $dest_path=~ m!/$!;

use lib './lib/';

use file;
use exceptions;
use misc;
use log;

use XML::LibXSLT;
use XML::LibXML;

my $xml_parser  = XML::LibXML->new();
my $xslt_parser = XML::LibXSLT->new();

my $style = $xslt_parser->parse_stylesheet('./script/doc_style.xsl');

compile_dir($source_path);

sub compile_dir {
    my $path = shift;
    print ">> 'Compiling' $path...\n";
    for my $file (<${path}*>) {
        if (-d $file) {
            compile_dir($file . '/');
        } elsif ($file =~ /^$source_path(.+)\.xml$/) {
            my $name = $1;
            print "$name\n";
            my $xml = eval { $xml_parser->parse_string(file::read($file)) };
            CORE::die("Error parsing xml on '$name': $@") if $@;
        }
        #print "$file\n";
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008