
package oyster::revisions;

unless ($just_getting_revs) {
    $oyster::DB = $DB;
    oyster::_delayed_imports();
}

# ----------------------------------------------------------------------------
# Revision 1
# ----------------------------------------------------------------------------

$revision[1]{'up'}{'shared'} = sub {

    # BBcode
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `bbcode` (
        `tag` tinytext NOT NULL,
        `xhtml_tag` tinytext NOT NULL,
        `extra` tinytext NOT NULL,
        `is_block` tinyint(1) NOT NULL default '0',
        `consume_pre_newline` tinyint(1) NOT NULL default '0',
        `consume_post_newline` tinyint(1) NOT NULL default '0', 
        `disable_paragraphs` tinyint(1) NOT NULL default '0'
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);
    $DB->query(qq~INSERT INTO `bbcode` (`tag`, `xhtml_tag`, `extra`, `is_block`, `consume_pre_newline`, `consume_post_newline`, `disable_paragraphs`) VALUES
        ('b', 'strong', '', 0, 0, 0, 0),
        ('i', 'em', '', 0, 0, 0, 0),
        ('u', 'span', ' class="underline"', 0, 0, 0, 0),
        ('s', 'del', '', 0, 0, 0, 0),
        ('img', '', '', 0, 0, 0, 0),
        ('url', 'a', '', 0, 0, 0, 0),
        ('quote', 'div', '', 1, 1, 1, 0),
        ('code', 'pre', ' class="quote"', 1, 1, 1, 0),
        ('size', '', '', 0, 0, 0, 0),
        ('color', '', '', 0, 0, 0, 0),
        ('list', '', '', 1, 1, 1, 1)~);

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
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `ipc` (
        `ctime` datetime NOT NULL default '0000-00-00 00:00:00',
        `command` tinytext NOT NULL,
        `daemon_id` char(32) NOT NULL,
        `site_id` tinytext NOT NULL,
        `task_id` varchar(32) NOT NULL,
        `id` int(11) NOT NULL auto_increment, UNIQUE KEY `id` (`id`), KEY `ctime` (`ctime`)
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1~);

    # Modules
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `modules` (
        `id` tinytext NOT NULL,
        `revision` smallint(6) NOT NULL default '0'
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);

    # Register the module
    module::register('oyster');

    # XHTML tags
    $DB->query(qq~CREATE TABLE IF NOT EXISTS `xhtml_tags` (
        `tag` tinytext NOT NULL,
        `permission_level` tinyint(1) NOT NULL default '0'
        ) ENGINE=MyISAM DEFAULT CHARSET=latin1~);
    $DB->query(qq~INSERT INTO `xhtml_tags` (`tag`, `permission_level`) VALUES
        ('p', 0),
        ('br', 0),
        ('img', 1),
        ('area', 1),
        ('map', 1),
        ('a', 1),
        ('span', 1),
        ('object', 1),
        ('param', 1),
        ('button', 1),
        ('fieldset', 1),
        ('form', 1),
        ('input', 1),
        ('label', 1),
        ('legend', 1),
        ('select', 1),
        ('optgroup', 1),
        ('option', 1),
        ('textarea', 1),
        ('sub', 1),
        ('sup', 1),
        ('strong', 1),
        ('em', 1),
        ('ins', 1),
        ('del', 1),
        ('code', 1),
        ('abbr', 1),
        ('acronym', 1),
        ('address', 1),
        ('date', 1),
        ('cite', 1),
        ('dfn', 1),
        ('kbd', 1),
        ('q', 1),
        ('samp', 1),
        ('var', 1),
        ('big', 1),
        ('small', 1),
        ('bdo', 1),
        ('ul', 2),
        ('ol', 2),
        ('li', 2),
        ('dl', 2),
        ('dt', 2),
        ('dd', 2),
        ('div', 2),
        ('h1', 2),
        ('h2', 2),
        ('h3', 2),
        ('h4', 2),
        ('h4', 2),
        ('h6', 2),
        ('blockquote', 2),
        ('blockcode', 2),
        ('caption', 2),
        ('col', 2),
        ('colgroup', 2),
        ('table', 2),
        ('tbody', 2),
        ('td', 2),
        ('tfoot', 2),
        ('th', 2),
        ('thead', 2),
        ('tr', 2);~);

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
    $DB->query(qq~INSERT INTO `${DB_PREFIX}styles` (`id`, `name`, `status`) VALUES ('bitpiston', 'BitPiston', 1)~);

    # Add site entry
    $DB->query('INSERT INTO `sites` (`id`) VALUES (?)', $SITE_ID);
};

1;
