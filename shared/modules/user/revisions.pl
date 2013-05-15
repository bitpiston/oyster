
package user::revisions;

# ----------------------------------------------------------------------------
# Revision 1
# ----------------------------------------------------------------------------

$revision[1]{'up'}{'shared'} = sub {

    # Register module
    module::register('user');

    # Create config table and populate initial settings
    $DB->query(qq~CREATE TABLE `user_config` (
          `name` tinytext NOT NULL,
          `value` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    $DB->query(qq~INSERT INTO `user_config` (`name`, `value`)
        VALUES
        	('avatar_max_size','30'),
        	('avatar_max_width','120'),
        	('avatar_max_height','120'),
        	('name_min_length','4'),
        	('name_max_length','12'),
        	('pass_min_length','4'),
        	('enable_registration','1');~);

    # Create users table and add the default user
    $DB->query(qq~CREATE TABLE `users` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `name` varchar(128) DEFAULT '',
          `name_hash` varchar(10) DEFAULT '',
          `password` varchar(64) NOT NULL DEFAULT '',
          `email` varchar(255) NOT NULL DEFAULT '',
          `email_hash` varchar(64) NOT NULL DEFAULT '',
          `ip` tinytext NOT NULL,
          `time_offset` tinyint(4) NOT NULL DEFAULT '0',
          `date_format` tinytext,
          `restrict_ip` tinyint(1) NOT NULL DEFAULT '0',
          `style` tinytext,
          UNIQUE KEY `user_id` (`id`),
          UNIQUE KEY `email_hash` (`email_hash`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    $DB->query(qq~INSERT INTO `users` (`name`, `name_hash`, `password`, `email`, `time_offset`, `date_format`, `style`) VALUES
        ('test', ?, ?, 'test\@test.com', 0, '%B %e, %Y %i:%M %p', '')~, hash::fast('test'), hash::secure('test'));

    # Create email change table
    $DB->query(qq~CREATE TABLE `user_email_changes` (
          `user_id` int(11) NOT NULL DEFAULT '0',
          `new_email` tinytext NOT NULL,
          `confirmation_hash` varchar(32) NOT NULL DEFAULT '',
          `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);

    # Create new users table
    $DB->query(qq~CREATE TABLE `user_new` (
          `name` varchar(20) NOT NULL DEFAULT '',
          `password` varchar(64) NOT NULL DEFAULT '',
          `email` tinytext NOT NULL,
          `ip` tinytext NOT NULL,
          `confirmation_hash` varchar(32) NOT NULL DEFAULT '',
          `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
          UNIQUE KEY `name` (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);

    # Create account recovery table
    $DB->query(qq~CREATE TABLE `user_recover` (
          `user_id` int(11) NOT NULL DEFAULT '0',
          `new_pass` char(64) NOT NULL DEFAULT '',
          `confirmation_hash` char(32) NOT NULL DEFAULT '',
          `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
          KEY `confirmation_hash` (`confirmation_hash`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
        
    # Create profile table
    $DB->query(qq~CREATE TABLE `user_profiles` (
          `user_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
          `registered` int(11) NOT NULL,
          `location` tinytext,
          `avatar` tinytext,
          `signature` text,
          `forum_posts` int(11) NOT NULL DEFAULT '0',
          PRIMARY KEY (`user_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
};

$revision[1]{'up'}{'site'} = sub {

    # Enable module
    module::enable('user');

    # Create config table and populate initial settings
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}config` (
          `name` tinytext NOT NULL,
          `value` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    $DB->query(qq~INSERT INTO `${MODULE_DB_PREFIX}config` (`name`, `value`) VALUES
    	('default_name','Guest'),
    	('cookie_path','/'),
    	('cookie_domain',''),
    	('default_group','2'),
    	('guest_group','1'),
    	('enable_registration','1'),
    	('customizable_styles','1'),
    	('enable_geoip','0');~);

    # Create default user groups
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}groups` (
          `id` tinyint(4) NOT NULL AUTO_INCREMENT,
          `name` tinytext NOT NULL,
          `user_admin_config` tinyint(1) NOT NULL DEFAULT '0',
          `user_admin_groups` tinyint(1) NOT NULL DEFAULT '0',
          `user_admin_manage` tinyint(1) NOT NULL DEFAULT '0',
          UNIQUE KEY `id` (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;~);
    $DB->query(qq~INSERT INTO `${MODULE_DB_PREFIX}groups` (`name`, `user_admin_config`, `user_admin_groups`, `user_admin_manage`) VALUES
        ('Guest', 0, 0, 0),
        ('Registered', 0, 0, 0),
        ('Moderator', 0, 0, 1),
        ('Administrator', 1, 1, 1),
        ('Banned', 0, 0, 0)~);

    # Create site permissions table and add the default user
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}permissions` (
          `user_id` int(11) NOT NULL DEFAULT '0',
          `group_id` tinyint(4) NOT NULL DEFAULT '0',
          UNIQUE KEY `user_id` (`user_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    $DB->query(qq~INSERT INTO `${MODULE_DB_PREFIX}permissions` (`user_id`, `group_id`) VALUES(1, 4)~);
    
    # Create sessions table
    $DB->query(qq~CREATE TABLE `${MODULE_DB_PREFIX}sessions` (
          `session_id` varchar(32) NOT NULL DEFAULT '',
          `user_id` int(11) unsigned NOT NULL,
          `ip` tinytext,
          `access_ctime` int(11) unsigned NOT NULL,
          `restrict_ip` tinyint(1) NOT NULL,
          `geoip_country` varchar(2) DEFAULT NULL,
          `geoip_region` varchar(2) DEFAULT NULL,
          `geoip_city` tinytext,
          UNIQUE KEY `session_id` (`session_id`),
          KEY `user_id` (`user_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);

    # Register email templates
    email::add_template('user_registration', 'text', '', 'Welcome to {site_name}', 'Blah blah blah..\r\n\r\n{confirm_url}');
    email::add_template('user_change_email', 'text', '', 'Confirm Email Address Change ({site_name})', 'Visit the address below to change your email address to "{new_email}" on the account "{username}":\r\n\r\n{confirm_url}');
    email::add_template('user_recover_account', 'text', '', 'Account Recovery ({site_name})', 'Visit the address below to change your password to "{new_pass}" on the account "{username}":\r\n\r\n{confirm_url}\r\n');

    # Register URLs
    url::register('url' => 'login',                    'module' => 'user', 'function' => 'login',              'title' => 'Log In');
    url::register('url' => 'logout',                   'module' => 'user', 'function' => 'logout',             'title' => 'Log Out');
    url::register('url' => 'register',                 'module' => 'user', 'function' => 'register',           'title' => 'Register Account');
    url::register('url' => 'admin/user',               'module' => 'user', 'function' => 'admin',              'title' => 'User Administration');
    url::register('url' => 'user/confirm',             'module' => 'user', 'function' => 'confirm_account',    'title' => 'Confirm Account');
    url::register('url' => 'user/recover',             'module' => 'user', 'function' => 'recover',            'title' => 'Recover Account');
    url::register('url' => 'user/account',             'module' => 'user', 'function' => 'edit_account',       'title' => 'Edit User Account');
    url::register('url' => 'user/profile/(\w+)',       'module' => 'user', 'function' => 'view_profile',       'title' => 'View Profile', 'regex' => 1);
    url::register('url' => 'admin/user/manage',        'module' => 'user', 'function' => 'admin_manage',       'title' => 'Manage Users');
    url::register('url' => 'admin/user/config',        'module' => 'user', 'function' => 'admin_config',       'title' => 'User Configuration');
    url::register('url' => 'admin/user/groups',        'module' => 'user', 'function' => 'admin_groups',       'title' => 'Manage User Groups');
    url::register('url' => 'user/confirm_email',       'module' => 'user', 'function' => 'confirm_email',      'title' => 'Confirm Email Change');
    url::register('url' => 'admin/user/groups/edit',   'module' => 'user', 'function' => 'admin_edit_group',   'title' => 'Edit a User Group');
    url::register('url' => 'admin/user/groups/create', 'module' => 'user', 'function' => 'admin_create_group', 'title' => 'Create a User Group');
    url::register('url' => 'admin/user/groups/delete', 'module' => 'user', 'function' => 'admin_delete_group', 'title' => 'Delete a User Group');
};

1;
