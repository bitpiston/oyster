=xml
<document title="File Functions">
    <synopsis>
        Functions associated with file manipulation.  This is a lightweight
        implementation of several File::* CPAN modules.
    </synopsis>
    <todo>
        Size and mtime should throw exceptions if the file does not exist.
    </todo>
=cut

package file;

use exceptions;

=xml
    <function name="tmp_name">
        <synopsis>
            Generates a name for a temporary file, returns the path to that file
        </synopsis>
        <prototype>
            string file_path = file::tmp_name()
        </prototype>
    </function>
=cut

sub tmp_name { $oyster::CONFIG{'tmp_path'} . string::random() . '.tmp' }

=xml
    <function name="tmp_web_name">
        <warning>
            Unimplemented
        </warning>
        <synopsis>
            Generates a name for a temporary file in a web accessible directory,
            returns both the path and url to that file
        </synopsis>
        <note>
            A single argument is optional, if specified, it will be used as the file
            extension.
        </note>
        <prototype>
            string file_path, string file_url = file::tmp_web_name([string extension])
        </prototype>
    </function>
=cut

#sub tmp_web_name {
#    my $ext = shift || 'tmp';
#    my $filename = string::random() . '.' . $ext;
#    return ("$oyster::CONFIG{site_file_path}tmp/" . $filename, "$oyster::CONFIG{site_file_url}tmp/" . $filename);
#}

=xml
    <function name="rename">
        <synopsis>
            Move or rename a file
        </synopsis>
        <note>
            throws a 'perl_error' exception on failure
        </note>
        <prototype>
            file::rename(string from_filename, string to_filename)
        </prototype>
        <example>
            file::rename("foo.txt", "bar.txt");
        </example>
    </function>
    
    <function name="move">
        <note>
            file::move is an alias for <link target="rename">file::rename</link>
        </note>
    </function>
=cut

sub move { goto &rename }
sub rename {
    my ($from, $to) = @_;
    return if $from eq $to;
    my $ret = oyster::execute_script('~nosite', 'file_move', $from, $to);
    chomp($ret);
    throw 'perl_error' => $ret unless $ret == 1;
}

=xml
    <function name="copy">
        <synopsis>
            Copy a file or a directory
        </synopsis>
        <note>
            throws a 'perl_error' exception on failure
        </note>
        <prototype>
            file::copy(string from_filename, string to_filename)
        </prototype>
        <example>
            file::copy("foo.txt", "bar.txt");
        </example>
    </function>
=cut

sub copy {
    my ($from, $to) = @_;
    return if $from eq $to;
    my $ret = oyster::execute_script('~nosite', 'file_move', $from, $to);
    chomp($ret);
    throw 'perl_error' => $ret unless $ret == 1;
}

=xml
    <function name="size">
        <synopsis>
            Returns a file's size, in kilobytes
        </synopsis>
        <prototype>
            int fsize = file::size(string filename)
        </prototype>
    </function>
=cut

sub size { ((stat(shift()))[7] / 1024) }

=xml
    <function name="slurp">
        <synopsis>
            Quick and dirty file reading
        </synopsis>
        <note>
            Throws a perl_error exception on failure
        </note>
        <prototype>
            string file_contents = file::slurp(string filename)
        </prototype>
        <example>
            
        </example>
        <todo>
            
        </todo>
    </function>
    
    <function name="read">
        <note>
            file::read is an alias for <link target="slurp">file::slurp</link>
        </note>
    </function>
=cut

sub read { goto &slurp }
sub slurp {
    my $file = shift;
    open(my $fh, $file) or throw 'perl_error' => "Error reading file '$file':\n$!";
    local $/;
    return <$fh>;
}

=xml
    <function name="write">
        <synopsis>
            Quick and dirty file writing
        </synopsis>
        <note>
            The third optional argument, if true, will attempt to create any directories necessary to create to the file.
        </note>
        <note>
            Throws a perl_error exception on failure
        </note>
        <prototype>
            file::write(string filename, string file_contents[, bool autocreate_directories])
        </prototype>
        <todo>
        	replace single last argument with optional flags for dir_autocreate, append, utf8, bin
        </todo>
    </function>
=cut

sub write {
    my ($file, $file_contents, $autocreate_dirs) = @_;
    if ($autocreate_dirs) {
        my ($path) = ($file =~ m!^(.+)/.+?$!o);
        file::mkdir($path);
    }
    open(my $fh, '>', $file) or throw 'perl_error' => "Error writing file '$file':\n$!";
    print $fh $file_contents;
}

=xml
    <function name="rmdir">
        <synopsis>
            Recursively deletes a directory and everything inside it.
        </synopsis>
        <note>
            Throws a perl_error exception on failure
        </note>
        <prototype>
            file::rmdir(string path)
        </prototype>
    </function>
=cut

sub rmdir {
    my $path = shift;
    $path .= '/' unless $path =~ m!/$!;
    opendir(my $dh, $path) or throw 'perl_error' => "Error reading directory '$path':\n$!";
    while (defined(my $file = readdir($dh))) {
        next if ($file eq '.' or $file eq '..');
        my $file_path = "$path$file";
        if (-d $file_path) {
            file::rmdir($file_path);
        } elsif (-f $file_path) {
            unlink($file_path)  or throw 'perl_error' => "Error deleting file '$file_path':\n$!";
        }
    }
    rmdir($path) or throw 'perl_error' => "Error deleting directory '$path':\n$!";
}

=xml
    <function name="mkdir">
        <synopsis>
            Recursively creates a directory and all directories leading up to it (if necessary)
        </synopsis>
        <prototype>
            file::mkdir(string path)
        </prototype>
    </function>
=cut

sub mkdir {
    my $path = shift;
    return if -d $path; # short circuit if it already exists
    $path =~ s!/$!!; # trim trailing slash
    my @dirs = split /\//, $path;
    my $create_path;
    for my $dir (@dirs) {
        $create_path .= "$dir/";
        next if $dir eq '.' or $dir eq '..';
        unless (-d $create_path) {
            mkdir($create_path) or throw 'perl_error' => "Error creating directory '$create_path':\n$!";
        }
    }
}

=xml
    <function name="mtime">
        <synopsis>
            Returns a file's last-modified time
        </synopsis>
        <note>
            
        </note>
        <prototype>
            
        </prototype>
        <example>
            
        </example>
        <todo>
            this should be adjusted to gmt
        </todo>
    </function>
=cut

sub mtime { (stat(shift()))[9] }

# Copyright BitPiston 2008
1;
=xml
</document>
=cut
