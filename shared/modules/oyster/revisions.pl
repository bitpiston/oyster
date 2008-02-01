
package oyster::revisions;

# ----------------------------------------------------------------------------
# Revision 1
# ----------------------------------------------------------------------------

$revision[1]{'up'}{'shared'} = sub {

    # Global config
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `config` (
        `name` tinytext NOT NULL,
        `value` tinytext NOT NULL
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);

    # Date formats
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `date_formats` (`format` tinytext NOT NULL) ENGINE=MyISAM DEFAULT CHARSET=latin1~);
    $DB->query(qq~INSERT INTO `date_formats` (`format`) VALUES
        ('%Y.%m.%d %H:%M:%S'),
        ('%e %B %Y %H:%M'),
        ('%B %e, %Y %i:%M %p')~);

    # IPC
    $DB->query(qq~CREATE TABLE IF NOT EXISTS  `ipc` (
        `id` int(11) NOT NULL auto_increment,
        `module` tinytext NOT NULL,
        `function` tinytext NOT NULL,
        `args` text NOT NULL,
        `daemon` char(32) NOT NULL,
        `site` tinytext NOT NULL,
        UNIQUE KEY `id` (`id`)
        ) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1~);

    # Modules
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `modules` (
        `id` tinytext NOT NULL,
        `revision` smallint(6) NOT NULL default '0'
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);

    # Register the module
    module::register('oyster');

    # Sites
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `sites` (`id` tinytext NOT NULL) ENGINE=MyISAM DEFAULT CHARSET=latin1~);
};

$revision[1]{'up'}{'site'} = sub {

    # Add to module's table
    $DB->query(qq~ALTER TABLE modules ADD `site_$SITE_ID` TINYINT(1) NOT NULL default '0'~);

    # Enable the module
    module::enable('oyster');

    # Site config
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${DB_PREFIX}config` (
        `name` tinytext NOT NULL,
        `value` text NOT NULL
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);
    $DB->query(qq~INSERT INTO `${DB_PREFIX}config` (`name`, `value`) VALUES
        ('error_message', 'You may have just broken the internet.  '),
        ('default_url', 'login'),
        ('time_offset', '-6'),
        ('default_style', 'bitpiston'),
        ('site_name', 'My Website'),
        ('navigation_depth', '1')~);

    # Email Templates
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${DB_PREFIX}email_templates` (
        `name` tinytext NOT NULL,
        `subject` tinytext NOT NULL,
        `body` text NOT NULL
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);

    # Logs
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${DB_PREFIX}logs` (`id` bigint(20) unsigned NOT NULL auto_increment, `type` tinytext NOT NULL, `time` datetime NOT NULL default '0000-00-00 00:00:00', `message` text NOT NULL, `trace` text NOT NULL, UNIQUE KEY `id` (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1~);

    # URLs
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${DB_PREFIX}urls` (
        `id` int(11) NOT NULL auto_increment,
        `parent_id` int(11) NOT NULL default '0',
        `url` tinytext NOT NULL,
        `url_hash` varchar(10) NOT NULL default '',
        `title` tinytext character set utf8 NOT NULL,
        `module` tinytext NOT NULL,
        `function` tinytext NOT NULL,
        `params` tinytext NOT NULL,
        `show_nav_link` tinyint(1) NOT NULL default '0',
        `nav_priority` smallint(6) NOT NULL default '0',
        `regex` tinyint(1) NOT NULL default '0',
        UNIQUE KEY `id` (`id`),
        KEY `url_hash` (`url_hash`),
        KEY `parent_id` (`parent_id`),
        KEY `regex` (`regex`)
        ) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1~);

    # Styles
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `${DB_PREFIX}styles` (
        `id` tinytext NOT NULL,
        `name` tinytext NOT NULL,
        `status` tinyint(1) NOT NULL default '1'
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);
    style::register('bitpiston', 'BitPiston');
    style::enable('bitpiston');

    # Add site entry
    $DB->query('INSERT INTO `sites` (`id`) VALUES (?)', $SITE_ID);
};

1;
