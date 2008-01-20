Setting Up an Oyster Development Environment

* Ensure you have the software required to run Oyster.
  - Perl

    Type `perl -v` to see your Perl version (or to check if you have Perl
    installed).

    Perl 5.8 or higher is required.

    On Windows, visit www.activestate.com and download their latest version
    of perl.

    On Linux or BSD, either compile perl from source or install using your
    distribution's package management tools.

  - ImageMagick
    ImageMagick is a set of programs that allow advanced image manipulation to
    be done on the command line.  Only the Imagemagick binaries are required
    by Oyster, no ImageMagick perl libraries are required.

    NOTE: ImageMagick is NOT mandatory for development or testing, as long as 
    you will not need any image manipulation performed.

    To obtain ImageMagick, visit imagemagick.com and find the proper release
    for your platform.

    Once installed, you need to know where ImageMagick's binaries are at.

    On Windows, this directory will be the one you specified during
    installation, typically 'C:/program files/imagemagick/'.

    On Linux, the binaries are usually placed in '/usr/bin/'.

  - Perl Modules

    Oyster requires the following perl modules: DBI, DBD::mysql, Digest::JHash,
    Time::HiRes, and Digest::SHA.  XML::LibXML and XML::LibXSLT are also
    also recommended (they are used for server-side XSLT), but the ssxslt module
    will automatically disable itself if they are not found.

    To check if you have these modules installed, type:
    `perl -Mmodulenamehere -e "print qq{success\n}"`
    If an error is printed instead of "success", you do not have the module.

    To install these modules using CPAN type:
    `perl -MCPAN -e "install modulenamehere"`

    To install these modules using Activestate's PPM type:
    `ppm install modulenamehere`

    To install these modules using FreeBSD's ports type:
    `pkg_add -r p5-DBI`
    `pkg_add -r p5-DBD-mysql`
    `pkg_add -r p5-Digest-JHash`
    `pkg_add -r p5-Digest-SHA`

    Notes: Digest::JHash is optional; if it is not present, Digest::SHA will
    be used.  Digest::JHash is highly recommended for production environments.
    Digest::SHA is optional; if it is not present, Oyster has a backup bundled
    with it -- however, the pure-perl version of Digest::SHA that Oyster uses
    as a fallback is quite slow, it is not recommended for use in production
    environments.  Time::HiRes usually comes with Perl.
* Get a fresh SVN checkout:
  `svn co svn://bitpiston.com/oyster oyster`
* Navigate to the shared directory:
  `cd oyster/trunk/shared`
* Copy the config file template:
  `cp config.pl.tmpl config.pl`
* Edit config.pl with the text editor of your choice.
* Install Oyster:
  `perl script/update.pl`
* Start your test server:
  `perl script/server.pl`

  Note: For additional server options, type `perl script/server.pl -h`
* Visit 127.0.0.1:80 (or whatever you configured the server to bind to)
* Your Oyster development environment is ready!

