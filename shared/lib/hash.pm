=xml
<document title="Hashing Functions">
    <synopsis>
        Functions related to hashing data.
    </synopsis>
=cut

package hash;

=xml
    <function name="fast">
        <synopsis>
            Returns a hashed value of a string, and is hopefully pretty quick about it
        </synopsis>
        <note>
            Hashes are curently 9-10 characters long with this algorithm.
        </note>
        <note>
            This is used primarily to create fixed-length, database-indexable hashes
            for quick url lookups.
        </note>
        <note>
            This function automatically reverts to SHA1 (truncated to 10 characters)
            if JHash is not available, -HOWEVER- you should -NEVER- switch between
            using both.
            
            This can be problematic if your production enviroment has JHash and your
            development environment does not.  Eventually I will get around to
            writing a pure-perl JHash algorithm for use where C versions are not
            available.
            
            On nix you should have no trouble installing JHash via:
                perl -MCPAN -e "install Digest::JHash"
            For Windows using ActivePerl, see the extras directory for a .ppd.  To
            install it: cd to the directory containing the .ppd file and type:
                ppm install Digest-JHash.ppd
        </note>
        <prototype>
            string = hash::fast(string)
        </prototype>
        <todo>
            pad to 10 chars? -- Pg will need this is you use char(10)!
        </todo>
        <todo>
            pure-perl JHash
        </todo>
    </function>
=cut

sub fast {
	if ($oyster::CONFIG{'hash_method'} eq "sha") {
        return substr(Digest::SHA::sha1_hex($_[0]), 0, 10);
	} elsif ($oyster::CONFIG{'hash_method'} eq "jhash") {
		return Digest::JHash::jhash($_[0]);
	} else {
		eval { require Digest::JHash };
		if ($@) {
		    eval q~
		    	return substr(Digest::SHA::sha1_hex($_[0]), 0, 10);
		    ~;
		} else {
		    eval q~
		    	return Digest::JHash::jhash($_[0]);
		    ~;
		}
	}
}

=xml
    <function name="secure">
        <synopsis>
            Returns a hashed value of a string, and is hopefully pretty hard to crack
        </synopsis>
        <note>
            Hashes are curently 64 characters long with this algorithm.
        </note>
        <note>
            If the Digest::SHA module is not installed, a pure-perl version will be
            used instead.  It is pretty slow, but fine for most purposes, since
            hash_secure is not used often.
        </note>
        <note>
            If you are using the pure-perl SHA module, you should DEFINITELY have
            JHash installed, since hash::fast() is called quite often.
        </note>
        <prototype>
            string = hash::secure(string)
        </prototype>
    </function>
=cut

eval { require Digest::SHA };
require Digest::SHA::PurePerl if $@;

sub secure {
    return Digest::SHA::sha256_hex($_[0]);
}

# Copyright BitPiston 2008
1;
=xml
</document>
=cut