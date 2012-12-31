=xml
<document title="Style &amp; Templates Functions">
    <synopsis>
        Functions related to styles and templates
    </synopsis>
=cut
package style;

use exceptions;

our %styles;

event::register_hook('load_lib', '_load');

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
        <function name="register">
            <synopsis>
                Adds an entry to the current site's styles table
            </synopsis>
            <prototype>
                style::register(string style_id, string style_name)
            </prototype>
            <note>
                This does nothing (and returns undef) if the given style ID is already registered.
            </note>
        </function>
=cut

sub register {
    my ($style_id, $name) = @_;
    return if is_registered($style_id);
    $oyster::DB->do("INSERT INTO $oyster::CONFIG{db_prefix}styles (id, name) VALUES (?, ?)", {}, $style_id, $name);
}

=xml
        <function name="unregister">
            <synopsis>
                Removes a style's entry in the current site's styles table
            </synopsis>
            <note>
                This does nothing if passed a non-existant style ID.
            </note>
            <prototype>
                style::unregister(string style_id)
            </prototype>
        </function>
=cut

sub unregister {
    my $style_id = shift;
    $oyster::DB->do("DELETE FROM $oyster::CONFIG{db_prefix}styles WHERE id = ?", {}, $style_id);
}

=xml
        <function name="enable">
            <synopsis>
                Enables a style
            </synopsis>
            <note>
                This does nothing if passed an invalid style ID.
            </note>
            <prototype>
                style::enable(string style_id)
            </prototype>
        </function>
=cut

sub enable {
    my $style_id = shift;
    $oyster::DB->do("UPDATE $oyster::CONFIG{db_prefix}styles SET status = '1' WHERE id = ?", {}, $style_id);
}

=xml
        <function name="disable">
            <synopsis>
                Disables a style
            </synopsis>
            <note>
                This does nothing if passed an invalid style ID.
            </note>
            <prototype>
                style::disable(string style_id)
            </prototype>
        </function>
=cut

sub disable {
    my $style_id = shift;
    $oyster::DB->do("UPDATE $oyster::CONFIG{db_prefix}styles SET status = '0' WHERE id = ?", {}, $style_id);
}

=xml
        <function name="is_enabled">
            <synopsis>
                Checks if a given style is enabled
            </synopsis>
            <prototype>
                bool = style::is_enabled(string style_id)
            </prototype>
        </function>
=cut

sub is_enabled {
    my $style_id = shift;
    return $oyster::DB->selectrow_arrayref("SELECT status FROM $oyster::CONFIG{db_prefix}styles WHERE id = ? LIMIT 1", {}, $style_id)->[0];
}

=xml
        <function name="is_registered">
            <synopsis>
                Checks if a given style is registered
            </synopsis>
            <prototype>
                bool = style::is_registered(string style_id)
            </prototype>
        </function>
=cut

sub is_registered {
    my $style_id = shift;
    return if $oyster::DB->selectrow_arrayref("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}styles WHERE id = ? LIMIT 1", {}, $style_id)->[0];
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
    return if exists $oyster::REQUEST{'printed_header'};

    # get the stylesheet's url and compile it if necessary
    my $stylesheet = (compile($oyster::REQUEST{'style'}, @{$oyster::REQUEST{'templates'}}))[0];

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
              . ' page_title="' . $oyster::REQUEST{'current_url'}->{'title'} . '"'
              . ' base="' .   $oyster::CONFIG{'url'} . '"'
              . ' styles="' . $oyster::CONFIG{'styles_url'} . '"'
              . ' browser="' . $oyster::REQUEST{'ua_browser'} . '"'
              . ' renderer="' . $oyster::REQUEST{'ua_render_engine'} . '"'
              . ' os="' . $oyster::REQUEST{'ua_os'} . '"'
              . ' style="' .  $oyster::REQUEST{'style'} . '"'
              . ' url="' .    $oyster::CONFIG{'url'} . ( length $oyster::REQUEST{'url'} ? $oyster::REQUEST{'url'} . '/' : '' ) . '"';
    $attrs .= ' module="' . $oyster::REQUEST{'module'} . '"' if length $oyster::REQUEST{'module'};
    $attrs .= ' query_string="?' . xml::entities($ENV{'QUERY_STRING'}) . '"' if length $ENV{'QUERY_STRING'};
    if (exists $oyster::REQUEST{'handler'}) {
        $attrs .= ' handler="' . $oyster::REQUEST{'handler'} . '"';
        $attrs .= ' ajax_target="' . $oyster::INPUT{'ajax_target'} . '"' if exists $oyster::INPUT{'ajax_target'};
    }

    print "<oyster$attrs>\n";

    $oyster::REQUEST{'printed_header'} = undef;
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
    return if exists $oyster::REQUEST{'printed_footer'};
    print "\t<benchmark>" . sprintf('%.5f', Time::HiRes::gettimeofday() - $oyster::REQUEST{'start_time'}) . "</benchmark>\n" if $oyster::CONFIG{'debug'};
    print "</oyster>\n";
    $oyster::REQUEST{'printed_footer'} = undef;
}

=xml
        <function name="print_styles_xml">
            <synopsis>
                Prints styles in an xml-friendly manner.
            </synopsis>
            <prototype>
                style::print_styles_xml()
            </prototype>
        </function>
=cut

sub print_styles_xml {
    _load();
    print "\t\t<styles>\n";
    for my $style (values %styles) {
        print "\t\t\t<style id=\"$style->{id}\" name=\"$style->{name}\" status=\"$style->{status}\" />\n";
    }
    print "\t\t</styles>\n";
}

=xml
        <function name="print_enabled_styles_xml">
            <synopsis>
                Print enabled styles in an xml-friendly manner.
            </synopsis>
            <prototype>
                style::print_enabled_styles_xml()
            </prototype>
        </function>
=cut

sub print_enabled_styles_xml {
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
        return $oyster::DB->selectrow_arrayref("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}styles WHERE id = ? and id != ? LIMIT 1", {}, $new_id, $current_id)->[0];
    } else {
        my $id = shift;
        return $oyster::DB->selectrow_arrayref("SELECT COUNT(*) FROM $oyster::CONFIG{db_prefix}styles WHERE id = ? LIMIT 1", {}, $id)->[0];
    }
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
        <function name="compile">
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
    my $xmlns       = $style::styles{$style}->{'output'} eq 'xhtml' ? "\n xmlns=\"http://www.w3.org/1999/xhtml\"" : '';

    # if dynamic style compilation is disabled
    unless ($oyster::CONFIG{'compile_styles'}) {

        # return the url/path to the base layout if no stylesheets were specified
        return "${style_url}base.xsl", "${style_path}base.xsl" unless @stylesheets;

        # otherwise return the url to the dynamic style
        # ugly work around for whatever reason map fails in fastcgi
        my $dyn_name;
        for my $file (@stylesheets) {
            $dyn_name = $file;
            $dyn_name =~ s/\.xsl$//og;
            $dyn_name =~ s/\//_/og;
            $dyn_name .= '.xsl';
        }
        #my $dyn_name = join('-', map { s!\.xsl$!!og; s!/!_!og } @stylesheets) . '.xsl';
        return "${style_url}dynamic/$dyn_name", "${style_path}dynamic/$dyn_name";
    }

    my $recompile_server_base = 0;

    # compile the base layout for this style if necessary
    if (!-e "${style_path}base.xsl" or file::mtime("${style_path}source/layout.xsl") > file::mtime("${style_path}base.xsl") or file::mtime("./styles/source.xsl") > file::mtime("${style_path}base.xsl")) {
        file::write("${style_path}base.xsl", _compile_style($style, "styles/source.xsl"));
        $recompile_server_base = 1;
    }

    # return the url/path to the base layout if no stylesheets were specified
    unless (@stylesheets) {
        file::write("${style_path}server_base.xsl", style::_compile_style($style, "styles/source.xsl", 1)) if $recompile_server_base == 1;
        return "${style_url}base.xsl", "${style_path}base.xsl";
    }

    # ensure that all of the stylesheets passed are compiled
    my (@dyn_style_name, $includes);
    for my $file (@stylesheets) {
        $includes .= "<xsl:include href=\"${style_url}modules/$file\" />\n";
        my $dyn_name = $file;
        $dyn_name =~ s/\.xsl$//og;
        $dyn_name =~ s/\//_/og;
        push @dyn_style_name, $dyn_name;
        if (_needs_compilation($style, $file)) {
            my $template =
                "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
              . "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"$xmlns>\n\n"
              .  _compile_style($style, "modules/$file") . "\n"
              .  "</xsl:stylesheet>\n";
            my ($module_id) = ($file =~ m!^(.+?)/!);
            file::mkdir("${style_path}modules/$module_id/");
            file::write("${style_path}modules/$file", $template);
            $recompile_server_base = 1;
        }
    }

    # create a dynamic style to combine all of the passed styles (if necessary)
    my $dyn_name = join('-', @dyn_style_name) . '.xsl';
    if (!-e "${style_path}dynamic/$dyn_name") {
        my $dyn_style =
            "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
          . "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"$xmlns>\n\n"
          . "<xsl:include href=\"${style_url}base.xsl\" />\n\n"
          . "$includes\n"
          . "</xsl:stylesheet>\n";
        mkdir("${style_path}dynamic/") unless -d "${style_path}dynamic/";
        file::write("${style_path}dynamic/$dyn_name", $dyn_style);
    }

    # recompile server_base.xsl if necessary
    file::write("${style_path}server_base.xsl", style::_compile_style($style, "styles/source.xsl", 1)) if $recompile_server_base == 1;

    return "${style_url}dynamic/$dyn_name", "${style_path}dynamic/$dyn_name";
}

=xml
    </section>
    
    <section title="Private Functions">
=cut

=xml
        <function name="_get_module_stylesheets">
            <todo>
                Dcoument this function
            </todo>
        </function>
=cut

sub _get_module_stylesheets {
    my %module_stylesheets;
    for my $module (keys %module::loaded) {
        my $module_path = $module::paths{$module} . $module;
           $module_path =~ s/ /\\ /g;   # otherwise glob is going to split on the whitespace
        for my $file ( grep( !/\.hook\.xsl$/, glob("$module_path/*.xsl") ) ) {
            $file =~ s!^../.+?/modules/$module/!!;
            push @{$module_stylesheets{$module}}, $file;
        }
    }
    return \%module_stylesheets;
}

=xml
        <function name="_needs_compilation">
            <todo>
                Document this function
            </todo>
        </function>
=cut

sub _needs_compilation {
    my ($style, $file, $is_server_side) = @_;

    return if $is_server_side; # this isn't used for anything server side (note: it is called on <oyster:include, but those don't even do anything for server-side styles)

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

    %styles = %{$oyster::DB->selectall_hashref("SELECT id, name, status, output FROM $oyster::CONFIG{db_prefix}styles", 'id')};
    
    # clear style data (for reloads)
    #%styles = ();

    # populate style data
    #my $query = $oyster::DB->query("SELECT id, name, status FROM $oyster::CONFIG{db_prefix}styles");
    #while (my $style = $query->fetchrow_hashref()) {
    #    $styles{$style->{'id'}} = $style;
    #}
}

=xml
        <function name="_compile_style">
            <todo>
                should hooks/global includes be compiled?
            </todo>
            <todo>
                Document this function
            </todo>
        </function>
=cut

sub _compile_style {
    my ($style, $file, $is_server_side) = @_;
    my $style_url  = "$oyster::CONFIG{styles_url}$style/";
    my $style_path = "$oyster::CONFIG{site_path}styles/$style/";
    my $xmlns      = $style::styles{$style}->{'output'} eq 'xhtml' ? "\n xmlns=\"http://www.w3.org/1999/xhtml\"" : '';

    $file = $style_path . 'source/' . $file if -e $style_path . 'source/' . $file;

    my $stylesheet = file::slurp($file);

    # replace conditionals
    $stylesheet =~ s{<oyster:(.+?)>([\s\S]+?)</oyster:\1>}{
        my ($tag, $data) = ($1, $2);
        if ($tag eq 'if_client_side') {
            $is_server_side ? '' : $data ;
        }
        elsif ($tag eq 'if_server_side') {
            $is_server_side ? $data : '';
        }
    }eg;

    # replace singleton tags
    $stylesheet =~ s{<oyster:(.+?) />}{
        my $tag = $1;
        my $insert;

        # includes/imports
        if ($tag =~ /^((?:include)|(?:import)) href="(.+?)"/o) {

            my ($directive, $include_file) = ($1, $2);

            # ensure that the file to be included has been compiled
            if ($oyster::CONFIG{'compile_styles'} and _needs_compilation($style, $include_file, $is_server_side)) {
                my $template;
                $template .= "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
                $template .= "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"$xmlns>\n\n";
                #$template .= _compile_style($style, "modules/$include_file", $is_server_side) . "\n";
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
            
            # opening xsl:stylesheet element
            if ($is_server_side) {
                $insert = "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"$xmlns>\n";
            } else {
                $insert = "<xsl:stylesheet version=\"1.0\"\n xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\"\n xmlns:dt=\"http://xsltsl.org/date-time\"\n xmlns:str=\"http://xsltsl.org/string\"$xmlns>\n"
                        . "<xsl:import href=\"$oyster::CONFIG{styles_url}date-time.xsl\" />\n"
                        . "<xsl:import href=\"$oyster::CONFIG{styles_url}string.xsl\" />\n";
            }

            # return the contents of layout.xsl
            $insert .= file::slurp($style_path . 'source/layout.xsl');
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
                    #$insert .= style::_compile_style($style, "modules/$module_id/$include_file", $is_server_side) . "\n";
                }
            }
        }

        # return the xml/xslt to be inserted in place of the tag
        $insert;
    }eg;

    # replace configuration variables
    $stylesheet =~ s/{\$oyster::config::([a-z_]+)}/
        my ($var)  = ($1);
        my $insert = '';

        if ($var eq '') {
            #
        }

        $insert;
    /eg;


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
