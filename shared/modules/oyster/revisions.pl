
package oyster::revisions;

# ----------------------------------------------------------------------------
# Revision 1
# ----------------------------------------------------------------------------

$revision[1]{'up'}{'shared'} = sub {

    # Global config
    $DB->query(qq~CREATE TABLE `config` (
          `name` tinytext NOT NULL,
          `value` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);

    # Date formats
    $DB->query(qq~CREATE TABLE `date_formats` (
          `format` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8~);
    $DB->query(qq~INSERT INTO `date_formats` (`format`) VALUES
        ('%Y.%m.%d %H:%M:%S'),
        ('%e %B %Y %H:%M'),
        ('%B %e, %Y %i:%M %p')~);

    # IPC
    $DB->query(qq~CREATE TABLE `ipc` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `module` tinytext NOT NULL,
          `function` tinytext NOT NULL,
          `args` text NOT NULL,
          `daemon` char(32) NOT NULL DEFAULT '',
          `site` tinytext NOT NULL,
          UNIQUE KEY `id` (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    
    # IPC Periodic
    $DB->query(qq~CREATE TABLE `ipc_periodic` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `module` tinytext NOT NULL,
          `function` tinytext NOT NULL,
          `args` text NOT NULL,
          `daemon` char(32) NOT NULL DEFAULT '',
          `site` tinytext NOT NULL,
          `interval` int(11) NOT NULL,
          `last_exec_time` int(11) DEFAULT NULL,
          UNIQUE KEY `id` (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;~);

    # Modules
    $DB->query(qq~CREATE TABLE `modules` (
          `id` tinytext NOT NULL,
          `revision` smallint(6) NOT NULL DEFAULT '0'
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);

    # Register the module
    module::register('oyster');

    # Sites
    $DB->query(qq~CREATE TABLE `sites` (
          `id` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
};

$revision[1]{'up'}{'site'} = sub {

    # Add to module's table
    $DB->query(qq~ALTER TABLE modules ADD `site_$SITE_ID` TINYINT(1) NOT NULL default '0'~);

    # Enable the module
    module::enable('oyster');

    # Site config
    $DB->query(qq~CREATE TABLE `site_config` (
          `name` tinytext NOT NULL,
          `value` text NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    $DB->query(qq~INSERT INTO `${DB_PREFIX}config` (`name`, `value`)
        VALUES
        	('error_message','You may have just broken the internet.  '),
        	('default_url','home'),
        	('time_offset','0'),
        	('default_style','bitpiston'),
        	('site_name','BitPiston'),
        	('navigation_depth','1'),
        	('log_404s','0'),
        	('force_ssxslt','0');~);

    # Email Templates
    $DB->query(qq~CREATE TABLE `${DB_PREFIX}email_templates` (
          `name` tinytext NOT NULL,
          `type` tinytext,
          `from_address` tinytext,
          `subject` tinytext NOT NULL,
          `body` text NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);

    # Logs
    $DB->query(qq~CREATE TABLE `${DB_PREFIX}logs` (
          `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
          `type` tinytext NOT NULL,
          `time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
          `message` text NOT NULL,
          `trace` text NOT NULL,
          UNIQUE KEY `id` (`id`)
        ) ENGINE=InnoDB AUTO_INCREMENT=70 DEFAULT CHARSET=utf8;~);

    # URLs
    $DB->query(qq~CREATE TABLE `${DB_PREFIX}urls` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `parent_id` int(11) NOT NULL DEFAULT '0',
          `url` tinytext NOT NULL,
          `url_hash` varchar(10) NOT NULL DEFAULT '',
          `title` tinytext NOT NULL,
          `module` tinytext NOT NULL,
          `function` tinytext NOT NULL,
          `params` tinytext NOT NULL,
          `show_nav_link` tinyint(1) NOT NULL DEFAULT '0',
          `nav_priority` smallint(6) NOT NULL DEFAULT '0',
          `regex` tinyint(1) NOT NULL DEFAULT '0',
          UNIQUE KEY `id` (`id`),
          KEY `url_hash` (`url_hash`),
          KEY `parent_id` (`parent_id`),
          KEY `regex` (`regex`)
        ) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8;~);

    # Styles
    $DB->query(qq~CREATE TABLE `${DB_PREFIX}styles` (
          `id` tinytext NOT NULL,
          `name` tinytext NOT NULL,
          `status` tinyint(1) NOT NULL DEFAULT '1',
          `output` tinytext NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8;~);
    style::register('bitpiston', 'BitPiston');
    style::enable('bitpiston');

    # Add site entry
    $DB->query('INSERT INTO `sites` (`id`) VALUES (?)', $SITE_ID);
};

1;
