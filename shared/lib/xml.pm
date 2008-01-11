=xml
<document title="XML Functions">
    <synopsis>
        Functions related to xml validation, transformation, and parsing.
    </synopsis>
    <todo>
        Possibly make include/call syntax more strict so the regex parsing is
        faster.
    </todo>
    <todo>
        I think there may be a bug with proper_english in the xhtml and bbcode
        parsers -- since they pass entify text in small chunks entities that have
        a start end (quotations) will not work properly if there is a tag/element
        between them.
    </todo>
=cut

package xml;

use exceptions;
use event;

# load xml entities -- these are in the db primarily because my text editor doesn't support UTF8! so I could never edit this file with all of the entities here!
our (%bbcode, %xhtml_tags);
event::register_hook('load_lib', '_load');
sub _load {

    # load bbcode tags
    my $query = $oyster::DB->query("SELECT * FROM bbcode");
    while (my $tag = $query->fetchrow_hashref()) {
        my $tag_name = delete $tag->{'tag'}; # deleted to save *a little* memory
        $bbcode{$tag_name} = $tag;
    }

    # load xhtml tags
    my $query = $oyster::DB->query("SELECT * FROM xhtml_tags");
    while (my $tag = $query->fetchrow_hashref()) {
        $xhtml_tags{$tag->{'tag'}} = $tag->{'permission_level'};
    }
}

=xml
    <function name="strip_elements">
        <synopsis>
            Takes an xml-safe string and strips xml elements (aka tags/nodes)
        </synopsis>
        <note>
            The 'xml-safe' part is important! If the string contains '&lt;' or '&gt;',
            they will be interpretted as parts of xml elements.
        </note>
        <note>
            The optional second argument can be used to replace elements with
            something instead of merely stripping them.
        </note>
        <prototype>
            string = xml::strip_elements(string[, string replace_with])
        </prototype>
    </function>
=cut

sub strip_elements {
    my $string = shift;
    return '' unless length $string; # don't return undef, theyll always be expecting a string (will error if you try to insert undef into the db for a string column)
                                     # don't just check for trueness! otherwise xml::strip_elements('0') returns ''!

    my $replace = length $_[0] ? shift : '' ;

    $string =~ s/<.+?>/$replace/og;

    return $string;
}

=xml
    <function name="replace_entities">
        <synopsis>
            Takes an XML-safe string and replaces XML entities with their plain ASCII equivalents
        </synopsis>
        <prototype>
            string = xml::replace_entities(string)
        </prototype>
    </function>
=cut

sub replace_entities {
    my $string = shift;
    return '' unless length $string; # don't return undef, theyll always be expecting a string (will error if you try to insert undef into the db for a string column)
                                     # don't just check for trueness! otherwise xml::replace_entities('0') returns ''!

    # replace basic entities
    $string =~ s/&amp;/&/og;
    $string =~ s/&gt;/>/og;
    $string =~ s/&lt;/</og;
    $string =~ s/&#34;/"/og;

    # un-transform proper-english-entities
    $string =~ s/&#8212;/--/og;    # dash
    $string =~ s/&#8722;/-/og;     # subtraction
    $string =~ s/&#8211;/-/og;     # hypens
    $string =~ s/&#8230;/.../og;   # ellipses
    $string =~ s/&#8216;/'/og;     # single quotes
    $string =~ s/&#8217;/'/og;
    $string =~ s/&#8220;/"/og;     # double quotes
    $string =~ s/&#8221;/"/og;        
    $string =~ s/&#39;/'/og;       # apostrophes

    # replace any remaining numerical entities
    $string =~ s/&#([0-9]+);/chr($1)/oeg;

    return $string;
}

=xml
    <function name="entities">
        <synopsis>
            Takes a string and makes it XML-safe.
        </synopsis>
        <note>
            The 'safe' flag, if set, will not re-entify things that already look
            like entities; this is useful if you are not sure if a string already
            contains XML entities.  For example, xml::entities('&amp;amp;', safe => 1)
            would result in '&amp;amp;', not '&amp;amp;amp;'.
        </note>
        <note>
            The 'proper_english' flag replaces various entities with their "proper"
            equivalents, including: ellipses, dashes, subtraction, hyphenation,
            single/double quotes, and apostrophes.
        </note>
        <prototype>
            string = xml::entities(string[, 'safe'][, 'proper_english'])
        </prototype>
        <example>
            print xml::entities($INPUT{'title'});
        </example>
        <todo>
            This should accept multiple strings like attr_entities
        </todo>
        <todo>
            This should NOT protect against double-entitying something (add entities_safe or something for that)
        </todo>
        <todo>
            check if these (?:)'s are necessary
        </todo>
        
    </function>
=cut

sub entities {
    my $string = shift;
    return '' unless length $string; # don't return undef, theyll always be expecting a string (will error if you try to insert undef into the db for a string column)
                                   # don't just check for trueness! otherwise xml::entities('0') returns ''!

    my %flags = map {($_ => undef)} @_;

    # safe translation
    if (exists $flags{'safe'}) {
        $string =~ s/&(?!amp;)(?!gt;)(?!lt;)(?!#\d+;)/&amp;/og;
    }

    # normal translation
    else {
        $string =~ s/&/&amp;/og;
    }

    $string =~ s/</&lt;/og;
    $string =~ s/>/&gt;/og;
    $string =~ s/"/&#34;/og; # this is actually only necessary for attributes, but why make another function just for those

    # transform proper english entities
    if (exists $flags{'proper_english'}) {
        $string =~ s/([a-zA-Z]\s?)--(\s?[a-zA-Z])/$1&#8212;$2/og; # dash
        $string =~ s/(\d\s?)-(\s?\d)/$1&#8722;$2/og;              # subtraction
        $string =~ s/([a-zA-Z])-([a-zA-Z])/$1&#8211;$2/og;        # hypens
        $string =~ s/\Q...\E/&#8230;/og;                          # ellipses
        $string =~ s/&#34;([\s\S]+?)&#34;/&#8220;$1&#8221;/og;    # double quotes
        $string =~ s/([a-zA-Z])'([a-zA-Z])/$1&#39;$2/og;          # apostrophes (has to be before single quotes)
        $string =~ s/'(\s\S+?)'/&#8216;$1&#8217;/og;              # single quotes
    }

    return $string;
}

=xml
    <function name="bbcode">
        <synopsis>
            Transforms BBcode into XHTML
        </synopsis>
        <note>
            This function raises a validation_error if a problem is encountered.
        </note>
        <prototype>
            string xhtml = xml::bbcode(string bbcode[, disabled_tags => hashref, allow_calls => bool, allow_includes => bool])
        </prototype>
        <example>
            my $post = xml::bbcode($INPUT{'post'});
        </example>
        <todo>
            automatic linking for URLs
        </todo>
    </function>
=cut
#{
#my @stack; # bbcode tag stack
# lexicalizing @stack like this is only necessary for _bbcode_inspect_stack, which is currently unused
sub bbcode {
    my $text = shift;
    my %options = @_; # optional arguments
    my $xhtml;        # generated xhtml
    my $in_p = 0;     # true if you are inside of a paragraph
    my @lists;        # holds list data
    my @call_data;    # if calls are allowed, the array storing the call data
    my @stack; # bbcode tag stack

    # optimization for include shorthand so the parser does not have do so many tests each pass
    $text =~ s/\[include#(\d+)\]/\[include file file: $1\]/og if $options{'allow_includes'};

    # iterate through text
    while (length $text != 0) {
        my $remove_len           = 0; # length of text to chop off of the beginning of $text
        my $replace_post_newline = 0; # set to true if a bbcode was caught and it consumed newlines it shouldn't have
        my $replace_pre_newline  = 0;

        # call/include directives
        if (
                ($options{'allow_includes'} or $options{'allow_calls'}) # seems pointless to do this here, but it can short-circuit the regex
                and
                $text =~ /^(\[((?:include)|(?:call))\s+(\w+)\s+(\w+)(?:\s*:\s*(.+?))?\s*\])/o
                and ( ($2 eq 'include' and $options{'allow_includes'}) or ($2 eq 'call' and $options{'allow_calls'}) )
            ) {
            my ($match, $directive, $module, $func, $args) = ($1, $2, $3, $4, $5);
            $remove_len = length $match;
            throw 'validation_error' => "Invalid $directive directive: " . entities($module) . ' ' . entities($func) . ': ' . entities($args) unless UNIVERSAL::can($module, "${directive}_$func");

            # parse arguments
            my @args = split(/(?:\s*,\s*)|(?:\s*=>\s*)/o, $args);

            # includes
            if ($directive eq 'include') {

                # add result of include to output xml
                $xhtml .= &{"${module}::include_${func}"}(@args);
            }
            
            # calls
            else {

                # compile and add call data to @call_data
                push(@call_data, join("\0", length $xhtml, $module, $func, @args));
            }
        }

        # match bbcode tags
        elsif ($text =~ /^((\n)?\[(\/)?(\w+?)(?:=(.+?))?\](\n)?)/o) {
            my ($tag_full, $pre_newline, $is_end, $tag, $param, $post_newline) = ($1, $2, $3, $4, $5, $6);
            $remove_len = length $tag_full;
            $replace_post_newline = 1 if ($post_newline and !$bbcode{$tag}->{'consume_post_newline'});
            $replace_pre_newline  = 1 if ($pre_newline  and !$bbcode{$tag}->{'consume_pre_newline'});

            # the tag encountered is an enabled bbcode tag
            if (exists $bbcode{$tag} and !$options{'disabled_tags'}->{$tag}) {

                # end tags
                if ($is_end) {
                    throw 'validation_error' => "End tag with no start tag: $tag"  if scalar @stack == 0;
                    my $end_of = pop @stack;
                    throw 'validation_error' => "Expected end tag: $end_of->{tag}" unless $end_of->{'tag'} eq $tag;

                    my $pre       = substr($xhtml, 0, $end_of->{'offset'});
                    my $post      = substr($xhtml, $end_of->{'offset'});
                    my $xhtml_tag = $bbcode{$tag}->{'xhtml_tag'} ? $bbcode{$tag}->{'xhtml_tag'} : $end_of->{'tag'} ;
                    my $extra     = $bbcode{$tag}->{'extra'}     ? $bbcode{$tag}->{'extra'}     : '' ;

                    # urls
                    if ($end_of->{'tag'} eq 'url') {
                        my $url = $end_of->{'param'} ? entities($end_of->{'param'}) : entities($post) ;
                        $extra = " href=\"$url\" title=\"$url\"";
                    }

                    # list
                    elsif ($end_of->{'tag'} eq 'list') {
                        $xhtml_tag = $end_of->{'param'} eq '1' ? 'ol' : 'ul' ;
                        throw 'validation_error' => 'Empty list.' unless $end_of->{'num_items'};
                        $post .= '</li>';
                        pop @lists;
                    }

                    # add html
                    if ($in_p == 1 and $bbcode{$end_of->{'tag'}}->{'is_block'}) { # if this is a block element, close any open paragraphs
                        $post .= '</p>' if (scalar @lists == 0 and $end_of->{'tag'} ne 'list'); # needs both checks because you just popped @lists if the tag was a list
                        $in_p = 0;
                    }
                    if ($end_of->{'pre_offset'}) { # if this item consumed a newline needlessly properly place the <br> or <p> tag before the opening tag
                        $pre .= substr($post, 0, $end_of->{'pre_offset'}, "");
                    }
                    $xhtml = $pre . '<' . $xhtml_tag . $extra . ( $post ? '>' . $post . '</' .  $xhtml_tag . '>' : ' />' );
                }

                # start tags
                else {

                    # don't add paragraph tags inside of lists
                    if (scalar @lists == 0) {

                        # if you arent inside of a paragraph and this tag isn't a block, start a paragraph
                        if ($in_p == 0 and !$bbcode{$tag}->{'is_block'}) {
                            $xhtml .= '<p>';
                            $in_p = 1;
                        }

                        # if this a block element end the current paragraph
                        elsif ($bbcode{$tag}->{'is_block'}) {
                            $xhtml .= '</p>' if $in_p == 1;
                            $in_p = 0;
                        }
                    }

                    # add the tag to the stack
                    push(@stack, {'tag' => $tag, 'offset' => length $xhtml, 'param' => $param, 'consumed_pre_newline' => $replace_pre_newline, 'consumed_post_newline' => $replace_post_newline});

                    # if this is a [code] block
                    if ($tag eq 'code') {
                        $text = substr($text, $remove_len); # remove the starting code tag
                        $remove_len = 0; # you already removed the tag, don't do it again
                        ($text, $xhtml) = _bbcode_parse_code($text, $xhtml);
                    }

                    # if the tag is a list add it to a special stack
                    push(@lists, $stack[$#stack]) if $tag eq 'list';
                }
            }

            # the tag encountered is not a valid bbcode tag
            else {
                $xhtml .= entities($tag_full);
            }
        }

        # urls
        #elsif ($text =~ m!^(((?:ht|f)tps?://)?(?:[\D\S]\S+?\.)+)(?:\w{2,3})?!i and !defined($inspect_stack->('url'))) {
        #elsif ($text =~ m!^(\s+(((?:http|ftp|https)://)?(?:\D\S+?\.)+(?:[a-z]{2,3})))!i and !defined($inspect_stack->('url'))) {
        #elsif ($text =~ m!^((?:http://)(?:\w+?\.)+(?:\w{2,3}))!i and !defined($inspect_stack->('url'))) {
        #elsif ($text =~ m!^(www\.google\.com)! and !defined($inspect_stack->('url'))) {
        #    my ($url) = ($1);
        #    $remove_len = length($url);
        #    substr($text, length($text) - $remove_len, 0, "[url]$url[/url]");
        #}

        # list elements
        elsif (scalar @lists and $text =~ /^\Q[*]\E/o) {
            $remove_len = 3;
            $xhtml .= '</li>' if $lists[$#list]->{'num_items'};
            $lists[$#list]->{'num_items'}++;
            $xhtml .= '<li>';
        }

        # double newline (indicating paragraph start or end)
        elsif (substr($text, 0, 2) eq "\n\n" and scalar @lists == 0) {
            $remove_len = 2;
            my $p_tag;
            if ($in_p == 1) {
                $p_tag = '</p>';
                $in_p = 0;
            } else {
                $p_tag = '<p>';
                $in_p = 1;
            }
            if (scalar @stack and $stack[$#stack]->{'consumed_pre_newline'} and !$stack[$#stack]->{'pre_offset'}) { # if a tag just consumed a newline, make sure it knows the proper html offset for when it inserts its tag
                $stack[$#stack]->{'pre_offset'} = length($p_tag);
            }
            $xhtml .= $p_tag;
        }

        # single newline (indicating line break)
        elsif (substr($text, 0, 1) eq "\n") {
            $remove_len = 1;
            if ($in_p == 1) { # this should only be false if the text starts with a newline
                $xhtml .= '<br />';
                if (scalar(@stack) and $stack[$#stack]->{'consumed_pre_newline'} and !$stack[$#stack]->{'pre_offset'}) { # if a tag just consumed a newline, make sure it knows the proper html offset for when it inserts its tag
                    $stack[$#stack]->{'pre_offset'} = 6;
                }
            } elsif (scalar @lists and $lists[$#lists]->{'num_items'}) {
                $xhtml .= '<br />';
            }
        }

        #elsif (!defined($inspect_stack->('url')) and $text =~ s!^(www\.google\.com)![url]$1[/url]!) { next }

        # match anything not a bbcode tags
        #else {
        #    my $char = substr($text, 0, 1, '');
        #    if ($in_p == 0 and scalar @lists == 0) {
        #        $xhtml .= '<p>';
        #        $in_p = 1;
        #    }
        #    $xhtml .= $entities{$char} ? "&#$entities{$char};" : $char; # faster than a call to entities and this works fine for single characters # TODO: does it? with the new xml::entities
        #}

        # anything before a [, this is necessary for entities() to pick up anything longer than 1 char
        elsif ($text =~ /^([\s\S]+?)(?=\[)/o) {
            my $chunk = $1;
            $remove_len = length $chunk;
            $xhtml .= entities($chunk, 'proper_english');
        }

        # nothing has matched a [ yet it must just be a plain [
        elsif (substr($text, 0, 1) eq '[') {
            $remove_len = 1;
            $xhtml .= '&lt;';
        }

        # no more ['s, so there must not be any more bbcode tags, entity the rest of the text
        else {
            $remove_len = length $text;
            $xml .= entities($text, 'proper_english');
        }

        # remove parsed text from $text
        $text = substr($text, $remove_len);

        # put newlines back if they consumed and they weren't supposed to be!
        if ($replace_post_newline) {
           $replace_post_newline = 0;
           $text = "\n$text";
        }
        if ($replace_pre_newline) {
           $replace_pre_newline = 0;
           $text = "\n$text";
        }
    }

    # close paragraph if there's one still open
    if ($in_p == 1) {
        $xhtml .= '</p>';
        $in_p = 0;
    }

    # error on unclosed tags
    if (scalar @stack != 0) {
        my @unended;
        push(@unended, $_->{'tag'}) for @stack;
        throw 'validation_error' => 'Unended tag(s): ' . join(', ', @unended);
    }

    # clear @stack (since it is not lexical to just this sub)
    #@stack = ();

    # return xhtmlified bbcode
    if ($options{'allow_calls'}) {
        my $call_data = join("\n", @call_data);
        return $xhtml, $call_data;
    } else {
        return $xhtml;
    }
}

=xml
    <function name="_bbcode_parse_code">
        <synopsis>
            Parses BBcode until a [/code] tag is found
        </synopsis>
        <note>
            This function properly keeps track of embedded [code] tags and only
            returns when the right ending tag is found.
        </note>
        <note>
            This is used internally by bbcode(), modules should never need to
            call this; it is not exported by default.
        </note>
        <prototype>
            my ($bbcode, $xhtml) = _bbcode_parse_code($bbcode, $xhtml)
        </prototype>
    </function>
=cut

sub _bbcode_parse_code {
    my ($text, $xhtml) = @_;
    my $depth       = 1;
    my $replace_len = 0;
    while (length $text != 0) {

        # begin a code block
        if ($text =~ /^\[code\]/o) {
            $depth++;
            $xhtml .= '[code]';
            $replace_len = 6;
        }

        # end a code block
        elsif ($text =~ /^\[\/code\]/o) {
            $depth-=1;
            if ($depth == 0) {
                return $text, $xhtml;
            } else {
                $replace_len = 7;
                $xhtml .= "[/code]";
            }
        }

        # anything before a [, this is necessary for entities() to pick up anything longer than 1 char
        elsif ($text =~ /^([\s\S]+?)(?=\[)/o) {
            my $chunk = $1;
            $remove_len = length $chunk;
            $xhtml .= entities($chunk);
        }

        # nothing has matched a [ yet it must just be a plain [
        elsif (substr($text, 0, 1) eq '[') {
            $remove_len = 1;
            $xhtml .= '[;';
        }

        else {
            throw 'validation_error' => 'Error parsing code tag.';
            #$replace_len = 0;
            #my $char = substr($text, 0, 1, '');
            #$xhtml .= $entities{$char} ? "&#$entities{$char};" : $char; # faster than a call to entities and this works fine for single characters
        }
        substr($text, 0, $replace_len, '');
    }
    throw 'validation_error' => 'Unended code tag.';
}

=xml
    <function name="_bbcode_inspect_stack">
        <warning>
            Unimplemented
        </warning>
        <synopsis>
            Allows you to inspect the bbcode tag stack
        </synopsis>
        <note>
            This function returns undef if the tag is not found, this means
            that if you are checking to see if a tag is in the stack (and don't
            care about its position) you must check if the result is defined,
            not just that it is true.
        </note>
        <note>
            Offset defaults to zero.
        </note>
        <prototype>
            int position = _bbcode_inspect_stack(string tag_name[, int offset])
        </prototype>
    </function>
=cut

#sub _bbcode_inspect_stack {
#    my $tag   = shift;
#    my $index = shift || 0 ;
#    while ($index <= $#stack) {
#        return $index if $stack[$index]->{'tag'} eq $tag;
#    } continue { $index++ }
#    return;
#}
#}

=xml
    <function name="validate_xhtml">
        <synopsis>
            Validates xhtml and returns the xml-compatible equivalent
        </synopsis>
        <note>
            This may potentially change the xhtml, transforming some entities to be
            xml-friendly.
        </note>
        <note>
            If a parse-error is encountered, a validation_error will be raised.
        </note>
        <note>
            Calls allow you to dynamically (each page view) include data from other
            modules.
        </note>
        <note>
            Includes allow you to include data from other modules when the page is
            saved.
        </note>
        <note>
            The permission level option allows you to only enable certain xhtml
            tags.
        </note>
        <prototype>
            string xml = xml::validate_xhtml(string xhtml[, permission_level => int level, allow_calls => bool, allow_includes => bool])
        </prototype>
        <todo>
            uh.. should this be a static search and replace BEFORE this loop starts?
        </todo>
    </function>
=cut

sub validate_xhtml {
    my $xhtml = shift;  # incoming xml
    my %options = @_;   # optional arguments
    $options{'permission_level'} ||= 2; # xhtml tag permission level -- see variables at top of file
    my $xml;            # generate xml
    my @call_data;      # if calls are allowed, the array storing the call data
    my @stack;          # xhtml tag stack
    my $ignore_tag = 0; # if a tag is matched that shouldn't be, the loop is restarted and that tag is ignored, set to true if that needs to happen

    # optimization for include shorthand so the parser does not have do so many tests each pass
    $xhtml =~ s/<!--\s*include\s*#\s*(\d+)\s*-->/<!--include file file: $1-->/og if $options{'allow_includes'};
    #$xhtml =~ s/<!--include#(\d+)-->/<!--include file file: $1-->/g if $options{'allow_includes'};

    # iterate through xhtml until there is none left
    ITER_XHTML: while (length $xhtml != 0) {
        my $replace_len = 0;

        # call/include directives
        if (
                ($options{'allow_includes'} or $options{'allow_calls'}) # seems pointless to do this here, but it can short-circuit the regex
                and
                $xhtml =~ /^(<!--\s*((?:include)|(?:call))\s+(\w+)\s+(\w+)(?:\s*:\s*(.+?))?\s*-->)/o
                and ( ($2 eq 'include' and $options{'allow_includes'}) or ($2 eq 'call' and $options{'allow_calls'}) )
            ) {
            my ($match, $directive, $module, $func, $args) = ($1, $2, $3, $4, $5);
            $replace_len = length $match;
            throw 'validation_error' => "Invalid $directive directive: " . entities($module) . ' ' . entities($func) . ': ' . entities($args) unless UNIVERSAL::can($module, "${directive}_$func");

            # parse arguments
            my @args = split(/(?:\s*,\s*)|(?:\s*=>\s*)/o, $args);

            # includes
            if ($directive eq 'include') {

                # add result of include to output xml
                $xml .= &{"${module}::include_${func}"}(@args);
            }
            
            # calls
            else {

                # compile and add call data to @call_data
                push(@call_data, join("\0", length $xml, $module, $func, @args));
            }
        }

        # start tags
        elsif ($xhtml =~ /^(<(\w+)((?:\s*\w+\s*=\s*"[^"]*")+)?\s*(\/?)>)/o and $ignore_tag == 0) {
            my ($match, $tag, $attrs, $is_end) = ($1, lc $2, $3, $4);
            if (!defined $xhtml_tags{$tag} or $xhtml_tags{$tag} > $options{'permission_level'}) {
                $ignore_tag = 1;
                next ITER_XHTML; # TODO: is this whole ignore tag stuff necessary? just add the above if statement to the elsif
            }
            $replace_len = length $match;
            push(@stack, $tag) unless $is_end;
            my @attrs;
            while (length $attrs) {
                my $attr_replace_len = 1;
                if ($attrs =~ /^((\w+)\s*=\s*"([^"]*)")/o) {
                    my ($match, $name, $value) = ($1, $2, $3);
                    $attr_replace_len = length $match;
                    push(@attrs, $name . '="' . entities($value) . '"');
                }
                substr($attrs, 0, $attr_replace_len, '');
            }
            $xml .= "<$tag";
            $xml .= ' ' . join(' ', @attrs) if scalar @attrs != 0;
            $xml .= ' /' if $is_end;
            $xml .= '>';
        }

        # end tags
        elsif ($xhtml =~ /^(<\/(\w+)>)/o and !$ignore_tag) {
            my ($match, $tag) = ($1, lc $2);
            if (!defined($xhtml_tags{$tag}) or $xhtml_tags{$tag} > $options{'permission_level'}) {
                $ignore_tag = 1;
                next ITER_XHTML; # TODO: is this whole ignore tag stuff necessary? just add the above if statement to the elsif
            }
            $replace_len = length $match;
            throw 'validation_error' => "Mismatched end tag: $tag." unless pop @stack eq $tag;
            $xml .= "</$tag>";
        }

        # comments
        # TODO: uh.. should this be a static search and replace BEFORE this loop starts?
        elsif ($xhtml =~ s/^<!--.+?-->//og) {}

        # newlines
        elsif (substr($xhtml, 0, 1) eq "\n") {
            $replace_len = 1;
            $xml .= ' ';
        }
        
        # xml entities
        elsif ($xhtml =~ /^(&#\d+;)/o) {
            my $entity = $1;
            $replace_len = length $entity;
            $xml .= $entity;
        }

        # anything before a <, this is necessary for entities() to pick up anything longer than 1 char
        elsif ($xhtml =~ /^([\s\S]+?)(?=<)/o) {
            my $text = $1;
            $replace_len = length $text;
            $xml .= entities($text, 'proper_english');
        }

        # nothing has matched a < yet it must just be a plain <
        elsif (substr($xhtml, 0, 1) eq '<') {
            $replace_len = 1;
            $xml .= '&lt;';
        }

        # no more <'s, so there must not be any more xhtml tags, entity the rest of the xhtml
        else {
            $replace_len = length $xhtml;
            $xml .= entities($xhtml, 'proper_english');
        }

        $ignore_tag = 0;
        substr($xhtml, 0, $replace_len, '');
    }

    # check for unended tags
    throw 'validation_error' => 'Unended tag(s): ' . join(', ', @stack) if scalar @stack != 0;

    # return xmlified xhtml
    if ($options{'allow_calls'}) {
        my $call_data = join("\n", @call_data);
        return $xml, $call_data;
    } else {
        return $xml;
    }
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
