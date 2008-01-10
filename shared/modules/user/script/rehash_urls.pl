##############################################################################
# Rehashes user url hashes
# ----------------------------------------------------------------------------

# configuration
BEGIN {
    eval { require "./config.pl"; };
    die "Could not read ./config.pl, are you sure you are executing this script from the site directory?" if $@;
}

# load the oyster base class
use oyster;

# load oyster
eval { oyster::load($config, load_modules => 1, load_libs => 1) };
die("Startup Failed: An error occured while loading Oyster: $@") if $@;

print "Rehashing user names...\n";

# select all user ids and names
my $query = $oyster::DB->query("SELECT id, name FROM users");
while (my $user = $query->fetchrow_hashref()) {
    $oyster::DB->query("UPDATE user_profiles SET name_hash = ? WHERE id = ?", hash::fast(lc($user->{'name'})), $user->{'id'});
    $oyster::DB->query("UPDATE users SET name_hash = ? WHERE id = ?", hash::fast(lc($user->{'name'})), $user->{'id'});
}

print "Done.\n";

# ----------------------------------------------------------------------------
# Copyright
##############################################################################
1;