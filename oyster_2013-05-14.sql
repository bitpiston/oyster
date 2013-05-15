# ************************************************************
# Sequel Pro SQL dump
# Version 4004
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: kosh.bitpiston.com (MySQL 5.5.30-MariaDB-log)
# Database: oyster
# Generation Time: 2013-05-15 05:54:03 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table config
# ------------------------------------------------------------

DROP TABLE IF EXISTS `config`;

CREATE TABLE `config` (
  `name` tinytext NOT NULL,
  `value` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table date_formats
# ------------------------------------------------------------

DROP TABLE IF EXISTS `date_formats`;

CREATE TABLE `date_formats` (
  `format` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `date_formats` WRITE;
/*!40000 ALTER TABLE `date_formats` DISABLE KEYS */;

INSERT INTO `date_formats` (`format`)
VALUES
	('%Y.%m.%d %H:%M:%S'),
	('%e %B %Y %H:%M'),
	('%B %e, %Y %i:%M %p');

/*!40000 ALTER TABLE `date_formats` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table ipc
# ------------------------------------------------------------

DROP TABLE IF EXISTS `ipc`;

CREATE TABLE `ipc` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `module` tinytext NOT NULL,
  `function` tinytext NOT NULL,
  `args` text NOT NULL,
  `daemon` char(32) NOT NULL DEFAULT '',
  `site` tinytext NOT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table ipc_periodic
# ------------------------------------------------------------

DROP TABLE IF EXISTS `ipc_periodic`;

CREATE TABLE `ipc_periodic` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `module` tinytext NOT NULL,
  `function` tinytext NOT NULL,
  `args` text NOT NULL,
  `daemon` char(32) NOT NULL DEFAULT '',
  `site` tinytext NOT NULL,
  `interval` int(11) NOT NULL,
  `last_exec_time` int(11) DEFAULT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

LOCK TABLES `ipc_periodic` WRITE;
/*!40000 ALTER TABLE `ipc_periodic` DISABLE KEYS */;

INSERT INTO `ipc_periodic` (`id`, `module`, `function`, `args`, `daemon`, `site`, `interval`, `last_exec_time`)
VALUES
	(1,'user','_clean_sessions','','','site',900,1368596905);

/*!40000 ALTER TABLE `ipc_periodic` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table modules
# ------------------------------------------------------------

DROP TABLE IF EXISTS `modules`;

CREATE TABLE `modules` (
  `id` tinytext NOT NULL,
  `revision` smallint(6) NOT NULL DEFAULT '0',
  `site_site` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `modules` WRITE;
/*!40000 ALTER TABLE `modules` DISABLE KEYS */;

INSERT INTO `modules` (`id`, `revision`, `site_site`)
VALUES
	('oyster',1,1),
	('ssxslt',2,1),
	('user',1,1),
	('admin',2,1),
	('forums',1,0),
	('qdcontent',1,0),
	('content',1,1),
	('blog',1,0),
	('comments',1,0),
	('contact',1,0);

/*!40000 ALTER TABLE `modules` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_blog_categories
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_blog_categories`;

CREATE TABLE `site_blog_categories` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `parent_id` smallint(6) NOT NULL DEFAULT '0',
  `name` tinytext NOT NULL,
  `description` tinytext NOT NULL,
  `url` tinytext NOT NULL,
  `show_nav_link` tinyint(1) NOT NULL DEFAULT '0',
  `nav_priority` smallint(6) NOT NULL DEFAULT '0',
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

LOCK TABLES `site_blog_categories` WRITE;
/*!40000 ALTER TABLE `site_blog_categories` DISABLE KEYS */;

INSERT INTO `site_blog_categories` (`id`, `parent_id`, `name`, `description`, `url`, `show_nav_link`, `nav_priority`)
VALUES
	(1,0,'Announcements','','announcements',1,1),
	(2,0,'Test','','test',1,2);

/*!40000 ALTER TABLE `site_blog_categories` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_blog_config
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_blog_config`;

CREATE TABLE `site_blog_config` (
  `name` tinytext NOT NULL,
  `value` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_blog_config` WRITE;
/*!40000 ALTER TABLE `site_blog_config` DISABLE KEYS */;

INSERT INTO `site_blog_config` (`name`, `value`)
VALUES
	('default_category','1'),
	('enable_comments_default','0');

/*!40000 ALTER TABLE `site_blog_config` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_blog_labels
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_blog_labels`;

CREATE TABLE `site_blog_labels` (
  `id` smallint(6) NOT NULL AUTO_INCREMENT,
  `name` tinytext NOT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

LOCK TABLES `site_blog_labels` WRITE;
/*!40000 ALTER TABLE `site_blog_labels` DISABLE KEYS */;

INSERT INTO `site_blog_labels` (`id`, `name`)
VALUES
	(1,'Products'),
	(2,'Services'),
	(3,'Projects'),
	(4,'Test');

/*!40000 ALTER TABLE `site_blog_labels` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_blog_posts
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_blog_posts`;

CREATE TABLE `site_blog_posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `published` tinyint(1) NOT NULL DEFAULT '0',
  `title` tinytext NOT NULL,
  `url` tinytext NOT NULL,
  `url_hash` varchar(10) NOT NULL DEFAULT '',
  `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `cdate` date NOT NULL DEFAULT '0000-00-00',
  `author_id` int(11) NOT NULL DEFAULT '0',
  `author_name` varchar(30) NOT NULL DEFAULT '',
  `post_original` text NOT NULL,
  `post` text NOT NULL,
  `more_original` text NOT NULL,
  `more` text NOT NULL,
  `translation_mode` tinytext NOT NULL,
  `comments_node` int(11) NOT NULL DEFAULT '0',
  `comments` smallint(6) NOT NULL DEFAULT '0',
  `enable_comments` tinyint(1) NOT NULL DEFAULT '0',
  `labels` tinytext NOT NULL,
  UNIQUE KEY `id` (`id`),
  KEY `author_id` (`author_id`),
  KEY `published` (`published`),
  KEY `cdate` (`cdate`),
  KEY `url_hash` (`url_hash`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

LOCK TABLES `site_blog_posts` WRITE;
/*!40000 ALTER TABLE `site_blog_posts` DISABLE KEYS */;

INSERT INTO `site_blog_posts` (`id`, `published`, `title`, `url`, `url_hash`, `ctime`, `cdate`, `author_id`, `author_name`, `post_original`, `post`, `more_original`, `more`, `translation_mode`, `comments_node`, `comments`, `enable_comments`, `labels`)
VALUES
	(1,1,'Nullam at Tortor id Nibh Luctus Pulvinar','nullam_at_tortor_id_nibh_luctus_pulvinar','3943813008','2006-12-16 05:30:25','2006-12-16',5,'Jan','Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Donec fringilla. Morbi id nulla eu erat hendrerit pellentesque. Sed vitae arcu. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed ac enim. Proin nec dolor eu purus posuere elementum. Curabitur dignissim dui in pede. Nunc dapibus.\n\nMorbi quis orci et justo laoreet congue. Aenean ac eros sed tellus fermentum tristique. Fusce lectus diam, feugiat quis, sollicitudin non, vehicula non, ligula. Curabitur nisi orci, vestibulum nec, aliquet in, laoreet viverra, diam. Fusce mauris felis, imperdiet non, tincidunt at, volutpat sit amet, turpis. Cras ullamcorper. Duis id lorem a eros lacinia venenatis. Donec euismod sem auctor dolor. Suspendisse dignissim, orci ac pellentesque dignissim, urna lorem adipiscing enim, vitae pellentesque erat augue sit amet lectus. Fusce tortor.','<p>Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Donec fringilla. Morbi id nulla eu erat hendrerit pellentesque. Sed vitae arcu. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Sed ac enim. Proin nec dolor eu purus posuere elementum. Curabitur dignissim dui in pede. Nunc dapibus.</p><p>Morbi quis orci et justo laoreet congue. Aenean ac eros sed tellus fermentum tristique. Fusce lectus diam, feugiat quis, sollicitudin non, vehicula non, ligula. Curabitur nisi orci, vestibulum nec, aliquet in, laoreet viverra, diam. Fusce mauris felis, imperdiet non, tincidunt at, volutpat sit amet, turpis. Cras ullamcorper. Duis id lorem a eros lacinia venenatis. Donec euismod sem auctor dolor. Suspendisse dignissim, orci ac pellentesque dignissim, urna lorem adipiscing enim, vitae pellentesque erat augue sit amet lectus. Fusce tortor.</p>','','','bbcode',7,2,0,'4,2'),
	(2,1,'Fermentum Tristique','fermentum_tristique','865598219','2006-12-17 18:35:44','2006-12-17',5,'Nic','Fusce mauris felis, imperdiet non, tincidunt at, volutpat sit amet, turpis. Cras ullamcorper. Duis id lorem a eros lacinia venenatis. Donec euismod sem auctor dolor. Suspendisse dignissim, orci ac pellentesque dignissim, urna lorem adipiscing enim, vitae pellentesque erat augue sit amet lectus.','<p>Fusce mauris felis, imperdiet non, tincidunt at, volutpat sit amet, turpis. Cras ullamcorper. Duis id lorem a eros lacinia venenatis. Donec euismod sem auctor dolor. Suspendisse dignissim, orci ac pellentesque dignissim, urna lorem adipiscing enim, vitae pellentesque erat augue sit amet lectus.</p>','','','bbcode',8,0,0,'4'),
	(3,1,'Lorem Ipsum','lorem_ipsum','790940489','2006-12-17 18:43:24','2006-12-17',5,'Jan','Etiam sapien. Suspendisse vel nunc. Ut vestibulum. Aenean augue lectus, accumsan sed, gravida ut, eleifend sit amet, ipsum. Etiam mattis condimentum sapien. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. \n\nDonec aliquet. Quisque commodo. Maecenas sed velit non turpis pretium rutrum. Integer ac purus. Vivamus pulvinar velit in quam mattis aliquam. Suspendisse vehicula lacus vitae quam. Duis consectetuer sagittis ipsum. Phasellus sollicitudin elit eu lorem. Cras semper venenatis mi.','<p>Etiam sapien. Suspendisse vel nunc. Ut vestibulum. Aenean augue lectus, accumsan sed, gravida ut, eleifend sit amet, ipsum. Etiam mattis condimentum sapien. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. </p><p>Donec aliquet. Quisque commodo. Maecenas sed velit non turpis pretium rutrum. Integer ac purus. Vivamus pulvinar velit in quam mattis aliquam. Suspendisse vehicula lacus vitae quam. Duis consectetuer sagittis ipsum. Phasellus sollicitudin elit eu lorem. Cras semper venenatis mi.</p>','Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. In eget leo eu dolor lacinia fermentum. Nunc accumsan facilisis dolor. Nunc iaculis. Aliquam a dui et nisi laoreet placerat. Pellentesque viverra. Cras malesuada. Phasellus viverra, mi tempus aliquam pretium, urna metus congue mauris, sit amet accumsan pede odio nec erat. Sed at massa et lorem mattis dignissim. \n\nAliquam vitae sem. Nam luctus eros in massa. Mauris laoreet, nisi volutpat varius tempus, dui sapien aliquet dui, eget suscipit leo mi in pede. Vivamus enim massa, nonummy ut, pellentesque ut, convallis consectetuer, lectus. Integer auctor nunc et est. Curabitur non felis id nibh congue condimentum. Vivamus semper purus in lorem. Ut pharetra facilisis metus. Integer vitae felis. Nunc convallis cursus ipsum.','<p>Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. In eget leo eu dolor lacinia fermentum. Nunc accumsan facilisis dolor. Nunc iaculis. Aliquam a dui et nisi laoreet placerat. Pellentesque viverra. Cras malesuada. Phasellus viverra, mi tempus aliquam pretium, urna metus congue mauris, sit amet accumsan pede odio nec erat. Sed at massa et lorem mattis dignissim. </p><p>Aliquam vitae sem. Nam luctus eros in massa. Mauris laoreet, nisi volutpat varius tempus, dui sapien aliquet dui, eget suscipit leo mi in pede. Vivamus enim massa, nonummy ut, pellentesque ut, convallis consectetuer, lectus. Integer auctor nunc et est. Curabitur non felis id nibh congue condimentum. Vivamus semper purus in lorem. Ut pharetra facilisis metus. Integer vitae felis. Nunc convallis cursus ipsum.</p>','bbcode',9,3,0,'1,3,2');

/*!40000 ALTER TABLE `site_blog_posts` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_config
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_config`;

CREATE TABLE `site_config` (
  `name` tinytext NOT NULL,
  `value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_config` WRITE;
/*!40000 ALTER TABLE `site_config` DISABLE KEYS */;

INSERT INTO `site_config` (`name`, `value`)
VALUES
	('error_message','You may have just broken the internet.  '),
	('default_url','home'),
	('time_offset','0'),
	('default_style','bitpiston'),
	('site_name','BitPiston'),
	('navigation_depth','1'),
	('log_404s','0'),
	('force_ssxslt','0'),
	('','');

/*!40000 ALTER TABLE `site_config` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_content_config
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_content_config`;

CREATE TABLE `site_content_config` (
  `name` tinytext NOT NULL,
  `value` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_content_config` WRITE;
/*!40000 ALTER TABLE `site_content_config` DISABLE KEYS */;

INSERT INTO `site_content_config` (`name`, `value`)
VALUES
	('subpage_depth','1'),
	('num_revisions','30');

/*!40000 ALTER TABLE `site_content_config` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_content_page_field_history
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_content_page_field_history`;

CREATE TABLE `site_content_page_field_history` (
  `revision_id` bigint(20) NOT NULL DEFAULT '0',
  `page_id` tinytext NOT NULL,
  `data` tinytext NOT NULL,
  `name` tinytext NOT NULL,
  `type` tinytext NOT NULL,
  `translation_mode` tinytext NOT NULL,
  `value` text NOT NULL,
  `translated_value` text NOT NULL,
  `call_data` text NOT NULL,
  `inside_content_node` tinyint(1) NOT NULL DEFAULT '0',
  KEY `revision_id` (`revision_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table site_content_page_fields
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_content_page_fields`;

CREATE TABLE `site_content_page_fields` (
  `page_id` int(11) NOT NULL DEFAULT '0',
  `data` text NOT NULL,
  `name` tinytext NOT NULL,
  `type` tinytext NOT NULL,
  `translation_mode` tinytext NOT NULL,
  `value` text NOT NULL,
  `translated_value` text NOT NULL,
  `call_data` text NOT NULL,
  `inside_content_node` tinyint(1) NOT NULL DEFAULT '1',
  KEY `page_id` (`page_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_content_page_fields` WRITE;
/*!40000 ALTER TABLE `site_content_page_fields` DISABLE KEYS */;

INSERT INTO `site_content_page_fields` (`page_id`, `data`, `name`, `type`, `translation_mode`, `value`, `translated_value`, `call_data`, `inside_content_node`)
VALUES
	(1,'','body','textarea','xhtml','','','',1),
	(1,'','sidebar','textarea','xhtml','','','',1);

/*!40000 ALTER TABLE `site_content_page_fields` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_content_page_revisions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_content_page_revisions`;

CREATE TABLE `site_content_page_revisions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `page_id` int(11) NOT NULL DEFAULT '0',
  `mtime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `title` tinytext NOT NULL,
  `author_id` int(11) NOT NULL DEFAULT '0',
  `author_name` varchar(30) NOT NULL DEFAULT '',
  UNIQUE KEY `id` (`id`),
  KEY `page_id` (`page_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table site_content_pages
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_content_pages`;

CREATE TABLE `site_content_pages` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) unsigned NOT NULL DEFAULT '0',
  `title` tinytext NOT NULL,
  `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `mtime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `author_id` int(11) unsigned NOT NULL DEFAULT '0',
  `url_hash` varchar(10) NOT NULL DEFAULT '',
  `nav_title` tinytext NOT NULL,
  `slug` tinytext NOT NULL,
  UNIQUE KEY `id` (`id`),
  KEY `parent_id` (`parent_id`,`url_hash`),
  KEY `url_hash` (`url_hash`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

LOCK TABLES `site_content_pages` WRITE;
/*!40000 ALTER TABLE `site_content_pages` DISABLE KEYS */;

INSERT INTO `site_content_pages` (`id`, `parent_id`, `title`, `ctime`, `mtime`, `author_id`, `url_hash`, `nav_title`, `slug`)
VALUES
	(1,0,'Home','2011-09-16 23:26:00','2011-09-16 23:26:00',1,'3306266643','','');

/*!40000 ALTER TABLE `site_content_pages` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_content_templates
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_content_templates`;

CREATE TABLE `site_content_templates` (
  `id` tinyint(4) NOT NULL DEFAULT '0',
  `name` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_content_templates` WRITE;
/*!40000 ALTER TABLE `site_content_templates` DISABLE KEYS */;

INSERT INTO `site_content_templates` (`id`, `name`)
VALUES
	(1,'Default Content Page');

/*!40000 ALTER TABLE `site_content_templates` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_email_templates
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_email_templates`;

CREATE TABLE `site_email_templates` (
  `name` tinytext NOT NULL,
  `type` tinytext,
  `from_address` tinytext,
  `subject` tinytext NOT NULL,
  `body` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_email_templates` WRITE;
/*!40000 ALTER TABLE `site_email_templates` DISABLE KEYS */;

INSERT INTO `site_email_templates` (`name`, `type`, `from_address`, `subject`, `body`)
VALUES
	('user_registration','text',NULL,'Welcome to {site_name}','Blah blah blah..\\r\\n\\r\\n{confirm_url}'),
	('user_change_email','text',NULL,'Confirm Email Address Change ({site_name})','Visit the address below to change your email address to \"{new_email}\" on the account \"{username}\":\\r\\n\\r\\n{confirm_url}'),
	('user_recover_account','text',NULL,'Account Recovery ({site_name})','Visit the address below to change your password to \"{new_pass}\" on the account \"{username}\":\\r\\n\\r\\n{confirm_url}\\r\\n'),
	('forums_notify','text',NULL,'Forum reply notification: {thread_title}','Hello {username}, You are receiving this notification because you are watching the topic, \"{thread_title}\" at {site_name}. This topic has received a reply since your last visit. You can use the following link to view the replies made, no more notifications will be sent until you visit the topic. {post_url} If you no longer wish to watch this topic you can click the \"Unsubscribe topic\" link found at the bottom of the topic above.');

/*!40000 ALTER TABLE `site_email_templates` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_logs
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_logs`;

CREATE TABLE `site_logs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `type` tinytext NOT NULL,
  `time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `message` text NOT NULL,
  `trace` text NOT NULL,
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=70 DEFAULT CHARSET=utf8;



# Dump of table site_styles
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_styles`;

CREATE TABLE `site_styles` (
  `id` tinytext NOT NULL,
  `name` tinytext NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `output` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_styles` WRITE;
/*!40000 ALTER TABLE `site_styles` DISABLE KEYS */;

INSERT INTO `site_styles` (`id`, `name`, `status`, `output`)
VALUES
	('bitpiston','BitPiston',1,'html');

/*!40000 ALTER TABLE `site_styles` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_urls
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_urls`;

CREATE TABLE `site_urls` (
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
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8;

LOCK TABLES `site_urls` WRITE;
/*!40000 ALTER TABLE `site_urls` DISABLE KEYS */;

INSERT INTO `site_urls` (`id`, `parent_id`, `url`, `url_hash`, `title`, `module`, `function`, `params`, `show_nav_link`, `nav_priority`, `regex`)
VALUES
	(1,0,'login','1523335517','Log In','user','login','',0,0,0),
	(2,0,'logout','2568911212','Log Out','user','logout','',0,0,0),
	(3,0,'register','3524755762','Register Account','user','register','',0,0,0),
	(4,-1,'admin/user','1528730671','User Administration','user','admin','',0,0,0),
	(5,-1,'user/confirm','216425727','Confirm Account','user','confirm_account','',0,0,0),
	(6,-1,'user/recover','3378436221','Recover Account','user','recover','',0,0,0),
	(7,-1,'user/settings','914524209','Edit User Settings','user','edit_settings','',0,0,0),
	(8,4,'admin/user/manage','3018394371','Manage Users','user','admin_manage','',0,0,0),
	(9,4,'admin/user/config','394334808','User Configuration','user','admin_config','',0,0,0),
	(10,4,'admin/user/groups','350737716','Manage User Groups','user','admin_groups','',0,0,0),
	(11,-1,'user/confirm_email','568716421','Confirm Email Change','user','confirm_email','',0,0,0),
	(12,10,'admin/user/groups/edit','3775673877','Edit a User Group','user','admin_edit_group','',0,0,0),
	(13,10,'admin/user/groups/create','2670352510','Create a User Group','user','admin_create_group','',0,0,0),
	(14,10,'admin/user/groups/delete','4069683626','Delete a User Group','user','admin_delete_group','',0,0,0),
	(15,0,'admin','2364429183','Administration Center','admin','menu','',0,0,0),
	(16,15,'admin/modules','2234665152','Manage Modules','admin','modules','',0,0,0),
	(17,15,'admin/config','791050580','Configuration','admin','config','',0,0,0),
	(18,17,'admin/config/navigation','852919525','Configure Navigation','admin','config_navigation','',0,0,0),
	(19,15,'admin/logs','2240523991','Logs','admin','logs','',0,0,0),
	(20,15,'admin/styles','2211067090','Manage Styles','admin','styles','',0,0,0),
	(21,15,'admin/qdcontent','3630607284','','qdcontent','admin','',0,0,0),
	(22,47,'admin/content/config','2610031277','Content Configuration','content','admin_config','',0,0,0),
	(23,15,'admin/content','2326970239','Content Administration','content','admin','',0,0,0),
	(24,0,'blog/(\\d{4})/(\\d{2})/(\\d{2})/(.+)','','','blog\n','view_post','',0,0,1),
	(25,0,'blog','4075756216','Weblog','blog','view_index','',0,6,0),
	(26,0,'home','3306266643','Home','content','view_page','',0,0,0),
	(27,0,'contact','886164247','Contact','contact','contact_form','',1,5,0);

/*!40000 ALTER TABLE `site_urls` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_user_config
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_user_config`;

CREATE TABLE `site_user_config` (
  `name` tinytext NOT NULL,
  `value` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_user_config` WRITE;
/*!40000 ALTER TABLE `site_user_config` DISABLE KEYS */;

INSERT INTO `site_user_config` (`name`, `value`)
VALUES
	('default_name','Guest'),
	('cookie_path','/'),
	('cookie_domain',''),
	('default_group','2'),
	('guest_group','1'),
	('enable_registration','1'),
	('customizable_styles','1'),
	('enable_geoip','0');

/*!40000 ALTER TABLE `site_user_config` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_user_groups
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_user_groups`;

CREATE TABLE `site_user_groups` (
  `id` tinyint(4) NOT NULL AUTO_INCREMENT,
  `name` tinytext NOT NULL,
  `user_admin_config` tinyint(1) NOT NULL DEFAULT '0',
  `user_admin_groups` tinyint(1) NOT NULL DEFAULT '0',
  `user_admin_manage` tinyint(1) NOT NULL DEFAULT '0',
  `admin_config` tinyint(1) NOT NULL DEFAULT '0',
  `admin_modules` tinyint(1) NOT NULL DEFAULT '0',
  `admin_styles` tinyint(1) NOT NULL DEFAULT '0',
  `admin_logs` tinyint(1) NOT NULL DEFAULT '0',
  `qdcontent_admin` tinyint(1) NOT NULL DEFAULT '0',
  `forums_admin` tinyint(1) NOT NULL DEFAULT '0',
  `forums_admin_config` tinyint(1) NOT NULL DEFAULT '0',
  `forums_view` tinyint(1) NOT NULL DEFAULT '0',
  `forums_create_forums` tinyint(1) NOT NULL DEFAULT '0',
  `forums_edit_forums` tinyint(1) NOT NULL DEFAULT '0',
  `forums_delete_forums` tinyint(1) NOT NULL DEFAULT '0',
  `forums_create_threads` tinyint(1) NOT NULL DEFAULT '0',
  `forums_delete_threads` tinyint(1) NOT NULL DEFAULT '0',
  `forums_create_posts` tinyint(1) NOT NULL DEFAULT '0',
  `forums_edit_posts` tinyint(1) NOT NULL DEFAULT '0',
  `forums_delete_posts` tinyint(1) NOT NULL DEFAULT '0',
  `forums_move` tinyint(1) NOT NULL DEFAULT '0',
  `forums_merge` tinyint(1) NOT NULL DEFAULT '0',
  `forums_split` tinyint(1) NOT NULL DEFAULT '0',
  `forums_announce` tinyint(1) NOT NULL DEFAULT '0',
  `forums_sticky` tinyint(1) NOT NULL DEFAULT '0',
  `forums_lock` tinyint(1) NOT NULL DEFAULT '0',
  `forums_edit_threads` tinyint(1) NOT NULL DEFAULT '0',
  `content_create` tinyint(1) NOT NULL DEFAULT '0',
  `content_edit` tinyint(1) NOT NULL DEFAULT '0',
  `content_delete` tinyint(1) NOT NULL DEFAULT '0',
  `content_admin` tinyint(1) NOT NULL DEFAULT '0',
  `content_admin_config` tinyint(1) NOT NULL DEFAULT '0',
  `content_templates` tinyint(1) NOT NULL DEFAULT '0',
  `content_revisions` tinyint(1) NOT NULL DEFAULT '0',
  UNIQUE KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

LOCK TABLES `site_user_groups` WRITE;
/*!40000 ALTER TABLE `site_user_groups` DISABLE KEYS */;

INSERT INTO `site_user_groups` (`id`, `name`, `user_admin_config`, `user_admin_groups`, `user_admin_manage`, `admin_config`, `admin_modules`, `admin_styles`, `admin_logs`, `qdcontent_admin`, `forums_admin`, `forums_admin_config`, `forums_view`, `forums_create_forums`, `forums_edit_forums`, `forums_delete_forums`, `forums_create_threads`, `forums_delete_threads`, `forums_create_posts`, `forums_edit_posts`, `forums_delete_posts`, `forums_move`, `forums_merge`, `forums_split`, `forums_announce`, `forums_sticky`, `forums_lock`, `forums_edit_threads`, `content_create`, `content_edit`, `content_delete`, `content_admin`, `content_admin_config`, `content_templates`, `content_revisions`)
VALUES
	(1,'Guest',0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
	(2,'Registered',0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
	(3,'Moderator',0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,2,1,2,2,1,1,1,1,1,1,1,0,0,0,0,0,0,0),
	(4,'Administrator',1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,2,2,1,1,1,1,1,1,1,0,0,0,0,0,0,0),
	(5,'Banned',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

/*!40000 ALTER TABLE `site_user_groups` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table site_user_permissions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_user_permissions`;

CREATE TABLE `site_user_permissions` (
  `user_id` int(11) NOT NULL DEFAULT '0',
  `group_id` tinyint(4) NOT NULL DEFAULT '0',
  UNIQUE KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table site_user_sessions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `site_user_sessions`;

CREATE TABLE `site_user_sessions` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `site_user_sessions` WRITE;
/*!40000 ALTER TABLE `site_user_sessions` DISABLE KEYS */;

INSERT INTO `site_user_sessions` (`session_id`, `user_id`, `ip`, `access_ctime`, `restrict_ip`, `geoip_country`, `geoip_region`, `geoip_city`)
VALUES
	('0jrNXbfUh6z0CHQbYXF79zIHCFFMADW8',0,'127.0.0.1',1368544105,1,NULL,NULL,NULL),
	('0wWctFiultWwSR2DIhoTpgkM8b6qDswC',0,'127.0.0.1',1368531035,1,NULL,NULL,NULL),
	('1OHLmYK2iNiNdsHetY1d4G0QiCXX5rdv',0,'127.0.0.1',1368550826,1,NULL,NULL,NULL),
	('1qIhWY9rsAE6qpc5zntMzQHkiOWu94L2',0,'127.0.0.1',1368584425,1,NULL,NULL,NULL),
	('1tXJqZ5R6sXNav8vR4KoSY2eGMHpKXTc',0,'127.0.0.1',1368572905,1,NULL,NULL,NULL),
	('1tYqXx7atda22uiAAALyOoFf8UhbG1pQ',0,'127.0.0.1',1368525602,1,NULL,NULL,NULL),
	('23kNAC5uxPpa8vJG1J1jxR6QY9O146gn',0,'127.0.0.1',1368574762,1,NULL,NULL,NULL),
	('23XcBwCBeqHs9ATmilXOVu7XvLPbBKR6',0,'127.0.0.1',1368566185,1,NULL,NULL,NULL),
	('2KjwJMtxLVPEsWfXOyaiDYyAOxRmR1KZ',0,'127.0.0.1',1368580225,1,NULL,NULL,NULL),
	('2WauG3LC6Zdq5SASSkNkBbMIXqPyWsYw',0,'127.0.0.1',1368518259,1,NULL,NULL,NULL),
	('3DlwdBasn2hqmNhv2kO2r0QLjpPPC4T1',0,'127.0.0.1',1368541953,1,NULL,NULL,NULL),
	('3k7AQ1pTXYAWohh7ysDilYHtagpw8YcA',0,'127.0.0.1',1368546025,1,NULL,NULL,NULL),
	('3pFiif2kFjU2hJI22ZtoumWBDZyqLTsp',0,'127.0.0.1',1368569274,1,NULL,NULL,NULL),
	('4AKoWcZhTik2LDz1eJSXn5MOLcBq0oXM',0,'127.0.0.1',1368532844,1,NULL,NULL,NULL),
	('4G8UZfG7rHBZOoegawwTIe91MtGIIruP',0,'127.0.0.1',1368571094,1,NULL,NULL,NULL),
	('4I8iRY2VIPbqYr64OmdiJQNJ9kfaQhBt',0,'127.0.0.1',1368558505,1,NULL,NULL,NULL),
	('4lM8OUCg5rxwz2CoTBTNqmh6nXpv3iS8',0,'127.0.0.1',1368551063,1,NULL,NULL,NULL),
	('54RacFwKgJHXA6VaYdHHsxw7iuqAD1FA',0,'127.0.0.1',1368588265,1,NULL,NULL,NULL),
	('5yiMAykg5w0iU9zOGMsjHM4v1OVy4Ws7',0,'127.0.0.1',1368531625,1,NULL,NULL,NULL),
	('6N75upb0gLmrKBEOesrXFVhsYJa6u6FY',0,'127.0.0.1',1368587539,1,NULL,NULL,NULL),
	('7tlzkZUlmpMfNBYwfvzRGgEgwNn0ls3g',0,'127.0.0.1',1368525597,1,NULL,NULL,NULL),
	('7WJBfVR1gMW06JhJfdatYSZuKZMY0XBw',0,'127.0.0.1',1368561977,1,NULL,NULL,NULL),
	('8a2NbugaM94tLJM3ksh1ROjrocAMwN4L',0,'127.0.0.1',1368549244,1,NULL,NULL,NULL),
	('8IgP1hYwy6iC52pEPpWsMbfybKQeUfVy',0,'127.0.0.1',1368585718,1,NULL,NULL,NULL),
	('8NLJDscfWHUDyGJLv1UXPZHIqoZTabls',0,'127.0.0.1',1368536487,1,NULL,NULL,NULL),
	('8sfYvdhTXeEqd33OCkCXO25IfyALCs7a',0,'127.0.0.1',1368528745,1,NULL,NULL,NULL),
	('8Wvua9WTQVczlKUDIpuZGLQ4Zortvgaw',0,'127.0.0.1',1368591168,1,NULL,NULL,NULL),
	('A0EcqzDJIWyAAgZ7EdqrxoENaAKvbvzS',0,'127.0.0.1',1368563791,1,NULL,NULL,NULL),
	('a9RFcPNUoHneqgIMiVQx5i0Bptx0KY5S',0,'127.0.0.1',1368542185,1,NULL,NULL,NULL),
	('Aj50Ph4nvnebyNRG0RGK3VtUqE2E6cub',0,'127.0.0.1',1368526825,1,NULL,NULL,NULL),
	('AjCPO4kYe21CDf6NP6wzA4uXRhQB5AtT',0,'127.0.0.1',1368522054,1,NULL,NULL,NULL),
	('aRgmTnHVpK9Azi2blZJhwnW1tCHAqSMY',0,'127.0.0.1',1368516265,1,NULL,NULL,NULL),
	('AT1ebh4ac8EsxcJ3nPrCs27c4xPDLT4W',0,'127.0.0.1',1368585722,1,NULL,NULL,NULL),
	('AvitFfCUiyqkAkLfRDxC44vHpyRpwPvL',0,'127.0.0.1',1368576581,1,NULL,NULL,NULL),
	('avWBBfUsjitCYLpAgkfOiRnQ17qnSz3m',0,'127.0.0.1',1368556585,1,NULL,NULL,NULL),
	('axh2uUdCxuXBAPoj5cFOL6Je0LfjQdXa',0,'127.0.0.1',1368532848,1,NULL,NULL,NULL),
	('B6LU9Wx3B3K26Aq4y5HqRYjH4shBPy7M',0,'127.0.0.1',1368548905,1,NULL,NULL,NULL),
	('BC0VFKHWPeIw4c0JVtNHW6eAU8uv1l4I',0,'127.0.0.1',1368587306,1,NULL,NULL,NULL),
	('Bfw7XrpeiZKejqvrHpQszWKt09HskMl6',0,'127.0.0.1',1368560162,1,NULL,NULL,NULL),
	('BKgnyfxwDFaaJZIuURZcZRa48s4Oacb9',0,'127.0.0.1',1368514615,1,NULL,NULL,NULL),
	('blh3WfYPJUZ3kYFJ6kZjFQqZTo9sVtQK',0,'127.0.0.1',1368535466,1,NULL,NULL,NULL),
	('bm2QyzfwnDuvK7okL6KrktOLVEWnA7h3',0,'127.0.0.1',1368538312,1,NULL,NULL,NULL),
	('BNDdiZf5bqjwLdM5QQRMRyY15NHYIbtx',0,'127.0.0.1',1368520110,1,NULL,NULL,NULL),
	('bSKkfePei1iWBwsBQzUNlVGQsf0yJZoB',0,'127.0.0.1',1368514346,1,NULL,NULL,NULL),
	('bWL4oI6LU7TX3LcB2Ka29sjVXf8OVjVA',0,'127.0.0.1',1368589358,1,NULL,NULL,NULL),
	('C0UssBrP8CNAbW5d4C5RrCsC7W3h4c3f',0,'127.0.0.1',1368543773,1,NULL,NULL,NULL),
	('CGUHkbaXd2ZUVeXfavY2Yw8VPc0OVCgE',0,'127.0.0.1',1368521932,1,NULL,NULL,NULL),
	('ChisFtE7XRYLUNQrXdHYVv6ggnpO9UUo',0,'127.0.0.1',1368523769,1,NULL,NULL,NULL),
	('ckuPagR5GZhsi9hui0jqZScmZNhnByIp',0,'127.0.0.1',1368555625,1,NULL,NULL,NULL),
	('crKIZ5BjVf6CpgqpZupVPygbXYxdPkxQ',0,'127.0.0.1',1368594794,1,NULL,NULL,NULL),
	('CTKN2mDxHbICumOE7oxLhlYvYE7hnKrG',0,'127.0.0.1',1368574757,1,NULL,NULL,NULL),
	('cXkeICRJ21wy2Sk3vHJW4N5JlXSvKlqB',0,'127.0.0.1',1368552745,1,NULL,NULL,NULL),
	('cy48rjfIRnv47unsNk1uAIF6ZzKqa2gk',0,'127.0.0.1',1368552879,1,NULL,NULL,NULL),
	('d9J37z8WyMgp8wzA7ZNfhD3ZiiboPlvd',0,'127.0.0.1',1368545600,1,NULL,NULL,NULL),
	('dES74uF3uXCu23tiNHSMPHW3I8Ytzqsf',0,'127.0.0.1',1368536427,1,NULL,NULL,NULL),
	('dprWOk3tG6iZmQ1NyeGxk4Xo6shzZGn7',0,'127.0.0.1',1368547428,1,NULL,NULL,NULL),
	('dSvkj5Gzbs7PxbSMR7p3AJfpyc7HPc0o',0,'127.0.0.1',1368524906,1,NULL,NULL,NULL),
	('dVtUAxUSwA2afPZKCxbSMCYqMZDmE5IQ',0,'127.0.0.1',1368536491,1,NULL,NULL,NULL),
	('ea1ORAPoV1iuygcxXarIOZCOhbIcaFcq',0,'127.0.0.1',1368543778,1,NULL,NULL,NULL),
	('eBK7F5f5g8Ho9d0pKyPJ58MQdxHUT34o',0,'127.0.0.1',1368540132,1,NULL,NULL,NULL),
	('eKgaXmtA0hA4JwmsbLgWk2zF0CVjyUZR',0,'127.0.0.1',1368594025,1,NULL,NULL,NULL),
	('enwvb9yTFvSwUYoBSxJuKPx7tkcUiNmu',0,'127.0.0.1',1368545605,1,NULL,NULL,NULL),
	('erINinO7DhuqlLt0n5gpoeZsd0kisIXO',0,'127.0.0.1',1368594984,1,NULL,NULL,NULL),
	('EVRhtN5iPcB4NHjTtURd3Vr8XSejRcwM',0,'127.0.0.1',1368523773,1,NULL,NULL,NULL),
	('F1YDdOrUyLB9ppYL3EkVGoMhv67temES',0,'127.0.0.1',1368538308,1,NULL,NULL,NULL),
	('fc6uPrngtSC9ZorwjYJmwze8Xh07uoTZ',0,'127.0.0.1',1368568105,1,NULL,NULL,NULL),
	('FpSKCwFbDYXgXN1KVDcaE2oEBgwLMI0K',0,'127.0.0.1',1368523946,1,NULL,NULL,NULL),
	('g7HNnJLePCg8bXvOegbGvFnFtEbZFcTh',0,'127.0.0.1',1368546985,1,NULL,NULL,NULL),
	('gisnnHwEUNa3khEZvlnmbKXWTboSneJy',0,'127.0.0.1',1368540136,1,NULL,NULL,NULL),
	('gRLcEz7FYazWXifkI8KY4qZq1fwTnYAH',0,'127.0.0.1',1368553705,1,NULL,NULL,NULL),
	('GV1NAKAQc01TXPW3pPbmyKTg2qI8BKuf',0,'127.0.0.1',1368569270,1,NULL,NULL,NULL),
	('h4oqFEMFuhYZ89myd588EqHQdElDtKam',0,'127.0.0.1',1368579625,1,NULL,NULL,NULL),
	('hYQZ1vCWKk7nClqEgNF9F2a4bdXsBjvA',0,'127.0.0.1',1368578664,1,NULL,NULL,NULL),
	('hZW8o3bgOWLxp879lwUIlul9aocSYx0m',0,'127.0.0.1',1368528202,1,NULL,NULL,NULL),
	('I8P8VP8wTIEZIrCxip2X8RN60fUUVyk7',0,'127.0.0.1',1368512426,1,NULL,NULL,NULL),
	('Id1CqyYURfrkgvIBJbt2fkC9E6AriOw4',0,'127.0.0.1',1368554694,1,NULL,NULL,NULL),
	('iJ9uxAaYzoTx9JD3ZVvr4pB7KUPIYGmF',0,'127.0.0.1',1368516437,1,NULL,NULL,NULL),
	('iyPnYQqe7guGNbVEUezOTO55mPEDKh1I',0,'127.0.0.1',1368592105,1,NULL,NULL,NULL),
	('J1orVLxINdLiVFbVd5Zam3Aa9WcBNApb',0,'127.0.0.1',1368512800,1,NULL,NULL,NULL),
	('JAzKkNNw1iGGvO4yiznZDqmBU5kiFukv',0,'127.0.0.1',1368539306,1,NULL,NULL,NULL),
	('jDd4AHlHnXGxGF7lVYu3StopUD8ovz89',0,'127.0.0.1',1368570985,1,NULL,NULL,NULL),
	('jDF9OwT53pPFOjIiGY2M2m2v9oMO15Nm',0,'127.0.0.1',1368529705,1,NULL,NULL,NULL),
	('JERjBSYGUqZgKAtXxqUtOvZITIOvY302',0,'127.0.0.1',1368575785,1,NULL,NULL,NULL),
	('JfBWZjnqSZK77jI7QYXyC6Gwzxf6ukOT',0,'127.0.0.1',1368574825,1,NULL,NULL,NULL),
	('JK7b1mvr1fDVStvlnOWEU7Co1E45zmOf',0,'127.0.0.1',1368525867,1,NULL,NULL,NULL),
	('Jp5wKtUeYEtW0IpZAaDGGFkf8gPL11RB',0,'127.0.0.1',1368561385,1,NULL,NULL,NULL),
	('JTbb5zKTUmP2Io0Hyf6NLO9vTCPYM7dY',0,'127.0.0.1',1368527414,1,NULL,NULL,NULL),
	('juRdIXTzCKvIPIjxVNQVtESDEKzEeDLr',0,'127.0.0.1',1368596904,1,NULL,NULL,NULL),
	('JzOIe6B3ZcLY3mxVYP2CFxvdUGpssOsj',0,'127.0.0.1',1368583898,1,NULL,NULL,NULL),
	('k7hheIBvCXcaEdo21xakDseKLHPekRkf',0,'127.0.0.1',1368565227,1,NULL,NULL,NULL),
	('keLne8p7SclhDOMQLVSK9CU7pxKSy4CR',0,'127.0.0.1',1368567433,1,NULL,NULL,NULL),
	('kj3InZIB9QA2lTzGIGrh24y1B58md7mP',0,'127.0.0.1',1368563305,1,NULL,NULL,NULL),
	('KYthMyQ4eT4YF4feSxmvwHeoflbcaOeb',0,'127.0.0.1',1368589354,1,NULL,NULL,NULL),
	('l1UVVLYbtBiNdbfcwpdTBckhkfQ56UAe',0,'127.0.0.1',1368569065,1,NULL,NULL,NULL),
	('l2rGv67Vximc10PJFnKE0zaDI9VGu6Q2',0,'127.0.0.1',1368514619,1,NULL,NULL,NULL),
	('LjUNWXbPcCtRIfCEjHV0JZpHWjOz7HeG',0,'127.0.0.1',1368586345,1,NULL,NULL,NULL),
	('Logfzb8uC6cqQeJ5j6mhzZnTyXOvlDUt',0,'127.0.0.1',1368554666,1,NULL,NULL,NULL),
	('lwMVMS7s5Hdma57BHkBB94LPmaUDoC5Y',0,'127.0.0.1',1368527418,1,NULL,NULL,NULL),
	('mfCQlOiCMVYhZH5DOUh7HI7EiAZLm6Er',0,'127.0.0.1',1368565612,1,NULL,NULL,NULL),
	('MILEvY9o3YViQIoZILmmAPk8Or0MbJHV',0,'127.0.0.1',1368551603,1,NULL,NULL,NULL),
	('MLp2meJ3NqOO5rOTQDvHqYsyHAO2JdtV',0,'127.0.0.1',1368532586,1,NULL,NULL,NULL),
	('MQjs9gwDCvlyMCtlLTZ3wc54sFFEFFt1',0,'127.0.0.1',1368515306,1,NULL,NULL,NULL),
	('MUb5i10Gtd6UlteGUMBKSF5pBfr42ZOk',0,'127.0.0.1',1368567429,1,NULL,NULL,NULL),
	('MVYNZKhNXvkYBsM4DrCCaY3ynENDEOov',0,'127.0.0.1',1368513387,1,NULL,NULL,NULL),
	('N2mQXbntpPXYYveZdI8eYYZr1VtKgcoL',0,'127.0.0.1',1368547945,1,NULL,NULL,NULL),
	('n39cZ2vv2ZYPE5oxaynjY4iJJ8KxKauH',0,'127.0.0.1',1368519147,1,NULL,NULL,NULL),
	('n65ERX2kdvThRDx9DcfIkOyiGPpqxZ2M',0,'127.0.0.1',1368572741,1,NULL,NULL,NULL),
	('nmxgfzw98YDvSITtxPw74GYor5L0sVfq',0,'127.0.0.1',1368516440,1,NULL,NULL,NULL),
	('nqvLEYPy7wrBRjATbJi48a7vnZrDygIR',0,'127.0.0.1',1368592984,1,NULL,NULL,NULL),
	('NtaZe7znCUYz0Vgw9GnPc8NKS7bXLPY2',0,'127.0.0.1',1368581545,1,NULL,NULL,NULL),
	('NTS3pvrjQnmRvyHz8LWZpZc2xIiqbjtr',0,'127.0.0.1',1368510969,1,NULL,NULL,NULL),
	('Nv6JCyXV8EzfDQ8r2XBAUmiEGr9KZNHw',0,'127.0.0.1',1368531032,1,NULL,NULL,NULL),
	('NVfHsilqTJCB5FMiCc03z9lk9oFkq5a6',0,'127.0.0.1',1368582505,1,NULL,NULL,NULL),
	('NvZmyvF8CXBCUti9LhB6crwQNvEmanqy',0,'127.0.0.1',1368571098,1,NULL,NULL,NULL),
	('NZGhAhNe2xTqsTpkfgzPX2XliXNdVjhx',0,'127.0.0.1',1368596611,1,NULL,NULL,NULL),
	('Ocj2BCyTIdDfXQ8AupLJ7F5rozVvIkht',0,'127.0.0.1',1368518186,1,NULL,NULL,NULL),
	('olZfT5W1e6nxDGDXHClCn7FLLl7odMX7',0,'127.0.0.1',1368533546,1,NULL,NULL,NULL),
	('OpCzoUVlPCw7stu0nmTk5MVgFlOIIM4o',0,'127.0.0.1',1368578404,1,NULL,NULL,NULL),
	('orQAA6jTcIXz3qntQ0xsN6Jynl95y69P',0,'127.0.0.1',1368592980,1,NULL,NULL,NULL),
	('oRRo42xuTwAkNQUsANpc3N3DV8Xp4Vln',0,'127.0.0.1',1368580585,1,NULL,NULL,NULL),
	('oVBJ8AoCZ70zZYkb2DPRReCwfjWVsJ9h',0,'127.0.0.1',1368594799,1,NULL,NULL,NULL),
	('oxnYbQXlKIheWd6b83bIe1ZxDCQQvS6Z',0,'127.0.0.1',1368593878,1,NULL,NULL,NULL),
	('OyqNlaf1N5ZPNw5ab6CPPQE3B1WTzRjh',0,'127.0.0.1',1368563787,1,NULL,NULL,NULL),
	('PnFaeBuUKkHoOxXI6MowgGlOliZwL2Qq',0,'127.0.0.1',1368567145,1,NULL,NULL,NULL),
	('pRWbvs3c1EPVz6m8xBclShDkFcA7wgXQ',0,'127.0.0.1',1368527785,1,NULL,NULL,NULL),
	('PtREVUKExZaNFsN9FkfChQ5dhNTy7zlx',0,'127.0.0.1',1368576745,1,NULL,NULL,NULL),
	('PvUAHhTubG9aX5DDnURusRVwLxKZ3UzY',0,'127.0.0.1',1368593065,1,NULL,NULL,NULL),
	('q0zH0ywV1yG6FQtMt7cwIocqCmPyvBHv',0,'127.0.0.1',1368530465,1,NULL,NULL,NULL),
	('Q1Im5BNIdGx1PllGRQZlo0Q8puDn0yMi',0,'127.0.0.1',1368583465,1,NULL,NULL,NULL),
	('QK0WMWgQDgV536xTjYXqqIJrBEV1BCAU',0,'127.0.0.1',1368521927,1,NULL,NULL,NULL),
	('qlPriKSAJN2u01QiH7VI8P8ue1N52exc',0,'127.0.0.1',1368556514,1,NULL,NULL,NULL),
	('QNACbZfh55sQ08UCVEFU6T89yzjyADi1',0,'127.0.0.1',1368561972,1,NULL,NULL,NULL),
	('QnQRTW91f1kT2y99NKBLoGaV7NgdX3Uc',0,'127.0.0.1',1368511466,1,NULL,NULL,NULL),
	('QP6Xwiqw9FuJ1F8ZnyBnL7i6vsTGEUjm',0,'127.0.0.1',1368510506,1,NULL,NULL,NULL),
	('qrMMlcAuGEADpns0YJclMONYlS6hCk13',0,'127.0.0.1',1368577705,1,NULL,NULL,NULL),
	('QYU4QdzzDyAVG6tdGBFuTI9ubVJqgtti',0,'127.0.0.1',1368549865,1,NULL,NULL,NULL),
	('R5nxc0M6HyZS2rYOPhjChTKXGNG0fYhH',0,'127.0.0.1',1368549248,1,NULL,NULL,NULL),
	('R5ZVwD0GWXzDT31inCobla3MfMVk3Avc',0,'127.0.0.1',1368564265,1,NULL,NULL,NULL),
	('r78h5kGkM5cl7HSV5StP5atRgENFEPOd',0,'127.0.0.1',1368576586,1,NULL,NULL,NULL),
	('rV0gEcIqxv4XEo2c4Un8nc4sRuKV7hTh',0,'127.0.0.1',1368560426,1,NULL,NULL,NULL),
	('rXZjIU9s94YmPUjnuG6sUZIDzgJ9nRoN',0,'127.0.0.1',1368591145,1,NULL,NULL,NULL),
	('S8HnkQbSfPlf9UpHQLrkH64XeqWuacwN',0,'127.0.0.1',1368560157,1,NULL,NULL,NULL),
	('sIrVtR97CUGfEOG0N2vgJ0WyQle5x1sf',0,'127.0.0.1',1368587544,1,NULL,NULL,NULL),
	('SKneaELv4sGlNUXPXBkyLwGAVoNFLQRS',0,'127.0.0.1',1368551068,1,NULL,NULL,NULL),
	('t89SflHdIRNDXfS0z6YeA0BmNYySf3LF',0,'127.0.0.1',1368572949,1,NULL,NULL,NULL),
	('TkDNfNBEHSbxjUKTi8UHYDYbKToAe28r',0,'127.0.0.1',1368558340,1,NULL,NULL,NULL),
	('tlxEjvm5pdW1XPU9mKGQ2lj5toiwr91Y',0,'127.0.0.1',1368521066,1,NULL,NULL,NULL),
	('Tnwv0PoYt5fhkGmwtHeNQ7CcuuDI94fd',0,'127.0.0.1',1368571945,1,NULL,NULL,NULL),
	('TpfA53P0SSNc2AMk5lnFwkljJPxuOE6W',0,'127.0.0.1',1368591172,1,NULL,NULL,NULL),
	('Trb6W1CutyIvWj6fvyzlBGxQCcu501tO',0,'127.0.0.1',1368534506,1,NULL,NULL,NULL),
	('TsCXIDMpYDwdlSVc4Am8DzElbk5Dvq7i',0,'127.0.0.1',1368534663,1,NULL,NULL,NULL),
	('TTG0YfbsAf7UhYrjzH4UfLcluTu33eGF',0,'127.0.0.1',1368538346,1,NULL,NULL,NULL),
	('u0HIZPTR7DGGrwZ40TJdCzoUDoWxNuFY',0,'127.0.0.1',1368520115,1,NULL,NULL,NULL),
	('U1gDZioBvVaSZJI1wVVTvRsWgnaKEAq9',0,'127.0.0.1',1368572945,1,NULL,NULL,NULL),
	('uHlD4fcOTQzxGn7YVFbuQbFKAEAU9v0S',0,'127.0.0.1',1368556510,1,NULL,NULL,NULL),
	('uIc9BgsUarERFDeOolnIZjItphk3fg76',0,'127.0.0.1',1368541958,1,NULL,NULL,NULL),
	('ULDcXSE1AY3hlj3BcBLsqAdTJxBjT0uO',0,'127.0.0.1',1368520106,1,NULL,NULL,NULL),
	('uSltk4ZHUDDw3jpNurPlO1yVfR1H9o0x',0,'127.0.0.1',1368522026,1,NULL,NULL,NULL),
	('vIanVViC5J6RKofCTgRbFNVZ5xyktjtg',0,'127.0.0.1',1368522986,1,NULL,NULL,NULL),
	('vjyyFSZw7MZq7iMrDGOWTcx64BUdpLtU',0,'127.0.0.1',1368578409,1,NULL,NULL,NULL),
	('vOHyak6x5WXQUzUMEZF4kmkosk2QSKjy',0,'127.0.0.1',1368559465,1,NULL,NULL,NULL),
	('VoSo0KRkbBr8Qsd2DFiORFI3rCVlQNFH',0,'127.0.0.1',1368570025,1,NULL,NULL,NULL),
	('VQQFi3FbZ4COAAmqrFPd8W8nHzGTCJrh',0,'127.0.0.1',1368512795,1,NULL,NULL,NULL),
	('VtEYxqvn35f0yoii22MAZ6326PFHHWRp',0,'127.0.0.1',1368582046,1,NULL,NULL,NULL),
	('W4h6k5RxBvc5KUz8VJShcZnekpQZTlZx',0,'127.0.0.1',1368543145,1,NULL,NULL,NULL),
	('W9xEZEv1QNvFyodocsVOUUylnxrOX3jz',0,'127.0.0.1',1368596607,1,NULL,NULL,NULL),
	('wjqWvetpi3RQjCsSoPzikgJpSiQMREc2',0,'127.0.0.1',1368590185,1,NULL,NULL,NULL),
	('wljQK4xqcgmClTyHnLaJL5QhnBDIpXJ1',0,'127.0.0.1',1368540265,1,NULL,NULL,NULL),
	('wmMUQSZeFVjxHWKAE7w5XSXSPD2cPJ5k',0,'127.0.0.1',1368565607,1,NULL,NULL,NULL),
	('WQ3FchMtytcYkX5YgJr1PRug1xzk4fDf',0,'127.0.0.1',1368537386,1,NULL,NULL,NULL),
	('WrvyhBrqXu7Ql9B3KDG7O6BJCJOm4avG',0,'127.0.0.1',1368589225,1,NULL,NULL,NULL),
	('WvjUaPw5PjJhDtw3dVEy9GuObKhmaktG',0,'127.0.0.1',1368562345,1,NULL,NULL,NULL),
	('WypIDObxFvEX83888OoaVwBYJmZq6kli',0,'127.0.0.1',1368583894,1,NULL,NULL,NULL),
	('WyYJ9oi7i39vqJDAySQ1l98FmjQ1AIAr',0,'127.0.0.1',1368547423,1,NULL,NULL,NULL),
	('x593sSpW9VTwESxCC6QnFg9OlHOLK27x',0,'127.0.0.1',1368541226,1,NULL,NULL,NULL),
	('X6hArRaSWDYuLj6exoH9RPN4S3Pp7K4c',0,'127.0.0.1',1368554698,1,NULL,NULL,NULL),
	('XbvNnyUFU3Uq1wtDEx4Xl9eZZbNTu0dv',0,'127.0.0.1',1368530665,1,NULL,NULL,NULL),
	('xFxPVcW1m7AjvewGcuQHIZPIbqQbT05n',0,'127.0.0.1',1368530361,1,NULL,NULL,NULL),
	('XHtzyqmaBGNIhENNxU8Tcr1kLgavInPH',0,'127.0.0.1',1368517226,1,NULL,NULL,NULL),
	('XSofZlAQeqH2NrpE11sXz9OkYG9GGaSj',0,'127.0.0.1',1368585385,1,NULL,NULL,NULL),
	('XWPLtwBCI8xTJZ8yzbVECJ1t3lQSNafJ',0,'127.0.0.1',1368573865,1,NULL,NULL,NULL),
	('y4A4uhtNjn8roz9rcmRXRGC1JBCJv8v0',0,'127.0.0.1',1368552883,1,NULL,NULL,NULL),
	('y5zBEfAgbtX00xrhgsyXPHhkToQw2GcM',0,'127.0.0.1',1368510973,1,NULL,NULL,NULL),
	('YhfkPehGZBs64eG7HQAw5iVGKAnER0Ko',0,'127.0.0.1',1368558336,1,NULL,NULL,NULL),
	('Yi5RrgPyCbuRrxgFSU01X2XLZTjmOVkS',0,'127.0.0.1',1368580220,1,NULL,NULL,NULL),
	('YjCekVjFwCCik9WqmpueizxqfBJ2R43D',0,'127.0.0.1',1368530468,1,NULL,NULL,NULL),
	('YrEM1ZpJ45iRSTjHIOZDLUpHUwmZnnEV',0,'127.0.0.1',1368518263,1,NULL,NULL,NULL),
	('YuUsEsUXyo6ZuiDLgG6VeVXY1cpDR2Oj',0,'127.0.0.1',1368551785,1,NULL,NULL,NULL),
	('z3mpU1bbLgefJdBJwbUkMfJyRFLiVMAw',0,'127.0.0.1',1368582041,1,NULL,NULL,NULL),
	('zDf696TLido8dP2SsKtesHfkkA4qBJk0',0,'127.0.0.1',1368557545,1,NULL,NULL,NULL),
	('ZdNsx1ZN64jWVkrBbUMbK12u9V7bgXP6',0,'127.0.0.1',1368545066,1,NULL,NULL,NULL),
	('zMWUBWI7ltA7MmmZK9e3e9lHP9f9vTbA',0,'127.0.0.1',1368534668,1,NULL,NULL,NULL),
	('ZXPmRUd6jcpG8b5rdyYLFlHKevFehnN7',0,'127.0.0.1',1368595945,1,NULL,NULL,NULL);

/*!40000 ALTER TABLE `site_user_sessions` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table sites
# ------------------------------------------------------------

DROP TABLE IF EXISTS `sites`;

CREATE TABLE `sites` (
  `id` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `sites` WRITE;
/*!40000 ALTER TABLE `sites` DISABLE KEYS */;

INSERT INTO `sites` (`id`)
VALUES
	('site');

/*!40000 ALTER TABLE `sites` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table user_config
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_config`;

CREATE TABLE `user_config` (
  `name` tinytext NOT NULL,
  `value` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `user_config` WRITE;
/*!40000 ALTER TABLE `user_config` DISABLE KEYS */;

INSERT INTO `user_config` (`name`, `value`)
VALUES
	('avatar_max_size','30'),
	('avatar_max_width','120'),
	('avatar_max_height','120'),
	('name_min_length','4'),
	('name_max_length','12'),
	('pass_min_length','4'),
	('enable_registration','1');

/*!40000 ALTER TABLE `user_config` ENABLE KEYS */;
UNLOCK TABLES;


# Dump of table user_email_changes
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_email_changes`;

CREATE TABLE `user_email_changes` (
  `user_id` int(11) NOT NULL DEFAULT '0',
  `new_email` tinytext NOT NULL,
  `confirmation_hash` varchar(32) NOT NULL DEFAULT '',
  `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table user_new
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_new`;

CREATE TABLE `user_new` (
  `name` varchar(20) NOT NULL DEFAULT '',
  `password` varchar(64) NOT NULL DEFAULT '',
  `email` tinytext NOT NULL,
  `ip` tinytext NOT NULL,
  `confirmation_hash` varchar(32) NOT NULL DEFAULT '',
  `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table user_profiles
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_profiles`;

CREATE TABLE `user_profiles` (
  `user_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `registered` int(11) NOT NULL,
  `location` tinytext,
  `avatar` tinytext,
  `signature` text,
  `forum_posts` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table user_recover
# ------------------------------------------------------------

DROP TABLE IF EXISTS `user_recover`;

CREATE TABLE `user_recover` (
  `user_id` int(11) NOT NULL DEFAULT '0',
  `new_pass` char(64) NOT NULL DEFAULT '',
  `confirmation_hash` char(32) NOT NULL DEFAULT '',
  `ctime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  KEY `confirmation_hash` (`confirmation_hash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table users
# ------------------------------------------------------------

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
