package oyster::config::heavy;

# This does config.pl's dirty work

sub init {
    my $default_site_id     = shift;
    my $default_environment = shift;

    # Specify the current environment, development or production, or add your own
    $ENV{'oyster_environment'} = $default_environment unless exists $ENV{'oyster_environment'};

    # Specify the site ID
    $ENV{'oyster_site_id'}     = $default_site_id     unless exists $ENV{'oyster_site_id'};

    # Get the shared (current) directory
    use Cwd;
    $oyster::config::shared_path = getcwd();
    $oyster::config::shared_path .= '/' unless $oyster::config::shared_path =~ m!/$!;

    # TODO: consider destroying the Cwd package

    # Get sites path
    $oyster::config::sites_path = $oyster::config::shared_path;
    $oyster::config::sites_path =~ s!/shared/$!/!;

    # add oyster's library paths to perl's include list (this is why require config must be in a BEGIN block)
    #@oyster::config::original_inc = @INC;
    #unshift @INC, $oyster::config::shared_path . 'lib/';
    #unshift @INC, $oyster::config::shared_path . 'perllib/';
    eval "use lib '${oyster::config::shared_path}modules/'";
    eval "use lib '${oyster::config::shared_path}perllib/'";
    eval "use lib '${oyster::config::shared_path}lib/'";

    # parse command line arguments
    if (@ARGV) {
        require console::util;
        %oyster::config::args = console::util::process_args();
        $ENV{'oyster_site_id'}     = $oyster::config::args{'site'}        if exists $oyster::config::args{'site'};
        $ENV{'oyster_site_id'}     = $oyster::config::args{'site_id'}     if exists $oyster::config::args{'site_id'};
        $ENV{'oyster_environment'} = $oyster::config::args{'environment'} if exists $oyster::config::args{'environment'};
        $ENV{'oyster_environment'} = $oyster::config::args{'env'}         if exists $oyster::config::args{'env'};
    }
}

sub end {

    # if a matching environment was found
    if (exists $oyster::config::config{$ENV{'oyster_site_id'}}{$ENV{'oyster_environment'}}) {
        my $combined_config = $oyster::config::config{$ENV{'oyster_site_id'}}{$ENV{'oyster_environment'}};

        # add shared configuration for the same environment
        for my $name (keys %{ $oyster::config::config{'shared'}{$ENV{'oyster_environment'}} }) {
            $combined_config->{$name} = $oyster::config::config{'shared'}{$ENV{'oyster_environment'}}{$name} unless exists $combined_config->{$name};
        }

        # add misc variables to config
        $combined_config->{'environment'} = $ENV{'oyster_environment'};
        $combined_config->{'site_id'}     = $ENV{'oyster_site_id'};
        $combined_config->{'shared_path'} = $oyster::config::shared_path;
        $combined_config->{'site_path'}   = $oyster::config::sites_path . $combined_config->{'site_id'} . '/';
        # possible values: MSWin32, MSWin64, linux, hpux, solaris, darwin, freebsd, openbsd, otherwise should either die or issue a warning
        if ($^O eq 'MSWin32' or $^O eq 'MSWin64') { # TODO: this is a pretty basic test... add more possiblities
            $combined_config->{'os'}      = 'windows';
        } else {
            $combined_config->{'os'}      = 'nix';
        }

        # delete some variables, they are no longer needed (and wont be GC'd automatically)
        undef $oyster::config::shared_path;
        undef $oyster::config::sites_path;

        # delete this package
        undef *init;
        undef *end;

        return $combined_config;
    }

    # invalid site id or environment
    else {
        die "Invalid site id '$ENV{oyster_site_id}' or environment '$ENV{oyster_environment}'.";
    }
}

1;
