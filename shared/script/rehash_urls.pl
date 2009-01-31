##############################################################################
# Rehashes user url hashes
# ----------------------------------------------------------------------------

# configuration
BEGIN
{
    our $config = eval { require './config.pl' };
    die "Could not read ./config.pl, are you sure you are executing this script from your shared directory: $@" if $@;
}

# load the oyster base class
use oyster 'script';

# load oyster
eval { oyster::load( $config, load_modules => 0, load_libs => 1  ) };
die( "Startup Failed: An error occured while loading Oyster: $@") if $@;

print "Rehashing urls...\n";

my $query = $oyster::DB->query( "SELECT id, url FROM $oyster::CONFIG{'db_prefix'}urls" );
while( my $url = $query->fetchrow_hashref() )
{
    $oyster::DB->query( "UPDATE $oyster::CONFIG{'db_prefix'}urls SET url_hash = ? WHERE id = ? LIMIT 1", hash::fast( $url->{'url'} ), $url->{'id'} )
}
print "Done.\n";

# ----------------------------------------------------------------------------
# Copyright
##############################################################################
1;

__END__

# select all user ids and names
my $query = $oyster::DB->query("SELECT id, name FROM users");
while (my $user = $query->fetchrow_hashref()) {
    $oyster::DB->query("UPDATE user_profiles SET name_hash = ? WHERE id = ?", hash::fast(lc($user->{'name'})), $user->{'id'});
    $oyster::DB->query("UPDATE users SET name_hash = ? WHERE id = ?", hash::fast(lc($user->{'name'})), $user->{'id'});
}
