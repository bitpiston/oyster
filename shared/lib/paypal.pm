=xml
<document title="Paypal API">
    <synopsis>
        This library provides access to Paypal's NVP api.
    </synopsis>
    <todo>
        Paypal account details should be in a config
    </todo>
    <todo>
        Needs more documentation
    </todo>
=cut

package paypal;

use LWP::UserAgent;

use cgi;
use exceptions;

=xml
    <section title="Public Functions">
        <note>
            All functions take either a single argument or a hash of arguments (NOT
            a hashref).
        </note>
        <note>
            All functions return hashrefs containing the nvp response.
        </note>
=cut

=xml
        <function name="new">
            <todo>
                validate the arguments, possibly even perform a no-op connection to ensure the credentials are valid
                performing an actual request is a good idea because it can also ensure you support https
            </todo>
        </function>
=cut

sub new {
    my $class = shift;

    # validate arguments
    my %args = @_;

    # create and return the paypal object
    my $obj = bless {

        # Paypal NVP API
        'username'   => $args{'username'},
        'password'   => $args{'password'},
        'signature'  => $args{'signature'},
        'url'        => $args{'url'}        || 'https://api-3t.sandbox.paypal.com/nvp', # defaults to sandbox
        'version'    => '2.3',
        'webscr_url' => $args{'webscr_url'} || 'https://www.sandbox.paypal.com/cgi-bin/webscr',

        # Paypal PDT API
        'token'      => $args{'token'},

        # Create a user agent for this object to make requests on
        'ua'         => LWP::UserAgent->new(),
    }, $class;

    return $obj;
}

=xml
        <function name="pdt">
            <synopsis>
                Sends a Payment Data Transfer request to Paypal
            </synopsis>
            <note>
                For an explanation of the variables returned by this, see
                <link url="https://www.paypal.com/IntegrationCenter/ic_ipn-pdt-variable-reference.html">PayPal's variable reference</link>.
            </note>
            <note>
                This uses a different authentication scheme than the NVP-based API
                functions.
            </note>
            <note>
                PDT also returns data in a different format than NVP, so it must use a
                custom parser.
            </note>
            <prototype>
                hashref = obj->pdt(string transaction_id)
            </prototype>
        </function>
=cut

sub pdt {
    my $obj            = shift;
    my $transaction_id = shift;

    # prepare paramenters for the request
    my %request_params = (
        'cmd' => '_notify-synch',  # command to PDT
        'tx'  => $transaction_id, # transaction id to query
        'at'  => $obj->{'token'},  # PDT identity token
    );

    # make the request
    my $request = $obj->{'ua'}->post($obj->{'webscr_url'}, \%request_params);
    throw 'perl_error' => "Paypal communication failed: " . $request->status_line() unless $request->is_success(); # could include more details in the error but it's probably not a good idea to store this raw data in the error log (or to transmit it over http)

    # parse the returned data
    my @lines = split(/\n/, $request->content());
    my $status = shift @lines;
    throw 'perl_error' => "Paypal communication failed.  Invalid transaction ID: $transaction_id" if $status eq 'FAIL';
    my %payment_data;
    for my $line (@lines) {
        next unless my ($name, $value) = ($line =~ /^(.+?)=(.+)$/);
        $payment_data{$name} = cgi::uri_decode($value);
        $payment_data{$name} =~ tr/+/ /;
    }
    return \%payment_data;
}

=xml
        <function name="get_transaction_details">
            
        </function>
=cut

sub get_transaction_details {
    my $obj            = shift;
    my $transaction_id = shift;

    return $obj->_send_msg('GetTransactionDetails', {'transactionid' => $transaction_id});
}

=xml
        <function name="transaction_search">
        
        </function>
=cut

sub transaction_search {
    my $obj    = shift;
    my %params = @_;
    $params{'startdate'} = '1998-01-01T00:00:00Z' unless $params{'startdate'};

    return $obj->_send_msg('TransactionSearch', \%params);
}

=xml
        <function name="parsed_transaction_search">
            <synopsis>
                A wrapper for transaction_search() that parses the results and puts them
                into a more meaningful data structure.
            </synopsis>
        </function>
=cut

sub parsed_transaction_search {
    my $obj = shift;

    my @transactions;
    my $results = $obj->transaction_search(@_);
    for my $result (keys %{$results}) {
        next unless my ($name, $id) = ($result =~ /^l_(.+)(\d+)$/);
        $transactions[$id]->{$name} = $results->{$result};
    }

    return \@transactions;
}

=xml
        <function name="validate_ipn">
            <todo>
                Should this return true/false or throw an exception?
            </todo>
        </function>
=cut

sub validate_ipn {
    my $obj = shift;
    my $ipn = shift;

    $ipn->{'cmd'} = '_notify-validate';
    my $request = $obj->{'ua'}->post($obj->{'webscr_url'}, $ipn);
    throw 'perl_error' => "Paypal communication failed: " . $request->status_line() unless $request->is_success(); # could include more details in the error but it's probably not a good idea to store this raw data in the error log (or to transmit it over http)

    return $request->content() eq 'VERIFIED' ? 1 : 0 ;
}

=xml
    </section>
    
    <section title="Private Functions">

        <function name="_send_msg">
            <synopsis>
                This is the main work horse of this library, this sends an NVP message and
                returns the response.
            </synopsis>
            <prototype>
                 $obj->_send_msg(string method, hashref params)
            </prototype>
            <todo>
                This should have an optional third argument, arrayref params for
                functions that require duplicate parameters with the same name.
            </todo>
        </function>
=cut

sub _send_msg {
    my $obj    = shift;
    my $method = shift;
    my $params = shift;

    # add mandatory arguments
    $params->{'user'}      = $obj->{'username'};
    $params->{'pwd'}       = $obj->{'password'};
    $params->{'signature'} = $obj->{'signature'};
    $params->{'version'}   = $obj->{'version'};
    $params->{'method'}    = $method;

    # send the request
    my $request = $obj->{'ua'}->post($obj->{'url'}, $params);
    throw 'perl_error' => "Paypal communication failed: " . $request->status_line() unless $request->is_success(); # could include more details in the error but it's probably not a good idea to store this raw data in the error log (or to transmit it over http)

    # parse the nvp response
    my %response;
    my @pairs = split(/&/, $request->content());
    for my $pair (@pairs) {
        my ($name, $value) = split(/=/, $pair);
        $response{ lc $name } = cgi::uri_decode($value);
    }

    # error
    #if ($response{'ack'} eq 'Error' or $response{'ack'} eq 'Warning') {
    if ($response{'ack'} eq 'Failure' or $response{'ack'} eq 'Error' or $response{'ack'} eq 'Warning') {
        throw 'perl_error' => 'Paypal Error: ' . $response{'l_longmessage0'};
    }

    # success
    elsif ($response{'ack'} eq 'Success' or $response{'ack'} eq 'SuccessWithWarning') {
        return \%response;
    }

    # other?
    else {
        throw 'perl_error' => 'Malformed Paypal response.';
    }
}

=xml
    </section>
=cut

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
