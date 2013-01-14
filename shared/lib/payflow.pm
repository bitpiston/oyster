=xml
<document title="Payflow Pro API">
    <warning>
        This library is considered beta at best.
    </warning>
    <synopsis>
        This library provides access to Paypal's PayFlow Pro XMLPay API.
    </synopsis>
    <todo>
        Error handling for XMLPay responses.
    </todo>
=cut

package payflow;

use soap;
use exceptions;

=xml
    <section title="Public Functions">
        <note>
            All functions take two hashrefs. One for your API configuration details and another with the transaction data to pass to the API. See the PayPal PayFlow Pro XMLPay API documentation for the details:
            https://cms.paypal.com/cms_content/US/en_US/files/developer/PP_PayflowPro_XMLPay_Guide.pdf
        </note>
        <note>
            All functions return hashrefs containing the XMLPay TransactionResult from the response.
        </note>
=cut

=xml
        <function name="sale_credit">
            <synopsis>
                Sends a credit card sale request to PayPal and returns the response.
            </synopsis>
            <prototype>
                hashref = sale_credit(hashref config, hashref data)
            </prototype>
        </function>
=cut

sub sale_credit {
    my ($config, $data) = @_;
        
    # Ordered hash of PayPal data to turn into XML
=xml                
                    'BillTo' => [ 0, {
                        'Address' => [ 0, {
                            'Street'  => [ 0, $data->{'street'} ],
                            'City'    => [ 1, $data->{'city'} ],
                            'State'   => [ 2, $data->{'state'} ],
                            'Zip'     => [ 3, $data->{'zip'} ],
                            'Country' => [ 4, $data->{'country'} ],
                        } ],
                    } ],
=cut  
    my %content = (
        'PayData' => [ 0, { 
            'Invoice' => [ 0, {
          
                'NationalTaxIncl' => [ 1, $data->{'tax'} ],
                'TotalAmt'        => [ 2, $data->{'cost'} ],
            } ],
            'Tender'   => [ 1, {
                'Card'     => [ 0, {
                    'CardType'    => [ 0, 'C' ],
                    'CardNum'     => [ 1, $data->{'card_number'} ],
                    'ExpDate'     => [ 2, $data->{'card_expiry'} ],
                    'NameOnCard'  => [ 3, $data->{'card_holder'} ],
                    'CVNum'       => [ 4, $data->{'cvv'} ],
                } ],
            } ],
        } ],
    );

    # Contruct the request from the content hash
    my $sale = _transaction($config, 'Sale', \%content);
    
    return $sale;
}

=xml
        <function name="auth">
            <synopsis>
                Sends a credit card authorization request to PayPal and returns the response.
            </synopsis>
            <prototype>
                hashref = auth_credit(hashref config, hashref data)
            </prototype>
        </function>
=cut

sub authorization_credit {
    my ($config, $data) = @_;
        
    # Ordered hash of PayPal data to turn into XML
    my %content = (
        'PayData' => [ 0, { 
            'Invoice' => [ 0, {       
                'NationalTaxIncl' => [ 1, $data->{'tax'} ],
                'TotalAmt'        => [ 2, $data->{'cost'} ],
            } ],
            'Tender'   => [ 1, {
                'Card'     => [ 0, {
                    'CardType'    => [ 0, 'C' ],
                    'CardNum'     => [ 1, $data->{'card_number'} ],
                    'ExpDate'     => [ 2, $data->{'card_expiry'} ],
                    'NameOnCard'  => [ 3, $data->{'card_holder'} ],
                    'CVNum'       => [ 4, $data->{'cvv'} ],
                } ],
            } ],
        } ],
    );

    # Contruct the request from the content hash
    my $authorization = _transaction($config, 'Authorization', \%content);
    
    return $authorization;
}

=xml
        <function name="capture_credit">
            
        </function>
=cut

sub get_status_credit {
    
}

=xml
        <function name="capture_credit">
            
        </function>
=cut

sub force_capture_credit {
    
}

=xml
        <function name="credit">
            
        </function>
=cut

sub credit {
    
}

=xml
        <function name="capture_credit">
            
        </function>
=cut

sub capture_credit {
    
}

=xml
        <function name="void_credit">
            
        </function>
=cut

sub void_credit {
    
}

=xml
    </section>
    
    <section title="Private Functions">

        <function name="_transaction">
            <synopsis>
                This is the main work horse of this library, this constructs, sends an XMLPay message and
                returns the response.
            </synopsis>
            <prototype>
                 _transaction(hashref config, string name, hashref content)
            </prototype>
            <todo>
                Connection error handling - this needs to account for SSL or HTTP failures and retry several times with a delay. Look at Payflowpro.pm on CPAN for an example of what they do.
            </todo>
        </function>
=cut

sub _transaction {
    my ($config, $name, $content) = @_;
    my ($response, $success);
    my $max_retries = 3;
    my $retries     = $max_retries;
    
    # PayPal XMLPay header and footer
    my %request;
    $request{'xml_header'} .= '<?xml version="1.0" encoding="UTF-8"?>' . "\n" . 
        '<XMLPayRequest Timeout="30" version="2.0" xmlns="http://www.paypal.com/XMLPay">' . "\n" .  
        "\t<RequestData>\n" . 
        "\t\t<Vendor>" . $config->{'vendor'} . "</Vendor>\n" . 
        "\t\t<Partner>" . $config->{'partner'} . "</Partner>\n" .
        "\t\t<Transactions>\n" .
        "\t\t\t<Transaction>\n";
    $request{'xml_body'} .= soap::print_vars($name, $content, 4);
    $request{'xml_footer'} .= "\t\t\t</Transaction>\n" . 
        "\t\t</Transactions>\n" .
        "\t</RequestData>\n" . 
        "\t<RequestAuth>\n" .
        "\t\t<UserPass>\n" . 
        "\t\t\t<User>" . $config->{'user'} . "</User>\n" . 
        "\t\t\t<Password>" . $config->{'pwd'} . "</Password>\n" .
        "\t\t</UserPass>\n" .
        "\t</RequestAuth>\n" .
        "</XMLPayRequest>";
    
    # Request ID for transaction
    # TODO: use date::gmtime
    # TODO: this should be changed since I don't think we pass these in
    my $request_id = substr(time . $content->{TrxType} . ($content->{InvNum} || $content->{OrigID} || 'NOID'),0,32);
    
    # IO::Socket::SSL settings
    $request{'url'} = $config->{'url'};
    $request{'ssl'} = {
        SSL_version => 'SSLv3',
        SSL_verify_mode => '0x00',
    };
    
    # HTTP headers for PayPal XMLPay API
    $request{'headers'} = [
        'X-VPS-CLIENT-TIMEOUT: 45',
        'X-VPS-REQUEST-ID: ' . $request_id,
    ];
    
    # Send the SOAP post to PayPal's server and return the response
    do {
        log::debug("Payflow: Attempting transaction, retries remaining: " . $retries);
        
        sleep(46) unless ($max_retries - $retries) == 0; # do not delay unless there has been a failure
        
        $success = try {
            $response = soap::request(\%request);
            throw 'payflow_error' => 'SOAP request to PayPal Payflow Pro failed for transaction ' . $request_id unless $response;
        }
        catch 'payflow_error', with {
            my $error = shift;
            
            log::error("Payflow Error: " . $error);
            abort(1);
        };
    } while (!$success and --$retries);
    
    if ($success) {
        return $response->{'XMLPayResponse'}->{'ResponseData'}->{'TransactionResults'}->{'TransactionResult'};
    }
    else {
        log::error("Payflow Error: Maximum retries reached, giving up on transaction " . $request_id);
        throw 'validation_error' => 'Unable to process your transaction. Please try again later.';
        return;
    }
}

=xml
    </section>
=cut

# Copyright BitPiston 2012
1;
=xml
</document>
=cut
