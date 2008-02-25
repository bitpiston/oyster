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
$source_path = '../documentation/source' unless length $source_path;
die "Source directory does not exist!"   unless -d $source_path;
$source_path .= '/' unless $source_path =~ m!/$!;

# figure out the destination directory
my $dest_path = shift;
$dest_path = '../documentation'             unless length $dest_path;
die "Destination directory does not exist!" unless -d $dest_path;
$dest_path.= '/' unless $dest_path=~ m!/$!;

use lib './lib/';

use file;
use exceptions;
use log;

use XML::LibXSLT;
use XML::LibXML;

my $parser  = XML::LibXML->new();
my $xslt    = XML::LibXSLT->new();

my $style = $xslt->parse_stylesheet($parser->parse_file('../documentation/document.xsl'));

# generate doc index xml

compile_dir($source_path);

# generate doc index html
my $xml = eval { $parser->parse_string(file::read('../documentation/source/index.xml')) };
CORE::die("Error parsing XML on 'index.xml': $@") if $@;
my $output = eval { $style->transform($xml) };
CORE::die("Error applying XSLT on 'index.xml': $@") if $@;
my $html = $style->output_string($output);
file::write($dest_path . 'index.xhtml', $html, 1);


sub compile_dir {
    my $path = shift;
    print "Compiling '$path'\n";
    for my $file (<${path}*>) {
        if (-d $file) {
            compile_dir($file . '/');
        } elsif ($file =~ /^$source_path(.+)\.xml$/) {
            my $name = $1;
            print "  $name\n";
            my $xml = eval { $parser->parse_string(file::read($file)) };
            CORE::die("Error parsing XML on '$name': $@") if $@;
            my $output = eval { $style->transform($xml) };
            CORE::die("Error applying XSLT on '$name': $@") if $@;
            my $html = $style->output_string($output);
            my $dest_file = $dest_path . $name . '.xhtml';
            #my ($dest_dir) = ($dest_file =~ /^(.+?)\.html$/o);
            #print "Dest Dir: $dest_dir\n";
            file::write($dest_file, $html, 1);
        }
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008