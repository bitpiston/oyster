=xml
<document title="User Module">
    <synopsis>
        This module encapsulates the current user's data/permissions and all user-related actions.
    </synopsis>
=cut

package user;

# import libraries
use oyster 'module';
use exceptions;

my $geoip;

our (%USER, %PERMISSIONS, %groups);

=xml
    <section title="Initialization">

        <function name="hook_load">
            <synopsis>
                Loads user group data and prepares queries to be used later.
            </synopsis>
            <note>
                This uses event::register_hook() to execute at the right times.
            </note>
        </function>
=cut

event::register_hook('load', 'hook_load', 90);
sub hook_load {

    # cache queries
    our $select_group_by_id             = $DB->prepare("SELECT * FROM ${module_db_prefix}groups WHERE id = ? LIMIT 1"); 
    #our $select_user_by_session         = $DB->prepare("SELECT ${module_db_prefix}sessions.user_id, ${module_db_prefix}sessions.ip, ${module_db_prefix}sessions.restrict_ip, users.name, users.time_offset, users.date_format, users.style, ${module_db_prefix}permissions.group_id FROM ${module_db_prefix}sessions, users, ${module_db_prefix}permissions WHERE ${module_db_prefix}sessions.session_id = ? and users.id = ${module_db_prefix}sessions.user_id and ${module_db_prefix}permissions.user_id = ${module_db_prefix}sessions.user_id LIMIT 1");
    our $select_user_by_id              = $DB->prepare("SELECT users.name, users.time_offset, users.date_format, users.style, ${module_db_prefix}permissions.group_id FROM users, ${module_db_prefix}permissions WHERE users.id = ? and ${module_db_prefix}permissions.user_id = users.id LIMIT 1");
    our $select_user_id_by_session      = $DB->prepare("SELECT user_id, ip, restrict_ip, geoip_country, geoip_region, geoip_city FROM ${module_db_prefix}sessions WHERE session_id = ? LIMIT 1");
    our $select_user_id_by_credentials  = $DB->prepare("SELECT id FROM users WHERE name_hash = ? and password = ? LIMIT 1");
    #our $update_user_session            = $DB->prepare("UPDATE ${module_db_prefix}sessions SET session_id = ?, ip = ?, restrict_ip = ?, access_ctime = ? WHERE user_id = ? LIMIT 1");
    our $update_user_session            = $DB->prepare("UPDATE ${module_db_prefix}sessions SET ip = ?, restrict_ip = ?, access_ctime = ? WHERE session_id = ? LIMIT 1");
    #our $update_user_session            = $DB->prepare("UPDATE ${module_db_prefix}sessions SET access_ctime = ? WHERE session_id = ? LIMIT 1");
    our $insert_user_session            = $DB->prepare("INSERT INTO ${module_db_prefix}sessions (user_id, session_id, ip, restrict_ip, access_ctime, geoip_country, geoip_region, geoip_city) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    our $select_permissions_count       = $DB->prepare("SELECT COUNT(*) FROM ${module_db_prefix}permissions WHERE ${module_db_prefix}permissions.user_id = ? LIMIT 1");

    # load user groups
    _load_groups();
    
    # every 15 minutes clean up expired sessions 
    ipc::do_periodic(900, 'user', '_clean_sessions');
    
    # import geolocation library
    if ($config{'enable_geoip'}) {
        try {
            require Geo::IP;
        }
        catch 'perl_error', with {
            $config{'enable_geoip'} = 0;
            log::status('User geolocation is ignored. Required library is not available.');
        };
    }

    # create the geoip object and open geoip database
    if ($config{'enable_geoip'}) {
        #log::debug('creating geoip object');
        try {
            #log::debug('starting try');
            $geoip = Geo::IP->open($CONFIG{'geoip_db'}, GEOIP_STANDARD); # unable to catch die() from Geo::IP
            #log::debug('end of try');
        }
        catch 'perl_error', with {
            #log::debug('starting catch perl_error, with');
            $config{'enable_geoip'} = 0;
            #log::status('User geolocation is ignored. Unable to open the geolocation database.');
            #log::debug('end of catch perl_error, with');
        };
    }
}

=xml
        <function name="import">
            <synopsis>
                Called by other modules to export %USER and %PERMISSIONS
            </synopsis>
        </function>
=cut

sub import {
    my $pkg = caller();

    *{"${pkg}::USER"}        = *USER;
    *{"${pkg}::PERMISSIONS"} = *PERMISSIONS;
}

=xml
    </section>

    <section title="Actions">

        <function name="recover">
            <synopsis>
                Recovers a lost account by sending an email to a user that allows them to reset their password.
            </synopsis>
            <note>
                This is registered to the url 'user/recover'.
            </note>
        </function>
=cut

sub recover {

    # if they passed a confirmation code
    if (length $INPUT{'confirm'} == 32) {
        my $confirmation_hash = $INPUT{'confirm'};

        # validate confirmation hash
        throw 'validation_error' => 'Invalid confirmation code provided.' unless $confirmation_hash =~ /^[a-zA-Z0-9]{32}$/;
        my $query = $DB->query("SELECT user_id, new_pass FROM user_recover WHERE confirmation_hash = ?", $confirmation_hash);
        throw 'validation_error' => 'No recovery was found matching the provided confirmation code.  Are you sure you haven\'t already confirmed this?' unless $query->rows();
        my $update = $query->fetchrow_hashref();

        # update the user's password
        $DB->query("UPDATE users SET password = ? WHERE id = ?", $update->{'new_pass'}, $update->{'user_id'});

        # delete their entry from the user recover database
        $DB->query("DELETE FROM user_recover WHERE user_id = ?", $update->{'user_id'});

        # confirmation
        confirmation('Your password has been updated.');
        return;
    }

    # if the form has been submitted
    my $success = try {

        # did the user input anything?
        throw 'validation_error' => 'A user name, id, or email address is required.' unless length $INPUT{'find'};

        # prepare the query to find their account
        my $where_field;
        if ($INPUT{'user'} =~ /^\d+$/) {         # if they are inputting a user id
            $where_field = 'id';
        }
        elsif (email::is_valid_email($INPUT{'user'})) { # if they are inputting an email address
            $where_field = 'email';
        } else {                                 # it must be a username
            $where_field = 'name';
        }
        my $find_query = $DB->query("SELECT id, name, email FROM users WHERE $where_field = ? LIMIT 1");

        # validate user input and find user
        throw 'validation_error' => 'No users were found matching that criteria.' unless $find_query->rows() == 1;
        my $found_user = $find_query->fetchrow_hashref();

        # make sure one of these hasn't been sent out in the last hour
        my $spam_query = $DB->query('SELECT COUNT(*) FROM user_recover WHERE user_id = ? and ctime > UTC_TIMESTAMP() - INTERVAL 1 HOUR LIMIT 1', $found_user->{'id'}); # TODO: test on Pg!
        throw 'validation_error' => 'An account recovery email has already been sent to this account within the last hour.  If you just attempted this, wait a few minutes for the email to arrive.  If you still have not received it in one hour, try again.' if $spam_query->fetchrow_arrayref()->[0];

        # generate a new password and confirmation hash
        my $new_pass          = string::random(8);
        my $confirmation_hash = string::random(32);

        # insert an entry into the user_recover table
        $DB->query('INSERT INTO user_recover (user_id, new_pass, confirmation_hash, ctime) VALUES (?, ?, ?, UTC_TIMESTAMP())', $found_user->{'id'}, $new_pass, $confirmation_hash);

        # send confirmation email
        email::send_template(
            'user_recover_account',
            $found_user->{'email'},
            {
                'site_name'   => $CONFIG{'site_name'},
                'username'    => $found_user->{'name'},
                'new_pass'    => $new_pass,
                'confirm_url' => "$CONFIG{full_url}user/recover/?confirm=$confirmation_hash",
            }
        );

        # print a confirmation
        confirmation('You have been sent an email containing instructions to reset your password.  It may take a few minutes to arrive.');
    } if $ENV{'REQUEST_METHOD'} eq 'POST';

    # print the account recovery form
    unless ($success) {
        style::include_template('recover');
        print "\t<user action=\"recover\" find=\"" . xml::entities($INPUT{'find'}) . "\" />\n";
    }
}

=xml
        <function name="edit_account">
            <synopsis>
                Edits a user's settings and profile
            </synopsis>
            <note>
                This is registered to the url 'user/account'.
            </note>
        </function>
=cut

sub edit_account {
    throw 'permission_error' if $USER{'id'} == 0;

    # select the id of the user to edit
    my $user_id = (exists $INPUT{'id'} and $PERMISSIONS{'user_admin_manage'}) ? $INPUT{'id'} : $USER{'id'} ;

    # the input source for the edit form
    my $input_source;

    # fetch current settings
    my $edit_user = $DB->query('SELECT * FROM users WHERE id = ? LIMIT 1', $user_id)->fetchrow_hashref();
    
    my $profile_meta;
    my $edit_profile;
    if ($config{'enable_profile'} == 1) {
        
        # fetch profile metadata
        my $query = $DB->query("SELECT * FROM user_profile_meta ORDER BY parent, name ASC");

        # prepare profile metadata
        while ( my $field = $query->fetchrow_hashref() ) {
            #push @{$profile_meta{ $field->{'parent'} }}, $field;
            $profile_meta{ $field->{'name'} } = $field;
        }

        # fetch user's profile data 
        $edit_profile = $DB->query("SELECT * FROM user_profiles WHERE user_id = ? LIMIT 1", $user_id)->fetchrow_hashref();
        
        # unserialize bbcode/xhtml fields
        for my $field (keys %{$edit_profile}) {
            if ($profile_meta{ $field }{'bbcode'} == 1) {
                my @unserialized = split /(?!\\),/, $edit_profile->{ $field };
                @unserialized[0] =~ s/\\,/,/o;
                $edit_profile->{ $field } = @unserialized[0];
            }
        }
    }
    
    # if the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {
        $input_source = \%INPUT;

        # validate input (in the order it was submitted)
        my %update;
        my $success = try {

            # if an admin is changing their user group
            if ($PERMISSIONS{'user_admin_manage'}) {
                my $query = $DB->query("SELECT group_id FROM ${module_db_prefix}permissions WHERE user_id = ? LIMIT 1", $edit_user->{'id'});
                my $group_id = $query->rows() ? $query->fetchrow_arrayref()->[0] : $config{'default_group'} ;
                if ($INPUT{'group_id'} != $group_id) {
                    throw 'validation_error' => 'Invalid group ID.' unless $groups{$INPUT{'group_id'}};
                    $update{'group_id'} = $INPUT{'group_id'};
                }
            }

            # if the user is trying to change his password
            if (length $INPUT{'password'}) {
                throw 'validation_error' => "Passwords must be at least $config{pass_min_length} characters long." if length $INPUT{'password'} < $config{'pass_min_length'};
                throw 'validation_error' => "Password and confirm password did not match."                         if $INPUT{'password'} ne $INPUT{'password2'};
                $update{'password'} = hash::secure($INPUT{'password'});
            }

            # if the user is trying to change his email, validate it
            if ($INPUT{'email'} ne $edit_user->{'email'}) {
                _validate_email($edit_user->{'id'});

                # make sure one of these hasn't been sent out in the last hour
                unless ($PERMISSIONS{'user_admin_manage'}) {
                    my $spam_query = $DB->query('SELECT COUNT(*) FROM user_email_changes WHERE new_email = ? and ctime > UTC_TIMESTAMP() - INTERVAL 1 HOUR LIMIT 1', $INPUT{'email'});
                    throw 'validation_error' => 'A change email request has already been sent to this email address within the last hour.  If you just attempted this, wait a few minutes for the email to arrive.  If you still have not received it in one hour, try again.' if $spam_query->fetchrow_arrayref()->[0];
                }

                $update{'email'} = $INPUT{'email'};
            }

            # if they are trying to change their date format
            if ($INPUT{'date_format'} ne $edit_user->{'date_format'}) {
                throw 'validation_error' => 'Invalid date format.' unless datetime::is_valid_format($INPUT{'date_format'});    
                $update{'date_format'} = $INPUT{'date_format'} eq $datetime::formats[0] ? '' : $INPUT{'date_format'} ;
            }

            # if they are trying to change their time offset
            if ($INPUT{'time_offset'} != $edit_user->{'time_offset'}) {
                throw 'validation_error' => 'Invalid time offset.' unless datetime::is_valid_time_offset($INPUT{'time_offset'});
                $update{'time_offset'} = $INPUT{'time_offset'};
            }

            # if they are trying to (and can) change their style
            if ($INPUT{'style'} eq $edit_user->{'style'}) { # leave the style as-is
            } elsif (length $INPUT{'style'} == 0) { # the user wants the default style
                $update{'style'} = '';
            } else {                                # the user wants to specify a style
                throw 'validation_error' => 'Invalid style ID.' unless style::is_enabled($INPUT{'style'});
                $update{'style'} = $INPUT{'style'};
            }
        };

        # validation was successful
        if ($success) {

            # if they are trying to update their email, set up a confirmation thing
            if ($update{'email'} and !$PERMISSIONS{'user_admin_manage'}) {
                my $confirmation_hash = string::random(32);

                # add the change to the pending-verification database
                my $query = $DB->query('INSERT INTO user_email_changes SET (user_id, new_email, confirmation_hash, ctime) VALUES (?, ?, ?, UTC_TIMESTAMP())', $edit_user->{'id'}, $update{'email'}, $confirmation_hash);

                # send confirmation email
                email::send_template(
                    'user_change_email',
                    $update{'email'},
                    {
                        'site_name'   => $CONFIG{'site_name'},
                        'username'    => $edit_user->{'name'},
                        'new_email'   => $update{'email'},
                        'confirm_url' => "$CONFIG{full_url}user/confirm_email/?confirm=$confirmation_hash",
                    }
                );

                # delete email from the update hash so it's not updated yet, it requires email verification first
                delete $update{'email'};
            }

            # if their user group needs updating
            if (exists $update{'group_id'}) {

                # update their group id
                my $query = $DB->query("UPDATE ${module_db_prefix}permissions SET group_id = ? WHERE user_id = ?", $INPUT{'group_id'}, $edit_user->{'id'});

                # the update failed, they have no group entry, creating one for them
                $DB->query("INSERT INTO ${module_db_prefix}permissions (user_id, group_id) VALUES (? , ?)", $edit_user->{'id'}, $INPUT{'group_id'}) unless $query->rows();

                # delete this from the update hash, it isn't even in the users table
                delete $update{'group_id'};
            }

            # perform the update
            $DB->query('UPDATE users SET ' . join(', ', map { "$_ = ?" } keys %update) . ' WHERE id = ?', values %update, $edit_user->{'id'}) if %update;

            # confirmation message
            if ($edit_user->{'id'} != $USER{'id'}) {
                confirmation("The selected user's settings have been saved.",
                    'Find another user.'        => "${BASE_URL}admin/user/find/",
                    "Edit this user's profile." => "${BASE_URL}user/profile/?id=$edit_user->{id}",
                );
            } else {
                confirmation('Your settings have been saved.');
            }
        }
        $input_source->{'name'} = $edit_user->{'name'};
    } else {
        $input_source                  = $edit_profile;
        $input_source->{$_}            = $edit_user->{$_} for keys %{$edit_user};
        $input_source->{'name'}        = $edit_user->{'name'};
        $input_source->{'date_format'} = $datetime::formats[0] unless length $edit_user->{'date_format'};
        if ($PERMISSIONS{'user_admin_manage'}) {
            my $query = $DB->query("SELECT group_id FROM ${module_db_prefix}permissions WHERE user_id = ? LIMIT 1", $edit_user->{'id'});
            my $group_id = $query->rows() ? $query->fetchrow_arrayref()->[0] : $config{'default_group'};
            $input_source->{'group_id'} = $group_id;
        }
    }

    # print the edit settings form
    style::include_template('edit_account');
    my $attrs;
    $attrs .= qq~ customizable_styles="1" style="$input_source->{style}"~ if $config{'customizable_styles'};
    $attrs .= qq~ id="$input_source->{id}" name="$input_source->{name}"~  if $user_id != $USER{'id'};
    $attrs .= qq~ group_id="$input_source->{group_id}"~                   if $PERMISSIONS{'user_admin_manage'};
    $attrs .=' email="' . xml::entities($input_source->{'email'}) . '"';
    $attrs .=' time_offset="' . xml::entities($input_source->{'time_offset'}) . '"';
    $attrs .=' date_format="' . xml::entities($input_source->{'date_format'}) . '"';
    print qq~\t<user action="edit_account"$attrs>\n~;
        print "\t\t<settings>\n";
            _print_groups() if $PERMISSIONS{'user_admin_manage'};
            datetime::print_date_formats_xml();
            style::print_enabled_styles_xml() if $config{'customizable_styles'};
        print "\t\t</settings>\n";
        
        if ($config{'enable_profile'} == 1) {
            print "\t\t<profile>\n";
            
            # sort profile meta data by group
            my %profile_groups;
            for my $field (%profile_meta) {
                next if length $field->{'name'} == 0;
                push @{ $profile_groups->{ $field->{'parent'} } }, $field->{'name'};
            }
            
            # print fields by group
            for my $group ( sort keys %{$profile_groups} ) {
                print qq~\t\t\t<group name="$group">\n~;
                
                for my $field ( sort @{$profile_groups->{$group}} ) {
                    my $attributes = qq~ name="$field" type="$profile_meta{ $field }{'input_type'}"~;
                    $attributes   .= qq~ note="$profile_meta{ $field }{'note'}"~ unless length $profile_meta{ $field }{'note'} == 0;
                    if ($profile_meta{ $field }{'input_type'} eq 'select') {
                        my $default;
                        $default     = qq~ default="$profile_meta{ $field }{'default_value'}"~ unless length $profile_meta{ $field }{'default_value'} == 0;
                        $default     = qq~ default="$input_source->{ $field }"~ unless length $input_source->{ $field } == 0;            
                        $attributes .= $default;
                        print qq~\t\t\t\t<field$attributes>\n~;
                        
                        for my $value ( split /,/, $profile_meta{ $field }{'values'} ) {
                            print qq~\t\t\t\t\t<value>$value</value>\n~;
                        }
                        print "\t\t\t\t</field>\n";
                    }
                    elsif ($profile_meta{ $field }{'input_type'} eq 'textarea') {
                        print qq~\t\t\t\t<field$attributes>\n~;
                        print $input_source->{ $field };
                        print "\t\t\t\t</field>\n";
                    }
                    else {
                        $attributes .= qq~ default="$profile_meta{ $field }{'default_value'}"~ unless length $profile_meta{ $field }{'default_value'} == 0;
                        print qq~\t\t\t\t<field$attributes value="$input_source->{ $field }" />\n~;
                    }
                }
                print "\t\t\t</group>\n";
            }
            print "\t\t</profile>\n";
        }
    print "\t</user>\n";
}

=xml
        <function name="confirm_email">
            <synopsis>
                Confirms an email address update
            </synopsis>
            <note>
                This is registered to the url 'user/confirm_email'.
            </note>
        </function>
=cut

sub confirm_email {
    my $confirmation_hash = $INPUT{'confirm'};

    # validate the confirmation hash
    throw 'validation_error' => 'Invalid confirmation code provided.' unless $confirmation_hash =~ /^[a-zA-Z0-9]{32}$/;

    # validate email verification
    my $query = $DB->query('SELECT user_id, new_email FROM user_email_changes WHERE confirmation_hash = ? LIMIT 1', $confirmation_hash);
    throw 'validation_error' => 'No pending email changes matched the provided confirmation code.  Are you sure you haven\'t already confirmed this email address?' unless $query->rows() == 1;
    my ($user_id, $new_email) = @{$query->fetchrow_arrayref()};

    # update the user's email
    $DB->query('UPDATE users SET email = ?, email_hash = ? WHERE id = ?', $new_email, hash::fast($new_email), $user_id);

    # delete the email change from the database
    $DB->query('DELETE FROM user_email_changes WHERE user_id = ?', $user_id);

    # confirmation message
    confirmation('Your email address has been updated.');
}

=xml
        <function name="confirm_account">
            <synopsis>
                Confirms a newly registered account
            </synopsis>
            <note>
                This is registered to the url 'user/confirm'.
            </note>
            <todo>
                Automatic login
            </todo>
        </function>
=cut

sub confirm_account {
    my $confirmation_hash = $INPUT{'confirm'};

    # validate the confirmation hash
    throw 'validation_error' => 'Invalid confirmation code provided.' unless $confirmation_hash =~ /^[a-zA-Z0-9]{32}$/;

    # validate user awaiting confirmation
    my $query = $DB->query('SELECT name, password, email FROM user_new WHERE confirmation_hash = ? LIMIT 1', $confirmation_hash);
    throw 'validation_error' => 'No accounts pending verification matched the provided confirmation code.  Are you sure you haven\'t already confirmed your account?' unless $query->rows() == 1;
    my ($name, $password, $email) = @{$query->fetchrow_arrayref()};
    
    # copy their information to the real users table
    my $query = $DB->query(
        'INSERT INTO users (name, name_hash, password, email, email_hash) VALUES (?, ?, ?, ?, ?)',
        $name, hash::fast(lc($name)), $password, $email, hash::fast($email)
    );
    
    # delete them from the user's-awaiting-confirmation table
    $DB->query("DELETE FROM user_new WHERE confirmation_hash = ?", $confirmation_hash);

    # confirmation message
    confirmation('Your account has been confirmed.',
        'Log In' => "${BASE_URL}login/?user=$name",
    );
}

=xml
        <function name="register">
            <synopsis>
                Registers a new account
            </synopsis>
            <note>
                This is registered to the url 'register'.
            </note>
        </function>
=cut

sub register {

    # make sure the user is not logged in
    throw 'permission_error' unless $USER{'id'} == 0;

    # make sure that registration is enabled
    throw 'validation_error' => 'User registration is currently disabled.' unless $config{'enable_registration'};

    # if the form was submitted
    my $success = try {

        # validate username

        # check username length
        throw 'validation_error' => "Usernames must be between $config{name_min_length} and $config{name_max_length} characters long."          if (length $INPUT{'username'} < $config{'name_min_length'} or length $INPUT{'username'} > $config{'name_max_length'});

        # check username for proper characters
        throw 'validation_error' => 'Usernames may only contain letters, spaces, periods, and underscores.  Names cannot begin with a number.'  unless $INPUT{'username'} =~ /^\D[a-zA-Z0-9 \._]*$/;
        throw 'validation_error' => 'Usernames can not have two non-alphanumeric characters in a row.'                                          if $INPUT{'username'} =~ /[^a-zA-Z0-9]{2}/;

        # check if the selected username is taken
        my $query = $DB->query('SELECT COUNT(*) FROM users WHERE name = ? LIMIT 1', $INPUT{'username'});
        throw 'validation_error' => "The username $INPUT{username} is already taken."                                                           if $query->fetchrow_arrayref()->[0];
        my $query = $DB->query('SELECT COUNT(*) FROM user_new WHERE name = ? LIMIT 1', $INPUT{'username'});
        throw 'validation_error' => "The username $INPUT{username} is already registered, but is still waiting to be confirmed via email."      if $query->fetchrow_arrayref()->[0];

        # validate password

        # check password length
        throw 'validation_error' => "Passwords must be at least $config{pass_min_length} characters long." if length $INPUT{'password'} < $config{'pass_min_length'};

        # check if confirm password matched
        throw 'validation_error' => 'Password and confirm password did not match.'                         if $INPUT{'password'} ne $INPUT{'password2'};

        # validate email address
        throw 'validation_error' => 'Email and confirm email did not match.'                               if $INPUT{'email'} ne $INPUT{'email2'};
        _validate_email();

        # everything validated, add the user

        # generate a confirmation hash
        my $confirmation_hash = string::random(32);

        # add user to database
        my $query = $DB->query(
            'INSERT INTO user_new (name, password, email, ip, confirmation_hash, ctime) VALUES (?, ?, ?, ?, ?, UTC_TIMESTAMP())',
            $INPUT{'username'}, hash::secure($INPUT{'password'}), $INPUT{'email'}, $ENV{'REMOTE_ADDR'}, $confirmation_hash
        );

        # send activation email
        email::send_template(
            'user_registration',
            $INPUT{'email'},
            {
                'site_name'   => $CONFIG{'site_name'},
                'username'    => $INPUT{'username'},
                'email'       => $INPUT{'email'},
                'password'    => $INPUT{'password'},
                'confirm_url' => "$CONFIG{full_url}user/confirm/?confirm=$confirmation_hash",
            }
        );

        # confirmation message
        confirmation('An email has been sent to ' . xml::entities($INPUT{email}) . ' with instructions on how to complete the registration process.');
    } if $ENV{'REQUEST_METHOD'} eq 'POST';

    # print the registration form
    unless ($success) {
        style::include_template('register');
        print "\t<user action=\"register\" username=\"" . xml::entities($INPUT{'username'}) . "\" email=\"" . xml::entities($INPUT{'email'}) . "\" email2=\"" . xml::entities($INPUT{'email2'}) . "\"/>\n";
    }
}

=xml
        <function name="admin">
            <synopsis>
                The administration menu
            </synopsis>
            <note>
                This is registered to the url 'admin/user'.
            </note>
        </function>
=cut

sub admin {

    # create admin center menu
    my $menu = 'user_admin';
    menu::label($menu, 'User Administration');
    menu::description($menu, 'Some description...');

    # populate the admin menu
    menu::add_item('menu' => $menu, 'label' => 'Configuration', 'url' => $module_admin_base_url . 'config/') if $PERMISSIONS{'user_admin_config'};
    menu::add_item('menu' => $menu, 'label' => 'Manage Users',  'url' => $module_admin_base_url . 'manage/') if $PERMISSIONS{'user_admin_manage'};
    menu::add_item('menu' => $menu, 'label' => 'Manage Groups', 'url' => $module_admin_base_url . 'groups/') if $PERMISSIONS{'user_admin_groups'};

    # print the admin center menu
    throw 'permission_error' unless menu::print_xml($menu);
}

=xml
        <function name="admin_config">
            <synopsis>
                Manages the user module's configuration
            </synopsis>
            <note>
                This is registered to the url 'admin/user/config'.
            </note>
        </function>
=cut

sub admin_config {
    require_permission('user_admin_config');
    style::include_template('admin_config');

    # configuration variables
    my @global_fields = qw(avatar_max_size avatar_max_height avatar_max_width name_min_length name_max_length pass_min_length enable_registration);
    my @site_fields   = qw(default_name cookie_path cookie_domain default_group guest_group customizable_styles);

    # the input source for the edit config form, defaults to the existing config
    my $input_source  = \%config;

    # the form has been submitted
    try {
        $input_source = \%INPUT;

        # validate user input
        throw 'validation_error' => 'Invalid maximum avatar size.'      unless $INPUT{'avatar_max_size'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid maximum avatar width.'     unless $INPUT{'avatar_max_width'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid maximum avatar height.'    unless $INPUT{'avatar_max_height'} =~ /^\d+$/;
        throw 'validation_error' => 'Invalid minimum password length.'  if (!$INPUT{'pass_min_length'} or $INPUT{'pass_min_length'} =~ /\D/);
        throw 'validation_error' => 'Invalid minimum username length.'  if (!$INPUT{'name_min_length'} or $INPUT{'name_min_length'} =~ /\D/);
        throw 'validation_error' => 'Invalid maximum username length.'  if (!$INPUT{'name_max_length'} or $INPUT{'name_max_length'} < $INPUT{'name_min_length'} or $INPUT{'name_max_length'} =~ /\D/);
        throw 'validation_error' => 'Invalid guest username.'           unless length $INPUT{'default_name'};
        throw 'validation_error' => 'Invalid guest group.'              unless exists $groups{$INPUT{'guest_group'}};
        throw 'validation_error' => 'Invalid default registered group.' unless exists $groups{$INPUT{'default_group'}};
        $INPUT{'enable_registration'} = $INPUT{'enable_registration'} ? 1 : 0 ;
        $INPUT{'customizable_styles'} = $INPUT{'customizable_styles'} ? 1 : 0 ;

        # everything validated, update settings
        my $query_update_site_config   = $DB->prepare("UPDATE ${module_db_prefix}config SET value = ? WHERE name = ?");
        map { $query_update_site_config->execute($INPUT{$_}, $_) } @site_fields;
        my $query_update_global_config = $DB->prepare("UPDATE user_config SET value = ? WHERE name = ?");
        map { $query_update_global_config->execute($INPUT{$_}, $_) } @global_fields;

        # print a confirmation message
        confirmation('User settings have been saved.');

        # reload configuration for all daemons
        ipc::do('module', 'load_config', 'user');
    } if $ENV{'REQUEST_METHOD'} eq 'POST';

    # print the edit config form
    my $fields = join '', map { " $_=\"" . xml::entities($input_source->{$_}) . '"' } @site_fields, @global_fields;
    print qq~\t<user action="admin_config"$fields>\n~;
    _print_groups();
    print "\t</user>\n";
}

=xml
        <function name="admin_delete_group">
            <synopsis>
                Deletes a user group
            </synopsis>
            <note>
                This is registered to the url 'admin/user/groups/delete'.
            </note>
        </function>
=cut

sub admin_delete_group {
    require_permission('user_admin_groups');

    # validate group id
    my $group_id = $INPUT{'group'};
    throw 'validation_error' => 'Invalid group ID' unless exists $groups{$group_id};
    my $group = $groups{$group_id};

    # if the user has selected a group to move users to
    my $success = try {

        # validate destination group
        throw 'validation_error' => 'Invalid destination group ID' unless (exists $groups{$INPUT{'dest_group'}} and $INPUT{'dest_group'} != $group_id);

        # destination group was good, move users and delete the group
        $DB->do("UPDATE ${module_db_prefix}permissions SET group_id = $INPUT{dest_group} WHERE group_id = $group_id");
        $DB->do("DELETE FROM ${module_db_prefix}groups WHERE id = $group_id");

        # print a confirmation message
        confirmation("\"$group->{name}\" has been deleted.");

        # reload label data from the database
        ipc::do('user', '_load_groups');

        # print the manage user groups page
        admin_groups();
    } if $ENV{'REQUEST_METHOD'} eq 'POST';

    # prompt the user to select a group to move users to
    unless ($success) {
        style::include_template('admin_groups_delete');
        print qq~\t<user action="admin_groups_delete" id="$group_id" name="$group->{name}" default_group="$config{default_group}">\n~;
        _print_groups();
        print "\t</user>\n";
    }
}

=xml
        <function name="admin_edit_group">
            <synopsis>
                Modifies a user group
            </synopsis>
            <note>
                This is registered to the url 'admin/user/groups/edit'.
            </note>
        </function>
=cut

sub admin_edit_group {
    require_permission('user_admin_groups');

    # validate group id and localize group data
    my $group_id = $INPUT{'group'};
    throw 'validation_error' => 'Invalid group ID' unless exists $groups{$group_id};
    my $group = $groups{$group_id};

    # if the form has been submitted
    my $success = try {

        # validate group name
        throw 'validation_error' => 'A group name is required.' unless length $INPUT{'name'};
        my $name = xml::entities($INPUT{'name'});
        for my $check_group_id (keys %groups) {
            next if $check_group_id == $group_id;
            throw 'validation_error' => 'That group name is already taken.' if $groups{$check_group_id}->{'name'} eq $name;
        }

        # add the database entry
        my @set;
        for my $module_id (keys %module::loaded) {
            my $perms = get_module_permissions($module_id);
            next unless $perms;
            for my $perm (keys %{$perms}) { push @set, "$perm = $INPUT{$perm}" }
        }
        push @set, 'name = ' . $DB->quote($name);
        $DB->do("UPDATE ${module_db_prefix}groups SET " . join(', ', @set) . " WHERE id = $group_id");

        # confirmation
        confirmation("The user group \"$name\" has been saved.");
            
        # reload label data from the database
        ipc::do('user', '_load_groups');

        # print the manage user groups page
        admin_groups();
    } if $ENV{'REQUEST_METHOD'} eq 'POST';

    # print the edit group form
    unless ($success) {
        style::include_template('admin_groups_edit');
        my $num_users = $DB->query("SELECT COUNT(*) FROM ${module_db_prefix}permissions WHERE group_id = ?", $group_id)->fetchrow_arrayref()->[0];
        print qq~\t<user action="admin_groups_edit" id="$group_id" name="$group->{name}" num_users="$num_users">\n~;
        _print_permissions($group_id);
        print "\t</user>\n";
    }
}

=xml
        <function name="admin_create_group">
            <synopsis>
                Creates a user group
            </synopsis>
            <note>
                This is registered to the url 'admin/user/groups/create'.
            </note>
        </function>
=cut

sub admin_create_group {
    require_permission('user_admin_groups');

    # if the form has been submitted
    my $name;
    my $success = try {

        # validate group name
        throw 'validation_error' => 'A group name is required.'            unless $INPUT{'name'};
        $name = xml::entities($INPUT{'name'});
        for my $check_group_id (keys %groups) {
            throw 'validation_error' => 'That group name is already taken' if $groups{$check_group_id}->{'name'} eq $name;
        }

        # add the database entry
        my (@update_fields, @update_values);
        for my $module_id (keys %module::loaded) {
            my $perms = get_module_permissions($module_id);
            next unless $perms;
            for my $perm (keys %{$perms}) {
                push(@update_fields, $perm);
                push(@update_values, $INPUT{$perm});
            }
        }
        push(@update_fields, 'name');
        push(@update_values, $DB->quote($name));
        $DB->do("INSERT INTO ${module_db_prefix}groups (" . join(', ', @update_fields) . ") VALUES (" . join(', ', @update_values) . ")");

        # confirmation
        confirmation("The user group \"$name\" has been created.");
            
        # reload label data from the database
        ipc::do('user', '_load_groups');

        # print the manage user groups page
        admin_groups();
    } if $ENV{'REQUEST_METHOD'} eq 'POST';

    # print a create group form
    unless ($success) {
        style::include_template('admin_groups_create');
        print "\t<user action=\"admin_groups_create\" name=\"$name\">\n";
        _print_permissions();
        print "\t</user>\n";
    }
}

=xml
        <function name="admin_groups">
            <synopsis>
                The manage user groups menu
            </synopsis>
            <note>
                This is registered to the url 'admin/user/groups'.
            </note>
        </function>
=cut

sub admin_groups {
    require_permission('user_admin_groups');
    style::include_template('admin_groups');

    print qq~\t<user action="admin_groups">\n~;
    _print_groups();
    print "\t</user>\n";
}

=xml
        <function name="admin_manage">
            <synopsis>
                Manage individual users
            </synopsis>
            <note>
                This is registered to the url 'admin/user/manage'.
            </note>
        </function>
=cut

sub admin_manage {
    require_permission('user_admin_manage');

    # if the form has been submitted
    if (length $INPUT{'find'}) {

        # prepare the find user query
        my $find_by_field;
        if ($INPUT{'find'} =~ /^\d+$/) { # find by user id
            $find_by_field = 'id';
        } else {                         # find by username
            $find_by_field = 'name';
        }

        # find the user
        my $found_user = find($INPUT{'find'});

        # if no user was found
        unless ($found_user) {
            style::include_template('admin_manage');
            print "\t<user mode=\"admin_manage\" find=\"" . xml::entities($INPUT{'find'}) . "\" />\n";
            return;
        }

        # if you are trying to delete a user
        if ($INPUT{'a'} eq 'delete') {

            # get confirmation
            confirm("Are you sure you want to permanentally delete '$found_user->{name}'?");
            
            # delete the user's settings
            $DB->query("DELETE FROM users WHERE id = ?", $found_user->{'id'});

            # delete the user's permissions entry in all sites
            my $query = $DB->query("SELECT id FROM sites");
            while (my $site = $query->fetchrow_arrayref()) {
                my $site_id = $site->[0];
                $DB->query("DELETE FROM ${site_id}_user_permissions WHERE user_id = ?", $found_user->{'id'});
            }

            # print confirmation
            confirmation("'$found_user->{name}' has been deleted.");
        }

        # list found user
        else {

            # create the menu
            my $menu = 'user_admin_manage';
            menu::label($menu, $found_user->{'name'});

            # populate the menu
            menu::add_item('menu' => $menu, 'label' => 'Edit Settings', 'url' => "${BASE_URL}user/settings/?id=$found_user->{id}");
            menu::add_item('menu' => $menu, 'label' => 'Delete',        'url' => "${module_admin_base_url}manage/?find=$found_user->{id}&amp;a=delete");

            # print the menu
            menu::print_xml($menu);
        }
    }

    # print a fresh find user form
    else {
        style::include_template('admin_manage');
        print "\t<user action=\"admin_manage\" />\n";
    }
}

=xml
        <function name="login">
            <synopsis>
                Logs a user into the web site
            </synopsis>
            <note>
                This is registered to the url 'login'.
            </note>
        </function>
=cut

sub login {

    # if the form has been submitted
    if ($ENV{'REQUEST_METHOD'} eq 'POST') {

        # user logged in successfully
        if ($USER{'id'}) {
            my %options;
            $options{'Return to the Previous Page'} = xml::entities($INPUT{'referer'}) unless $INPUT{'referer'} eq "$CONFIG{full_url}logout/";
            confirmation('You are now logged in.', %options);
            return;
        }

        # user tried to log in but failed
        else {
            print "\t<error>Invalid username/password combination.</error>\n";
        }
    }

    # if the form has not been submitted
    style::include_template('login');
    my $referer = exists $ENV{'HTTP_REFERER'} ? $ENV{'HTTP_REFERER'} : 'javascript:history.go(-2);';
    print "\t<user action=\"login\" referer=\"" . xml::entities($referer) . "\" user=\"" . xml::entities($INPUT{'user'}) . "\" />\n";

    # executed at request_init if the login form is submitted
    sub _login_init {        
        my $restrict_ip = $INPUT{'restrict_ip'} ? '1' : '0' ; # PostgreSQL must have string 1/0 to translate it to a bool true/false

        # get the user id by login credentials
        $select_user_id_by_credentials->execute(hash::fast(lc($INPUT{'user'})), hash::secure($INPUT{'password'}));
        my $user_id = $select_user_id_by_credentials->fetchrow_arrayref()->[0] if $select_user_id_by_credentials->rows();
        
        # if the login was successful
        if (defined $user_id) {
            
            # remove the any existing session for the user_id from the database
            $DB->do("DELETE FROM ${module_db_prefix}sessions WHERE user_id = $user_id LIMIT 1");
            
            my ($new_session, $geoip_country, $geoip_region, $geoip_city) = _create_session($user_id, $restrict_ip, $ENV{'REMOTE_ADDR'});
            
            $USER{'session'} = $new_session;
            
            if ($config{'enable_geoip'}) {
                $USER{'geoip_country'} = $geoip_country;
                $USER{'geoip_region'}  = $geoip_region;
                $USER{'geoip_city'}    = $geoip_city;
            }
            
            my $how_long = ($INPUT{'how_long'} and $INPUT{'how_long'} =~ /^\d+$/) ? $INPUT{'how_long'} : 0 ; # 0 = remove at end of browser session
            cgi::set_cookie('session', $USER{'session'}, $how_long, $config{'cookie_path'}, $config{'cookie_domain'});
            
            # check if the user is set up in a group on this site, if not, put them in the default group
            $select_permissions_count->execute($user_id);
            $DB->do("INSERT INTO ${module_db_prefix}permissions (user_id, group_id) VALUES ('$user_id', '$config{default_group}')") if $select_permissions_count->fetchrow_arrayref()->[0] == 0;
        }
    }
}

=xml
        <function name="logout">
            <synopsis>
                Logs a user out of the web site
            </synopsis>
            <note>
                This is registered to the url 'logout'.
            </note>
        </function>
=cut

sub logout {
    #throw 'permission_error' unless $USER{'id'}; # no harm in removing this, it would only be confusing if people accidentally visited this page while logged out
    confirmation('You are now logged out.');

    # executed at request_init
    sub _logout_init {
        
        # remove the session from the database
        $DB->do("DELETE FROM ${module_db_prefix}sessions WHERE user_id = $USER{id} LIMIT 1");

        # remove the existing id and session from this request's user data (to turn the user into a guest)
        $USER{'id'}      = 0;
        $USER{'session'} = 0;

        # remove the session cookie
        cgi::set_cookie('session', '', 0,  $config{'cookie_path'}, $config{'cookie_domain'});
    }
}


=xml
        <function name="view_profile">
            <synopsis>
                View a profile
            </synopsis>
            <note>
                This is registered to the url 'user/profile/(\w+)'.
            </note>
        </function>
=cut

sub view_profile {
    my ($username) = @_;
    
    user::require_permission('user_profile_view');
    
    throw 'validation_error' => 'A username is required.' unless length $username;
    throw 'validation_error' => 'Profiles are currently disabled.' unless $config{'enable_profile'} == 1;
    
    # fetch user's profile data 
    my $user = $DB->query("SELECT users.id, user_profiles.*, users.email FROM users, user_profiles WHERE users.name_hash = ? and user_profiles.user_id = users.id LIMIT 1", hash::fast(lc($username)) )->fetchrow_hashref();
    
    # validate username
    throw 'request_404' unless $user;
    
    # fetch profile metadata
    # todo: move this into a subroutine and cache it
    my $query = $DB->query("SELECT name, parent, link, bbcode FROM user_profile_meta ORDER BY name ASC");
    
    # prepare profile metadata
    my $fields;
    while ( my $field = $query->fetchrow_arrayref() ) {
        my %field = ( 'name' => $field->[0], 'link' => $field->[2], 'bbcode' => $field->[3] );
        push @{$fields{ $field->[1] }}, \%field;
    }
    
    # print profile data
    style::include_template('view_profile');
   
    print qq~\t<user action="view_profile" name="$username">\n~;
    
    # print fields by group
    for my $group (sort keys %fields) {
        print qq~\t\t<group name="$group">\n~;
        for my $field (@{$fields{ $group }}) {
            
            # skip empty fields and set email
            next if length $user->{ $field->{'name'} } == 0;
            $field->{'name'} = "email" if ($field->{'name'} eq "display_email" and $user->{ $field->{'name'} } == 1);
            
            # unserialize fields with bbcode/xhtml
            if ($field->{'bbcode'} == 1) {
                my @unserialized = split /(?!\\),/, $user->{ $field->{'name'} };
                @unserialized[1] =~ s/\\,/,/o;
                $user->{ $field->{'name'} } = @unserialized[1];
                print qq~\t\t\t<field name="$field->{'name'}">\n~;
                print "\t\t\t\t" . $user->{ $field->{'name'} } . "\n";
                print "\t\t\t</field>\n";
            }
            else {
                my $link = qq~link="$field->{'link'}" ~ unless length $field->{'link'} == 0;
                print qq~\t\t\t<field name="$field->{'name'}" value="$user->{ $field->{'name'} }" $link/>\n~; 
            }            
        }
        print "\t\t</group>\n";
    }
    print "\t</user>\n";
    
    # contextual admin menu
    if ($PERMISSIONS{'user_admin_manage'}) {
        my $item = menu::add_item('menu' => 'admin', 'label' => 'This User', 'url' => $REQUEST{'url'});
        menu::add_item('parent' => $item, 'label' => 'Edit Account',    'url' => $REQUEST{'url'} . '/?id=' .  $user->{'user_id'});
        menu::add_item('parent' => $item, 'label' => 'Delete',          'url' => $module_admin_base_url . 'manage/?find=' .  $user->{'user_id'} . '&amp;a=delete');
    }
}

=xml
    </section>

    <section title="Event Hooks">
=cut

#
# Request
#

# called before the header is printed
event::register_hook('request_init', 'hook_request_init', 95);
sub hook_request_init {
    my $is_guest_session;

    # login stuff
    if ($REQUEST{'module'} eq 'user' and $REQUEST{'action'} eq 'login' and $ENV{'REQUEST_METHOD'} eq 'POST') {
        _login_init();
    }

    # otherwise, get the session from the cookie
    else {
        $USER{'session'}       = $COOKIES{'session'};
        $USER{'geoip_country'} = $COOKIES{'country'};
        $USER{'geoip_region'}  = $COOKIES{'region'};
        $USER{'geoip_city'}    = $COOKIES{'city'};
    }
    
    # if a session id is set
    if (exists $USER{'session'} and length $USER{'session'} == 32) {

        # fetch user id and session info from the db
        $select_user_id_by_session->execute($USER{'session'});

        # if the user is logged in
        if ($select_user_id_by_session->rows()) {
        #if ($select_user_by_session->rows()) {
            my ($id, $ip, $restrict_ip, $geoip_country, $geoip_region, $geoip_city) = @{$select_user_id_by_session->fetchrow_arrayref()};
            
            # Don't fetch the user data for guests
            if ($id != 0) {
            
                # fetch the user data from the db
                $select_user_by_id->execute($id);
                
                my ($name, $time_offset, $date_format, $style, $group) = @{$select_user_by_id->fetchrow_arrayref()};
                if (($ip eq $ENV{'REMOTE_ADDR'} and $restrict_ip) or !$restrict_ip) {
                    %USER = (
                        'id'          => $id,
                        'name'        => $name,
                        'group'       => $group, # TODO: should be group_id ?
                        'time_offset' => $time_offset,
                        'date_format' => $date_format || $datetime::formats[0],
                        'session'     => $USER{'session'},
                        'style'       => $config{'customizable_styles'} ? $style : '' ,
                    );
                    
                    if ($config{'enable_geoip'}) {
                        $USER{'geoip_country'} = $geoip_country;
                        $USER{'geoip_region'}  = $geoip_region;
                        $USER{'geoip_city'}    = $geoip_city;
                    }
                    
                    $REQUEST{'style'} = $USER{'style'} if $USER{'style'} ne '';
                }
            }
            
            # set the user id for guests
            else {
                $is_guest_session = 1 if (($ip eq $ENV{'REMOTE_ADDR'} and $restrict_ip) or !$restrict_ip); 
            }

            # Update sesssion access time
            $update_user_session->execute($ip, $restrict_ip, datetime::gmtime, $USER{'session'});
        }
        
        # if the user has a session id, but it's invalid, delete the cookie so this session is not checked again
        cgi::set_cookie('session', '', 0, $config{'cookie_path'}, $config{'cookie_domain'}) unless exists $USER{'id'} or defined $is_guest_session;
    }

    # if the user is trying to log out
    _logout_init() if ($REQUEST{'module'} eq 'user' and $REQUEST{'action'} eq 'logout' and exists $USER{'id'});
    
    # create a session for guests or continue the existing session
    unless (exists $USER{'id'}) {
        my ($session, $geoip_country, $geoip_region, $geoip_city);
        
        #my ($session, $geoip_country, $geoip_region, $geoip_city) = defined $is_guest_session ? $USER{'session'} : _create_session(0, 1, $ENV{'REMOTE_ADDR'}); # id = 0 and restrict_ip = 1
        
        if (defined $is_guest_session) {
            $session       = $USER{'session'};
            $geoip_country = $USER{'geoip_country'};
            $geoip_region  = $USER{'geoip_region'};
            $geoip_city    = $USER{'geoip_city'};
        } 
        else {
            ($session, $geoip_country, $geoip_region, $geoip_city) = _create_session(0, 1, $ENV{'REMOTE_ADDR'});
        }
        
        # set default user data
        %USER = (
            'id'          => 0,
            'group'       => $config{'guest_group'},
            'name'        => $config{'default_name'},
            'session'     => $session,
            'date_format' => $datetime::formats[0],
            'time_offset' => 0,
        );
        
        if ($config{'enable_geoip'}) {
            $USER{'geoip_country'} = $geoip_country;
            $USER{'geoip_region'}  = $geoip_region;
            $USER{'geoip_city'}    = $geoip_city;
        }
        
        # set the cookies
        cgi::set_cookie('session', $session,       0, $config{'cookie_path'}, $config{'cookie_domain'}); # 0 = remove at end of browser session
        cgi::set_cookie('country', $geoip_country, 0, $config{'cookie_path'}, $config{'cookie_domain'}); 
        cgi::set_cookie('region',  $geoip_region,  0, $config{'cookie_path'}, $config{'cookie_domain'}); 
        cgi::set_cookie('city',    $geoip_city,    0, $config{'cookie_path'}, $config{'cookie_domain'}); 
    }

    # alias user permissions to an easier-to-reach place
    *PERMISSIONS = \%{$groups{$USER{'group'}}};
}

# called before the footer is printed
event::register_hook('request_end', 'hook_request_end', 0);
sub hook_request_end {
    my $geoip_attributes = $config{'enable_geoip'} ? ' country="' . $USER{'geoip_country'} . '" region="' . $USER{'geoip_region'} . '" city="' . $USER{'geoip_city'} . '"' : '';
    
    # Print the user node with permissions child-node if request flag set
    if (exists $REQUEST{'user'}{'print_permissions'}) {
        my $attributes;
        
        # Print as an attribute if the permission exists
        for my $permission (keys %{ $REQUEST{'user'}{'print_permissions'} }) {
            $attributes .= $permission . '="' . $PERMISSIONS{ $permission } . '" ' if exists $PERMISSIONS{ $permission };
        }
        
        print qq~\t<user id="$USER{id}" name="$USER{name}" date_format="$USER{date_format}" time_offset="$USER{time_offset}"$geoip_attributes>\n~;
        print qq~\t\t<permissions $attributes/>\n~;
        print qq~\t</user>\n~;
    }
    
    # Otherwise just print the user node sans permissions.
    else {
        print qq~\t<user id="$USER{id}" name="$USER{name}" date_format="$USER{date_format}" time_offset="$USER{time_offset}"$geoip_attributes />\n~;
    }
}

# called after the request is finished
event::register_hook('request_cleanup', 'hook_request_cleanup', 0);
sub hook_request_cleanup {
    %USER = ();
}

#
# Contextual Admin Menu
#

# called when this module's admin menu is printed
event::register_hook('module_admin_menu', 'hook_module_admin_menu');
sub hook_module_admin_menu {
    my $item = menu::add_item('menu' => 'admin', 'label' => 'Users', 'url' => $module_admin_base_url, 'require_children' => 1);
    menu::add_item('parent' => $item, 'label' => 'Configuration', 'url' => $module_admin_base_url . 'config/') if $PERMISSIONS{'user_admin_config'};
    menu::add_item('parent' => $item, 'label' => 'Manage Users',  'url' => $module_admin_base_url . 'manage/') if $PERMISSIONS{'user_admin_manage'};
    menu::add_item('parent' => $item, 'label' => 'Manage Groups', 'url' => $module_admin_base_url . 'groups/') if $PERMISSIONS{'user_admin_groups'};
}

# called when the admin menu is printed (after the module admin menu)
event::register_hook('admin_menu', 'hook_admin_menu');
sub hook_admin_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Users', 'url' => $module_admin_base_url)
        if ($REQUEST{'module'} ne 'user' and
            ($PERMISSIONS{'user_admin_config'} or $PERMISSIONS{'user_admin_groups'} or $PERMISSIONS{'user_admin_manage'}));
}

#
# Administration Center Menus
#

# config menu
event::register_hook('admin_center_config_menu', 'hook_admin_center_config_menu');
sub hook_admin_center_config_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Users', 'url' => $module_admin_base_url . 'config/') if $PERMISSIONS{'user_admin_config'};
}

# modules menu
event::register_hook('admin_center_modules_menu', 'hook_admin_center_modules_menu');
sub hook_admin_center_modules_menu {
    menu::add_item('parent' => $_[0], 'label' => 'Users', 'url' => $module_admin_base_url) if (
        $PERMISSIONS{'user_admin_config'} or $PERMISSIONS{'user_admin_manage'} or $PERMISSIONS{'user_admin_groups'} );
}

=xml
    </section>

    <section title="Helper Functions">
=cut

# insert the a new session into the database
sub _create_session {
    my ($user_id, $restrict_ip, $ip) = @_;
    my ($new_session, $geoip_country, $geoip_region, $geoip_city) = undef;
    
    my $geoip_results = $geoip->record_by_addr($ip) if $config{'enable_geoip'};
    
    if ($geoip_results) {
        $geoip_country = $geoip_results->country_code;
        $geoip_region  = $geoip_results->region;
        $geoip_city    = $geoip_results->city;
    }
    
    # if there is a session id collision try again until there isn't
    my $success = 0;
    until ($success) {
        $success = try {
            $new_session = string::random(32);            
            $insert_user_session->execute($user_id, $new_session, $ip, $restrict_ip, datetime::gmtime, $geoip_country, $geoip_region, $geoip_city);
        }
        catch 'db_error', with {
            my $error = shift;
            
            # if it is a duplicate error, abort, returning false, triggering the until() to retry
            if ($error =~ /Duplicate (?:entry|key)/) { abort(); } # entry for mysql, key for postgresql
            else { throw 'db_error' => $error; }
        };
    }
    
    return $new_session, $geoip_country, $geoip_region, $geoip_city;
}


# delete expired guest sessions from the database
sub _clean_sessions {
    $interval = 86400; # 24 hours
    
    $DB->query("DELETE FROM ${module_db_prefix}sessions WHERE user_id = '0' and access_ctime <= ?", datetime::gmtime() - $interval);
}

sub _validate_email {
    throw 'validation_error' => 'Invalid email address.' unless email::is_valid_email($INPUT{'email'});
    my $user_id = shift;
    my $query = $user_id
        ? $DB->query('SELECT COUNT(*) FROM users WHERE email_hash = ? and id != ? LIMIT 1', hash::fast($INPUT{'email'}), $user_id)
        : $DB->query('SELECT COUNT(*) FROM users WHERE email_hash = ? LIMIT 1', hash::fast($INPUT{'email'}));
    throw 'validation_error' => 'The email address ' . xml::entities($INPUT{'email'}) . ' is already in use by another user.' if $query->fetchrow_arrayref()->[0];
    my $query = $DB->query('SELECT COUNT(*) FROM user_new WHERE email = ? LIMIT 1', $INPUT{'email'});
    throw 'validation_error' => 'The email address ' . xml::entities($INPUT{'email'}) . ' is already registered by another user, but has not yet been confirmed.' if $query->fetchrow_arrayref()->[0];
}

# load group data from the database
sub _load_groups {

    # reset data structure
    %groups = ();

    # load and save site user groups
    my $query = $DB->query("SELECT * FROM ${module_db_prefix}groups");
    while (my $group = $query->fetchrow_hashref()) {
        $groups{$group->{'id'}} = $group;
    }
}

# list user groups in xml
sub _print_groups {
    print "\t\t<groups>\n";
    for my $group_id (keys %groups) {
        print qq~\t\t\t<group id="$group_id">$groups{$group_id}->{name}</group>\n~;
    }
    print "\t\t</groups>\n";
}

# prints module permissions
sub _print_permissions {
    my $group_id = shift;
    print "\t\t<permissions>\n";
    for my $module_name (keys %module::loaded) {
        my $perms = get_module_permissions($module_name);
        next unless $perms;
        my $meta = module::get_meta($module_name);
        print qq~\t\t\t<module id="$module_name" name="$meta->{name}">\n~;
        for my $perm (keys %{$perms}) {
            print qq~\t\t\t\t<permission id="$perm" name="$perms->{$perm}->{name}">\n~;
            my $levels = $perms->{$perm}->{'levels'};
            my $id = 0;
            for my $level (@{$levels}) {
                my $selected = (($group_id and $groups{$group_id}->{$perm} eq $id) or (defined $INPUT{$perm} and $INPUT{$perm} == $id)) ? ' selected="selected"' : '';
                print qq~\t\t\t\t\t<level id="$id"$selected>$level</level>\n~;
                $id++;
            }
            print "\t\t\t\t</permission>\n";
        }
        print "\t\t\t</module>\n";
    }
    print "\t\t</permissions>\n";
}

=xml
    </section>

    <section title="Public API">

        <function name="require_permission">
            <synopsis>
                Throws a 'permission_error' exception if a user does not meet a certain permission requirement
            </synopsis>
            <note>
                'minimum_level' defaults to 1.
            </note>
            <prototype>
                user::require_permission(string permission_id[, int minimum_level])
            </prototype>
        </function>
=cut

sub require_permission {
    my $id    = shift;
    my $level = scalar @_ ? shift : 1 ;

    throw 'permission_error' unless $PERMISSIONS{$id} >= $level;
}

=xml
        <function name="add_permission">
            <synopsis>
                Adds a permission to the current site's user groups table
            </synopsis>
            <note>
                'default_permission_level' defaults to 0.
            </note>
            <prototype>
                user::add_permission(string permission_id[, int default_permission_level])
            </prototype>
        </function>
=cut

sub add_permission_once {
    my $permission_id = $_[0];
    my $perm_exists = 1;
    try {
        $oyster::DB->query("SELECT $permission_id FROM ${module_db_prefix}groups");
    }
    catch 'db_error', with {
        $perm_exists = 0;
        abort(1);
    };
    add_permission($permission_id, @_) unless $perm_exists;
}

sub add_permission {
    my $permission_id = shift;
    $DB->do("ALTER TABLE ${module_db_prefix}groups ADD `$permission_id` TINYINT(1) NOT NULL DEFAULT '0'");
    if (@_) {
        my $default_level = shift;
        $DB->query("UPDATE ${module_db_prefix}groups SET `$permission_id` = ?", $default_level);
    }
}

=xml
        <function name="delete_permission">
            <synopsis>
                Deletes a permission from the current site's user groups table
            </synopsis>
            <prototype>
                user::delete_permission(string permission_id)
            </prototype>
        </function>
=cut

sub delete_permission {
    my $permission = shift;
    $DB->do("ALTER TABLE ${module_db_prefix}groups DROP `$permission`");
}

=xml
        <function name="get_email">
            <synopsis>
                Retreives a user's email address based on their ID.
            </synopsis>
            <note>
                user_id defaults to the current user ID (if any), and if fetching the current user's email, adds it to the %USER hash.
            </note>
            <prototype>
                string = user::get_email([int user_id])
            </prototype>
        </function>
=cut

sub get_email {

    # fetch a particular user's email
    if (@_ and $_[0] != $USER{'id'}) {
        my $query = $DB->query('SELECT email FROM users WHERE id = ? LIMIT 1', shift());
        return unless $query->rows() == 1;
        return $query->fetchrow_arrayref()->[0];
    }

    # fetch the current user's email
    else {
        return unless $USER{'id'};
        return $USER{'email'} if $USER{'email'};
        $USER{'email'} = $DB->query('SELECT email FROM users WHERE id = ? LIMIT 1', $USER{'id'})->fetchrow_arrayref()->[0];
    }
}

=xml
        <function name="get_name">
            <synopsis>
                Retreives a user's name based on their ID.
            </synopsis>
            <prototype>
                string = user::get_name(int user_id)
            </prototype>
        </function>
=cut

sub get_name {
    my $user_id = shift;
    my $query = $DB->query('SELECT name FROM users WHERE id = ? LIMIT 1', $user_id);
    return unless $query->rows() == 1;
    return $query->fetchrow_arrayref()->[0];
}

=xml
        <function name="find">
            <synopsis>
                Returns an entry from the user table by id, email, or username
            </synopsis>
            <prototype>
                hashref = user::find(int user_id or string username or string email)
            </prototype>
        </function>
=cut

sub find {
    my $find = shift;

    # prepare the find user query
    my $field;
    if ($find =~ /^\d+$/) {   # find by user id
        $field = 'id';
    } elsif ($find =~ /\@/) { # find by email
        $field = 'email';
    } else {                  # find by username
        $field = 'name';
    }

    # execute the search query
    my $query = $DB->query("SELECT * FROM users WHERE $field = ? LIMIT 1", $find);

    return unless $query->rows() == 1;
    return $query->fetchrow_hashref();
}

=xml
        <function name="is_username_taken">
            <synopsis>
                Checks if a given username is taken
            </synopsis>
            <prototype>
                bool = user::is_username_taken(string username)
            </prototype>
        </function>
=cut

sub is_username_taken {
    my $username = lc(shift());
    return $DB->query("SELECT COUNT(*) FROM users WHERE name_hash = ? LIMIT 1", hash::fast(lc $username))->fetchrow_arrayref()->[0];
}

=xml
        <function name="get_module_permissions">
            <synopsis>
                Fetches permissions information about a module
            </synopsis>
            <note>
                Returns undef if no permission information is available
            </note>
            <note>
                throws a 'perl_error' exception if permissions.pl exists but an error occured while reading it
            </note>
            <prototype>
                hashref = user::get_module_permissions(string module_id)
            </prototype>
        </function>
=cut

sub get_module_permissions {
    my $module_id = shift;
    my $filename = "./modules/${module_id}/permissions.pl";
    return unless -e $filename;
    my $permissions = do $filename;
    unless ($permissions) {
        throw 'perl_error' => "Couldn't parse permissions file '$filename': $@" if $@;
        throw 'perl_error' => "Couldn't do permissions file '$filenamee': $!"   unless defined $permissions;
        throw 'perl_error' => "Couldn't run permissions file '$filename'."      unless $permissions;
    }
    return $permissions;
}

=xml
        <function name="print_permissions">
            <synopsis>
                Prints user permissions exactly matching requested strings as a user child-node
            </synopsis>
            <note>
                Prints all permissions if no string is present
            </note>
            <prototype>
                user::print_permissions([string permission_name ...])
            </prototype>
            <example>
                user::print_permissions;
            </example>
            <example>
                user::print_permissions('user_admin_config', 'user_admin_groups');
            </example>
        </function>
=cut

sub print_permissions {
    my @permissions = @_;
    
    if (scalar @permissions > 0) {
        for my $permission (@permissions) {
            $REQUEST{'user'}{'print_permissions'}{ $permission } = 1 if exists $PERMISSIONS{ $permission };
        }
    }
    else {
        for my $permission (keys %PERMISSIONS) {
            $REQUEST{'user'}{'print_permissions'}{ $permission } = 1 unless ($permission =~ /^name|id/o);
        }
    }
}

=xml
        <function name="print_permissions_regex">
            <synopsis>
                Prints user permissions matching requested strings as a user child-node
            </synopsis>
            <note>
                Matches permissions starting with the provided string(s)
            </note>
            <prototype>
                user::print_permissions_regex(string permission_partial_name [, string permission_partial_name ...])
            </prototype>
            <example>
                user::print_permissions_regex('user_admin_');
            </example>
        </function>
=cut

sub print_permissions_regex {
    my @permissions = @_;
    
    for my $regex (@permissions) {
        for my $permission (keys %PERMISSIONS) {
            $REQUEST{'user'}{'print_permissions'}{ $permission } = 1 if ($permission =~ /^$regex/); 
        }
    }        
}

=xml
        <function name="print_module_permissions">
            <synopsis>
                Prints all user permissions for requested modules as a user child-node
            </synopsis>
            <prototype>
                user::print_module_permissions(string module_name [, string module_name ...])
            </prototype>
            <example>
                user::print_module_permissions('user');
            </example>
        </function>
=cut

sub print_module_permissions {
    my @permissions = @_;
    my $regex;
    my $module_permissions;
    
    for my $module (@permissions) {
        $regex = $module . '_';        
        $module_permissions = get_module_permissions($module);
        
        for my $permission (keys %PERMISSIONS) {
            $REQUEST{'user'}{'print_permissions'}{ $permission } = 1 if ( $permission =~ /^$regex/ and exists $module_permissions->{ $permission } ); 
        }
    }
}

=xml
    </section>
</document>
=cut

1;

# Copyright BitPiston 2008
