=xml
<document title="Style &amp; Templates Functions">
    <synopsis>
        Functions related to styles and templates
    </synopsis>
    <todo>
        # TODO: update admin.pm's style management stuff and user.pm's style selection
    </todo>
=cut
package style;

use exceptions;

event::register_hook('load_lib', '_style_load');
sub _style_load {

    # load style data
    our %styles;
    _load();
}

=xml
    <section tile="Public API">

        <function name="include_template">
            <synopsis>
                Defines a specific xsl template to use for the current request.
            </synopsis>
            <prototype>
                style::include_template(string template_name)
            </prototype>
        </function>
=cut

sub include_template {
    my ($module, $template);

    # if two arguments are specified
    if (@_ == 2) {
        ($module, $template) = @_;
    }

    # one argument, assume the module is the one that called this
    else {
        $template = shift;
        my $pkg = caller();
        $pkg =~ /::/o ? ($module) = ($pkg =~ /^(.+?)::/o) : $module = $pkg ;
    }

    # add the template file to the list of templates to include
    push @{$oyster::REQUEST{'templates'}}, "$module/$template.xsl";
}

=xml
        <function name="print_header">
            <synopsis>
                Print the page header.
            </synopsis>
            <note>
                Modules should rarely need to call this function explicitely.  Each page
                request is wrapped in the template automatically.
            </note>
            <prototype>
                style::print_header()
            </prototype>
            <todo>
                Some of $attrs is cachable and not necessary to assemble every request
            </todo>
            <todo>
                Investigate if all $attrs are even used somewhere, and if some are
                rarely used, don't always print them
            </todo>
        </function>
=cut

sub print_header {
    return if $oyster::REQUEST{'printed_header'};

    # get the stylesheet's url and compile it if necessary
    my $stylesheet = (style::compile($oyster::REQUEST{'style'}, @{$oyster::REQUEST{'templates'}}))[0];

    # set the default mime type
    $oyster::REQUEST{'mime_type'} = 'application/xml' unless length $oyster::REQUEST{'mime_type'};

    # print http headers
    http::header("Content-Type: $oyster::REQUEST{mime_type}");
    http::print_headers();

    # print xml heading
    print qq~<?xml version="1.0" encoding="utf-8"?>\n~;
    print qq~<?xml-stylesheet type="text/xsl" href="$stylesheet"?>\n~;

    # assemble and print oyster header xml
    my $attrs = ' title="' .  $oyster::CONFIG{'site_name'} . '"'
              . ' base="' .   $oyster::CONFIG{'url'} . '"'
              . ' styles="' . $oyster::CONFIG{'styles_url'} . '"'
              . ' style="' .  $oyster::REQUEST{'style'} . '"'
              . ' url="' .    $oyster::CONFIG{'url'} . ( length $oyster::REQUEST{'url'} ? $oyster::REQUEST{'url'} . '/' : '' ) . '"';
    $attrs .= ' module="' . $oyster::REQUEST{'module'} . '"' if length $oyster::REQUEST{'module'};
    $attrs .= ' query_string="?' . xml::entities($ENV{'QUERY_STRING'}) . '"' if length $ENV{'QUERY_STRING'};
    if (exists $oyster::REQUEST{'handler'}) {
        $attrs .= ' handler="' . $oyster::REQUEST{'handler'} . '"';
        $attrs .= ' ajax_target="' . $oyster::INPUT{'ajax_target'} . '"' if exists $oyster::INPUT{'ajax_target'};
    }

    print "<swaf$attrs>\n";

    $oyster::REQUEST{'printed_header'} = 1;
}

=xml
        <function name="print_footer">
            <synopsis>
                Print the page footer.
            </synopsis>
            <note>
                Modules should rarely need to call this function explicitely.  Each page
                request is wrapped in the template automatically.
            </note>
            <prototype>
                style::print_footer()
            </prototype>
        </function>
=cut

sub print_footer {
    return if $oyster::REQUEST{'printed_footer'};
    print "\t<benchmark>" . sprintf('%.5f', Time::HiRes::gettimeofday() - $oyster::REQUEST{'start_time'}) . "</benchmark>\n" if $oyster::CONFIG{'debug'};
    print "</swaf>\n";
    $oyster::REQUEST{'printed_footer'} = 1;
}

=xml
        <function name="print_styles">
            <synopsis>
                Prints styles in an xml-friendly manner.
            </synopsis>
            <prototype>
                style::print_styles()
            </prototype>
        </function>
=cut

sub print_styles {
    _load();
    print "\t\t<styles>\n";
    for my $style (values %styles) {
        print "\t\t\t<style id=\"$style->{id}\" name=\"$style->{name}\" status=\"$style->{status}\" />\n";
    }
    print "\t\t</styles>\n";
}

=xml
        <function name="print_enabled_styles">
            <synopsis>
                Print enabled styles in an xml-friendly manner.
            </synopsis>
            <prototype>
                style::print_enabled_styles()
            </prototype>
        </function>
=cut

sub print_enabled_styles {
    _load();
    print "\t\t<styles>\n";
    for my $style (values %styles) {
        next unless $style->{'status'};
        print "\t\t\t<style id=\"$style->{id}\" name=\"$style->{name}\" />\n";
    }
    print "\t\t</styles>\n";
}

=xml
        <function name="is_valid_style">
            <synopsis>
                Returns true if a valid style is found.
            </synopsis>
            <prototype>
                bool = style::is_valid_style(string style_id[, string ignore_style_id])
            </prototype>
        </function>
=cut

sub is_valid_style {
    if (scalar(@_) == 2) {
        my ($new_id, $current_id) = @_;
        my $query = $oyster::DB->query("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}styles WHERE id = ? and id != ? LIMIT 1", $new_id, $current_id);
        return $query->fetchrow_arrayref()->[0];
    } else {
        my $id = shift;
        my $query = $oyster::DB->query("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}styles WHERE id = ? LIMIT 1", $id);
        return $query->fetchrow_arrayref()->[0];
    }
}

=xml
        <function name="is_enabled_style">
            <synopsis>
                Returns true if a style is enabled
            </synopsis>
            <note>
            
            </note>
            <prototype>
                bool = style::is_enabled_style(string style_id)
            </prototype>
            <todo>
            
            </todo>
            <example>
            
            </example>
        </function>
=cut

sub is_enabled_style {
    my $id = shift;
    return unless $styles{$id};
    return $styles{$id}->{'status'};
}

=xml
        <function name="is_reserved_id">
            <synopsis>
                Returns true if a style id is reserved.
            </synopsis>
            <prototype>
                bool = style::is_reserved_id(string style_id)
            </prototype>
        </function>
=cut

sub is_reserved_id {
    my $id = shift;
    my $path = "$oyster::CONFIG{site_path}styles/$id/";
    return ( (-d $path and !-f "${path}layout.xsl") ? 1 : 0 );
}

=xml
        <function name="">
            <synopsis>
                Calls xslcompiler.pl on all of the current site's styles, returns the url path to the style for the given stylesheets.
            </synopsis>
            <prototype>
                string stylesheet_url, string stylesheet_path = style::compile(string style[, string stylesheet][, string stylesheet])
            </prototype>
        </function>
=cut

sub compile {
    my $style       = shift;
    my @stylesheets = @_;
    my $style_path  = "$oyster::CONFIG{site_path}styles/$style/";
    my $style_url   = "$oyster::CONFIG{styles_url}$style/";

    # compile the base layout for this style if necessary
    if ($oyster::CONFIG{'compile_styles'} and (!-e "${style_path}base.xsl" or file::mtime("${style_path}source/layout.xsl") > file::mtime("${style_path}base.xsl") or file::mtime("$oyster::CONFIG{shared_path}styles/source.xsl") > file::mtime("${style_path}base.xsl"))) {
        file::write("${style_path}base.xsl", _compile_style($style, "styles/source.xsl"));
    }

    # return the url/path to the base layout if no stylesheets were specified
    return "${style_url}base.xsl", "${style_path}base.xsl" unless @stylesheets;

    # ensure that all of the stylesheets passed are compiled
    my (@dyn_style_name, $includes);
    for my $file (@stylesheets) {
        $includes .= "<xsl:include href=\"${style_url}modules/$file\" />\n";
        my $dyn_name = $file;
        $dyn_name =~ s/\.xsl$//og;
        $dyn_name =~ s/\//_/og;
        push @dyn_style_name, $dyn_name;
        if ($oyster::CONFIG{'compile_styles'} and _needs_compilation($style, $file)) {
            my $template;
            $template .= "<?xml version='1.0' encoding=\"UTF-8\" ?>\n";
            $template .= "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"\n xmlns=\"http://www.w3.org/1999/xhtml\">\n\n";
            $template .= _compile_style($style, "modules/$file") . "\n";
            $template .= "</xsl:stylesheet>\n";
            my ($module_id) = ($file =~ m!^(.+?)/!);
            file::mkdir("${style_path}modules/$module_id/");
            file::write("${style_path}modules/$file", $template);
        }
    }

    # create a dynamic style to combine all of the passed styles (if necessary)
    my $dyn_name = join('-', @dyn_style_name) . '.xsl';
    if ($oyster::CONFIG{'compile_styles'} and !-e "${style_path}dynamic/$dyn_name") {
        my $dyn_style;
        $dyn_style .= "<?xml version='1.0' encoding=\"UTF-8\" ?>\n";
        $dyn_style .= "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"\n xmlns=\"http://www.w3.org/1999/xhtml\">\n\n";
        $dyn_style .= "<xsl:include href=\"${style_url}base.xsl\" />\n\n";
        $dyn_style .= "$includes\n";
        $dyn_style .= "</xsl:stylesheet>\n";
        mkdir("${style_path}dynamic/") unless -d "${style_path}dynamic/";
        file::write("${style_path}dynamic/$dyn_name", $dyn_style);
    }

    return "${style_url}dynamic/$dyn_name", "${style_path}dynamic/$dyn_name";
}

=xml
    </section>
    
    <section title="Private Functions">
=cut

=xml
        <function name="_get_module_stylesheets">
            <todo>
                Documentate this function
            </todo>
        </function>
=cut

sub _get_module_stylesheets {
    my %module_stylesheets;
    for my $module (keys %module::loaded) {
        for my $file (grep(!/\.hook\.xsl$/, <modules/$module/*.xsl>)) {
            $file =~ s!^modules/$module/!!;
            push @{$module_stylesheets{$module}}, $file;
        }
    }
    return \%module_stylesheets;
}

=xml
        <function name="_needs_compilation">
            <todo>
                Documentate this function
            </todo>
        </function>
=cut

sub _needs_compilation {
    my ($style, $file, $is_server_side) = @_;

    return if $is_server_side; # this isn't used for anything server side (note: it is called on <swaf:include, but those don't even do anything for server-side styles)

    my $style_path = "$oyster::CONFIG{site_path}styles/$style/";

    # if this template hasn't been compiled at all
    return 1 unless -e "${style_path}modules/$file";

    # if this style has a style for this particular template
    if (-e "${style_path}source/modules/$file") {
        return file::mtime("${style_path}source/modules/$file") > file::mtime("${style_path}modules/$file") ? 1 : 0 ;
    }

    # if the general template is being used
    else {
        return file::mtime("modules/$file") > file::mtime("${style_path}modules/$file") ? 1 : 0 ;
    }
}

=xml
        <function name="_load">
            <synopsis>
                Loads (or reloads) enabled styles
            </synopsis>
            <prototype>
                _load()
            </prototype>
        </function>
=cut

sub _load {

    # clear style data (for reloads)
    %styles = ();

    # populate style data
    my $query = $oyster::DB->query("SELECT id, name, status FROM $oyster::CONFIG{db_prefix}styles");
    while (my $style = $query->fetchrow_hashref()) {
        $styles{$style->{'id'}} = $style;
    }
}

=xml
        <function name="_compile_style">
            <todo>
                should hooks/global includes be compiled?
            </todo>
            <todo>
                Documentate this function
            </todo>
        </function>
=cut

sub _compile_style {
    my ($style, $file, $is_server_side) = @_;
    my $style_url  = "$oyster::CONFIG{styles_url}$style/";
    my $style_path = "$oyster::CONFIG{site_path}styles/$style/";

    $file = $style_path . 'source/' . $file if -e $style_path . 'source/' . $file;

    my $stylesheet = file::slurp($file);

    # replace conditionals
    $stylesheet =~ s{<swaf:(.+?)>([\s\S]+?)</swaf:\1>}{
        my ($tag, $data) = ($1, $2);
        if ($tag eq 'if_client_side') {
            $is_server_side ? '' : $data ;
        }
        elsif ($tag eq 'if_server_side') {
            $is_server_side ? $data : '';
        }
    }eg;

    # replace singleton tags
    $stylesheet =~ s{<swaf:(.+?) />}{
        my $tag = $1;
        my $insert;

        # includes/imports
        if ($tag =~ /^((?:include)|(?:import)) href="(.+?)"/o) {

            my ($directive, $include_file) = ($1, $2);

            # ensure that the file to be included has been compiled
            if ($oyster::CONFIG{'compile_styles'} and _needs_compilation($style, $include_file, $is_server_side)) {
                my $template;
                $template .= "<?xml version='1.0' encoding=\"UTF-8\" ?>\n";
                $template .= "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"\n xmlns=\"http://www.w3.org/1999/xhtml\">\n\n";
                $template .= _compile_style($style, "modules/$include_file", $is_server_side) . "\n";
                $template .= "</xsl:stylesheet>\n";
                my ($module_id) = ($include_file =~ m!^(.+?)/!);
                file::mkdir("${style_path}modules/$module_id/");
                file::write("${style_path}modules/$include_file", $template);
            }

            # return the proper xsl to include/import the file
            if ($is_server_side) {
                # should server side includes actually include anything? since they can only include other module styles.. and those styles are compiled into server_base.xsl...
            } else {
                $insert = "<xsl:" . ( $directive eq 'include' ? 'import' : 'include' ) . " href=\"${style_url}modules/$include_file\" />\n";
            }
        }

        # hooks
        elsif ($tag =~ /^include hook="(.+?)"/o) {

            my $hook = $1;

            # assemble hook include data
            while (my $include_file = <modules/*/$hook.hook.xsl>) {
                $include_file = $style_path . 'source/' . $include_file if -e $style_path . 'source/' . $include_file;
                $insert .= file::slurp($include_file);
            }
        }

        # include the layout (for source.xsl only)
        elsif ($tag eq 'include_layout') {

            # return the contents of layout.xsl
            $insert = file::slurp($style_path . 'source/layout.xsl');
        }

        # shared includes/imports (for source.xsl only)
        elsif ($tag =~ /^((?:include)|(?:import))_shared href="(.+?)"/o) {

            my ($directive, $include_file) = ($1, $2);

            # return the proper xsl to include/import the file
            if ($is_server_side) {
                $insert = file::slurp("$oyster::CONFIG{site_path}styles/$include_file");
            } else {
                $insert = "<xsl:" . ( $directive eq 'include' ? 'import' : 'include' ) . " href=\"$oyster::CONFIG{styles_url}$include_file\" />\n";
            }
        }

        # module style includes (for server-side source.xsl only)
        elsif ($tag eq 'include_modules' and $is_server_side) {
            my $module_stylesheets = style::_get_module_stylesheets();
            for my $module_id (keys %{$module_stylesheets}) {
                $insert .= "\n<!-- MODULE: $module_id -->\n\n";
                for my $include_file (@{$module_stylesheets->{$module_id}}) {
                    $insert .= "\n<!-- $include_file -->\n\n";
                    $insert .= style::_compile_style($style, "modules/$module_id/$include_file", $is_server_side) . "\n";
                }
            }
        }

        # return the xml/xslt to be inserted in place of the tag
        $insert;
    }eg;

    return $stylesheet;
}

=xml
    </section>
=cut

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
