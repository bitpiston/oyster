=xml
<document title="Set File Permissions">
    <synopsis>
        This can be used to set the proper file permissions on *nix systems.
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
package oyster::script::perm;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

die "There is no need to run this script on Windows." if $config->{'os'} eq 'windows';

my $shared_path    = $config->{'shared_path'};
my $site_path      = $config->{'site_path'};
my $site_file_path = $config->{'site_file_path'};

print "tmp/ to 755\n";
chmod 0755, "${shared_path}tmp/";

print "oyster.fcgi to 755\n";
chmod 0755, "${shared_path}oyster.fcgi";

print "oyster.pl to 755\n";
chmod 0755, "${shared_path}oyster.pl";

print "logs/ to 755\n";
chmod 0755, "${site_path}logs/";

print "styles/ (and all sub-directories) to 755\n";
chmod_dir("${site_path}styles/", 755);

print "files/ (and all sub-directories) to 755\n";
chmod_dir($site_file_path, 755);

my %chmod_ext = (
    'xsl' => undef,
    'jpg' => undef,
    'png' => undef,
    'gif' => undef,
    'js'  => undef,
    'css' => undef,
);

sub chmod_dir {
    my ($dir, $mode) = @_;

    chmod 0755, $dir;

    opendir(my $dh, $dir) or die "Could not open directory '$dir': $!";
    ITER_DIR: while (my $file = readdir($dh)) {
        next ITER_DIR if ($file eq '.' or $file eq '..');

        if (-d "$dir$file") {
            chmod_dir("$dir$file/", $mode);
            next ITER_DIR;
        } elsif ($file =~ /^.+\.(?:.+?)$/ and exists $chmod_ext{$1}) {
            chmod 0755, "$dir$file";
        }

        chmod 0755, "$dir$file";
    }
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008