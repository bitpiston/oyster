=xml
<document title="Oyster Console">
    <synopsis>
        Allows you to execute perl code within a Oyster environment.
    </synopsis>
    <section title="Command Line Arguments">
        <dl>
            <dt>-site (optional)</dt>
            <dd>Specifies a particular site ID to use</dd>
            <dt>-env (optional)</dt>
            <dd>Specifies a particular configuration environment to use</dd>
        </dl>
    </section>
    <section title="Special Commands">
        TODO
    </section>
=cut
package oyster::script::console;

# configuration
BEGIN {
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

# load the oyster base class
use oyster 'launcher';

# load oyster
eval { oyster::load($config) };
die "Startup Failed: An error occured while loading Oyster: $@" if $@;

# load console class
eval { require oyster::console };
die "Startup Failed: Could not locate oyster console library. $@" if $@;

# start the console
oyster::console::start();

=xml
</document>
=cut

1;

# Copyright BitPiston 2008