=xml
<document title="Generate Documentation">
    <synopsis>
        Executes all of the doc generation scripts in the proper order.
    </synopsis>
=cut
package oyster::script::generate_docs;

print "-- EXTRACTING DOC XML -------------------------------------\n";
print `perl script/extract_doc_xml.pl`;
print "-- GENERATING INDEX XML -----------------------------------\n";
print `perl script/generate_doc_index_xml.pl`;
print "-- GENERATING XHTML ---------------------------------------\n";
print `perl script/generate_doc_html.pl`;

=xml
</document>
=cut

1;

# Copyright BitPiston 2008