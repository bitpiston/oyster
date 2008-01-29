=xml
<document title="Email Functions">
    <synopsis>
        Functions associated with email.
    </synopsis>
=cut

package email;

use exceptions;

=xml
    <function name="is_valid_email">
        <synopsis>
            Validates a possible email address
        </synopsis>
        <prototype>
            bool is_valid = email::is_valid_email(string email_address)
        </prototype>
        <example>
            my $email = 'ShaneCalimlim@gmail.com';
            if (email::is_valid_email($email)) {
               print "$email is a valid email address\n";
            } else {
               print "$email is not a valid email address\n";
            }
        </example>
        <todo>
            rename is_valid_address? (email::is_valid_address sounds nice)
        </todo>
    </function>
=cut

sub is_valid_email {
    #return $_[0] !~ /^[a-zA-Z0-9._%-]+@[a-zA-Z0-9._%-]+\.[a-zA-Z]{2,6}$/ ? 0 : 1;
    $_[0] !~ /^[a-zA-Z0-9._%-]+@[a-zA-Z0-9._%-]+\.[a-zA-Z]{2,6}$/;
}

=xml
    <function name="send">
        <synopsis>
            Sends an email
        </synopsis>
        <note>
            If no path to sendmail is configured, the email will be printed in a
            &lt;litera&gt; xml node
        </note>
        <prototype>
            email::send(to => string, subject => string[, string header_name => string header_value ...], string content)
        </prototype>
        <example>
            email::send(to => 'ShaneCalimlim@gmail.com', subject => 'Hello!', 'You suck!');
        </example>
        <todo>
            Add alternatives to sendmail
        </todo>
    </function>
=cut

sub send {
    my $content = @_ % 2 == 1 ? pop : '' ;
    my %headers = @_;
    $headers{'from'} = $oyster::CONFIG{'sendmail_from'} unless grep /^from$/i, keys %headers;

    my @headers;
    for my $header (keys %headers) {
        my $name = string::proper_caps($header);
        my $value = $headers{$header};
        push @headers, join(': ', $name, $value);
    }
    my $headers = join($http::crlf, @headers) . "$http::crlf$http::crlf";

    # send the email
    if ($oyster::CONFIG{'sendmail'}) {
        open(my $sendmail, "|$oyster::CONFIG{sendmail} -oi -t") or throw 'perl_error' => 'An error occured while attempting to send an email.';
        print $sendmail $headers;
        print $sendmail $content . "$http::crlf$http::crlf";
    } else {
        print "<literal>";
        print "Sending email...\n";
        print $headers;
        print $content . "$http::crlf$http::crlf";
        print "</literal>\n";
    }
}

=xml
    <function name="send_template">
        <synopsis>
            Sends an email using a template from the database
        </synopsis>
        <note>
            Templates are stored in site_email_templates
        </note>
        <prototype>
            email::send_template(string template_name, string to, hashref variables)
        </prototype>
        <example>
            email::send_template('user_registration', 'ShaneCalimlim@gmail.com', {'username' => 'ShaneC'});
        </example>
    </function>
=cut

sub send_template {
    my ($template, $to, $vars) = @_;

    # grab the template
    my ($subject, $body) = $oyster::DB->query("SELECT subject, body FROM $oyster::CONFIG{db_prefix}email_templates WHERE name = ?", $template)->fetchrow_arrayref();

    # remove returns
    $body =~ s/\r//g;

    # interpolate variables
    $subject =~ s/{(\w+?)}/$vars->{$1}/g;
    $body    =~ s/{(\w+?)}/$vars->{$1}/g;

    # send email
    email::send('to' => $to, 'subject' => $subject, $body);
}

=xml
    <function name="add_template">
        <todo>
            Document this function
        </todo>
    </function>
=cut

sub add_template {
    $oyster::DB->query("INSERT INTO $oyster::CONFIG{db_prefix}email_templates (name, subject, body) VALUES (?, ?, ?)", @_);
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
