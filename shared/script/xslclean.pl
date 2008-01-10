=xml
<document title="XSL Cleaner">
    <synopsis>
        Deletes compiled stylesheet data.
    </synopsis>
    <section title="Command Line Arguments">
        <dl>
            <dt>-site (optional)</dt>
            <dd>Specifies a particular site ID to use</dd>
            <dt>-env (optional)</dt>
            <dd>Specifies a particular configuration environment to use</dd>
        </dl>
    </section>
=cut
package oyster::script::xslclean;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

# load the oyster base class
use oyster 'launcher';

my $styles_path = "$config->{site_path}styles/";

print "Cleaning up styles directory...\n";
print "\tDeleting module styles...\n";
my @dirs = <${styles_path}*/modules/>;
for my $dir (@dirs) {
    my $disp_path = $dir;
    $disp_path =~ s/^\Q$styles_path\E//;
    print "\t\t$disp_path\n";
    file::rmdir($dir);
}
print "\tDone.\n";
print "\tDeleting dynamic styles...\n";
my @dirs = <${styles_path}*/dynamic/>;
for my $dir (@dirs) {
    my $disp_path = $dir;
    $disp_path =~ s/^\Q$styles_path\E//;
    print "\t\t$disp_path\n";
    file::rmdir($dir);
}
print "\tDone.\n";
print "\tDeleting base styles...\n";
my @files = <${styles_path}*/base.xsl>;
for my $file (@files) {
    my $disp_path = $file;
    $disp_path =~ s/^\Q$styles_path\E//;
    print "\t\t$disp_path\n";
    unlink($file) or die "Error deleting '$file'.";
}
my @files = <${styles_path}*/server_base.xsl>;
for my $file (@files) {
    my $disp_path = $file;
    $disp_path =~ s/^\Q$styles_path\E//;
    print "\t\t$disp_path\n";
    unlink($file) or die "Error deleting '$file'.";
}
print "\tDone.\n";
print "Finished.\n";

=xml
</document>
=cut

1;

# Copyright BitPiston 2008