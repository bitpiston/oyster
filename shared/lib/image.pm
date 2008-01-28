=xml
<document title="Image Functions">
    <synopsis>
        Inspect and manipulate images using ImageMagick.  This is basically a
        lightweight version of perlmagick that can potentially use other backends.
    </synopsis>
    <warning>
        This library is considered pre-alpha.  It needs to be updated to prevent shell injection and to use exceptions.
    </warning>
    <todo>
        Allow alternatives to ImageMagick
    </todo>
    <todo>
        shell_escape!
    </todo>
=cut

package image;

=xml
    <function name="identify">
        <synopsis>
            Inspect an image and return the type, width, and height.
        </synopsis>
        <note>
            Returns a undef if an error occured
        </note>
        <prototype>
            string type, int width, int height = image::identify(string image_filename)
        </prototype>
        <example>
            throw 'validation_error' => "File is not an image!" unless image::identify($INPUT{'some_upload'}->{'tmp_name'})
        </example>
    </function>
=cut
   
sub identify {
    my $image = shift;
    my $data = `$oyster::CONFIG{imagemagick}identify "$image"`;
    if ($data =~ /([A-Z]+) (\d+)x(\d+)/) {
        my ($type, $width, $height) = ($1, $2, $3);
        $type = 'jpg' if $type eq 'JPEG'; # TODO: necessary?
        return (lc $type, $width, $height);
    } else {
        return;
    }
}

=xml
    <function name="thumbnail">
        <synopsis>
            Create a thumbnail of an image
        </synopsis>
        <note>
            Returns undef on failure, 1 on success.
        </note>
        <prototype>
            image::thumbnail(string source_filename, string dest_filename, int width[, int height])
        </prototype>
    </function>
=cut

sub thumbnail {
    my ($source_file, $dest_file, $width, $height) = @_;

    # prepare dimensions
    my $dimensions = $width;
    $dimensions .= "x$height" if $height;

    # perform the thumbnailing
    my $out = `$oyster::CONFIG{imagemagick}convert $source_file -resize $dimensions $dest_file`;

    return length $out == 0 ? 1 : undef ;
}

=xml
    <function name="watermark">
        <synopsis>
            Overlays one image on top of another
        </synopsis>
        <note>
            If no destination filename is provided, the second argument is
            overwritten.
        </note>
        <note>
            The valid alignments are: topleft, topright, center, bottomleft, and
            bottomright.
        </note>
        <note>
            If no alignment is specified, bottomright is selected.
        </note>
        <prototype>
            image::thumbnail(string overlay_image, string background_image[, string alignment][, string destination_filename])
        </prototype>
        <todo>
            Add a proper return value for success/failure
        </todo>
    </function>
=cut

sub watermark {
    my ($overlay, $bg, $align, $dest) = @_;
    my %alignments = (
        'topleft'     => 'NorthWest',
        'topright'    => 'NorthEast',
        'center'      => 'Center',
        'bottomleft'  => 'SouthWest',
        'bottomright' => 'SouthEast',
    );
    $dest = $bg unless defined $dest;
    $align = $alignments{$align} ? $alignments{$align} : $alignments{'bottomright'} ;
    `$oyster::CONFIG{imagemagick}composite -gravity $align "$overlay" "$bg" "$dest"`;
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
