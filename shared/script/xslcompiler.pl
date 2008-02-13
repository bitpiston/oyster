=xml
<document title="XSL Compiler">
    <synopsis>
        Takes source stylesheets and compiles them into usable client and server side xsl.
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
package oyster::script::xslcompiler;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

# load the oyster base class
use oyster 'launcher';

# load oyster
eval { oyster::load($config) };
die("Startup Failed: An error occured while loading Oyster: $@") if $@;

our $shared_path = $oyster::CONFIG{'shared_path'};
our $module_path = $oyster::CONFIG{'shared_path'} . 'modules/';
our $styles_path = $oyster::CONFIG{'site_path'} . 'styles/';

# clean up any existing compiled styles
print `perl script/xslclean.pl`;

my $module_stylesheets = style::_get_module_stylesheets();

# iterate over each enabled style
for my $style (keys %style::styles) {
    my $style_path = $styles_path . $style . '/';
    print "$style...\n";

    # client side layout.xsl
    print "\tbase.xsl... ";
    file::write("${style_path}base.xsl", style::_compile_style($style, "styles/source.xsl"));
    print "Done.\n";

    # server side layout.xsl
    print "\tserver_base.xsl... ";
    file::write("${style_path}server_base.xsl", style::_compile_style($style, "styles/source.xsl", 1));
    print "Done.\n";

    # module styles
    for my $module_id (keys %{$module_stylesheets}) {
        print "\t$module_id..\n";
        file::mkdir("${style_path}modules/$module_id/");
        for my $stylesheet (@{$module_stylesheets->{$module_id}}) {
            print "\t\t$stylesheet... ";

            # compile style
            my $template;
            $template .= "<?xml version='1.0' encoding=\"UTF-8\" ?>\n";
            $template .= "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"\n xmlns=\"http://www.w3.org/1999/xhtml\">\n\n";
            $template .= style::_compile_style($style, "modules/$module_id/$stylesheet") . "\n";
            $template .= "</xsl:stylesheet>\n";
            file::write("${style_path}modules/$module_id/$stylesheet", $template);

            # create dynamic style
            my $style_url = "$oyster::CONFIG{styles_url}$style/";
            my $dyn_name  = $stylesheet;
            my $dyn_style =
                "<?xml version='1.0' encoding=\"UTF-8\" ?>\n"
              . "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"\n xmlns=\"http://www.w3.org/1999/xhtml\">\n\n"
              . "<xsl:include href=\"${style_url}base.xsl\" />\n\n"
              . "<xsl:include href=\"${style_url}modules/$stylesheet\" />\n"
              . "</xsl:stylesheet>\n";
            mkdir("${style_path}dynamic/") unless -d "${style_path}dynamic/";
            file::write("${style_path}dynamic/${module_id}_$dyn_name", $dyn_style);

            print "Done.\n";
        }
        print "\tDone.\n";
    }

    print "Done.\n";
}

=xml
</document>
=cut

1;

# Copyright BitPiston 2008