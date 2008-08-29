<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns="http://www.w3.org/1999/xhtml">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" media-type="application/xhtml+xml" indent="yes" doctype-public="-//W3C//DTD XHTML 1.1//EN"  doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" />
	
	<xsl:template match="/">
		<html xml:lang="en">
			<head>
				<meta http-equiv="content-type" content="application/xhtml+xml; charset=UTF-8" />
				<meta http-equiv="content-style-type" content="text/css" />
				<link rel="stylesheet" type="text/css" media="screen" href="{/document/@depth}document.css" />
				<title><xsl:if test="/document"><xsl:value-of select="/document/@title" /> | </xsl:if>Oyster Documentation</title>
				<xsl:comment>[if lt IE 8]&gt;
					&lt;link rel="stylesheet" type="text/css" media="screen" href="./layout/ie.css" /&gt;
					&lt;script src="http://ie7-js.googlecode.com/svn/version/2.0(beta3)/IE8.js" type="text/javascript"&gt;&lt;/script&gt;
				&lt;![endif]</xsl:comment>
			</head>
			<body class="documentation">
				<xsl:if test="/index">
					<xsl:attribute name="class">documentation toc</xsl:attribute>
				</xsl:if>				
				<div id="header">
					<div class="wrapper">
						<a id="title" href="http://oyster.bitpiston.com/">Oyster</a>
						<span id="subtitle">A Perl web application framework.</span>
					</div>
				</div>
				<hr />
				<div id="navigation">
					<div class="wrapper">
						<ul>
							<li><a href="http://oyster.bitpiston.com/">Overview</a></li>
							<li><a href="http://oyster.bitpiston.com/download/">Download</a></li>
							<li class="selected"><a href="../index.xhtml">Documentation</a></li>
							<li><a href="http://oyster.bitpiston.com/weblog/">Weblog</a></li>
							<li><a href="http://oyster.bitpiston.com/development/">Development</a></li>
						</ul>
					</div>
				</div>
				<hr />
				<div id="content">
					<div class="wrapper">
						<div id="content-primary">
							<xsl:apply-templates />
						</div>
						<div id="content-secondary">
							<form id="search" method="get" action="/search/">
								<div>
									<input type="text" id="search-input" name="search-input" accesskey="f" value="Search documentation" onfocus="if(this.value=='Search documentation') this.value='';" onblur="if(this.value=='') this.value='Search documentation';" size="25" />
									<input type="image" src="../images/icon.search.png" id="search-submit " alt="Search" title="Search" />
								</div>
							</form>
							<h2>Lorem Ipsum</h2>
							<p>Mauris eleifend adipiscing nisl. Mauris tellus nunc, condimentum vel, sollicitudin sit amet, gravida et, ante.</p>
						</div>
					</div>
				</div>
				<hr />
				<div id="footer">
					<div class="wrapper">
						<p class="copyright">Copyright &#169; 2007&#8211;2008 BitPiston, <abbr title="Limited Liability Company">LLC</abbr>. All rights reserved. <br /> Oyster is released under the <a href="./license.xhtml">Artistic License 2</a>, or the <a href="./license.xhtml">GNU General Public License (GPL) 2</a>.</p>
						<a id="bitpiston" href="http://www.bitpiston.com/">A BitPiston Product.</a>
					</div>
				</div>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="/index">
		<h1>Table of Contents</h1>
		<ol id="toc">
			<xsl:for-each select="/index/directory">
				<li id="{@title}">
					<span><xsl:value-of select="@index" /> </span><h2><xsl:value-of select="@title" /></h2>
					<ol>
						<xsl:for-each select="document">
							<li><span><xsl:value-of select="@index" /> </span><a href="{@path}{@file}.xhtml"><xsl:value-of select="@title" /></a></li>
						</xsl:for-each>
					
					</ol>
				</li>
			</xsl:for-each>
		</ol>
	</xsl:template>
	
	<xsl:template match="/document">
		<h1><span><xsl:value-of select="@index" /> </span><a href="./"><xsl:value-of select="@title" /></a></h1>
		
		<xsl:if test="/document/todo">
			<div class="todo">
				<strong>Todo</strong>
				<ul>
					<xsl:for-each select="/document/todo">
						<li><xsl:value-of select="." /></li>
					</xsl:for-each>
				</ul>
			</div>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="todo" />
	
	<xsl:template match="warning">
		<div class="warning">
			<strong>Warning</strong>
			<p><xsl:apply-templates /></p>
		</div>
	</xsl:template>
	
	<xsl:template match="section">
		<xsl:if test="count(ancestor::*) = '1'">
			<h2 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}"><xsl:value-of select="@title" /></a></h2>
		</xsl:if>
		<xsl:if test="count(ancestor::*) = '2'">
			<h3 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}"><xsl:value-of select="@title" /></a></h3>
		</xsl:if>
		<xsl:if test="count(ancestor::*) = '3'">
			<h4 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}"><xsl:value-of select="@title" /></a></h4>
		</xsl:if>
		<xsl:if test="count(ancestor::*) = '4'">
			<h5 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}"><xsl:value-of select="@title" /></a></h5>
		</xsl:if>
		<xsl:if test="count(ancestor::*) = '5'">
			<h6 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}"><xsl:value-of select="@title" /></a></h6>
		</xsl:if>
		<xsl:apply-templates />
	</xsl:template>
	
	<xsl:template match="function">
		<div class="function">
			<xsl:if test="count(ancestor::*) = '1'">
				<h2 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}" rel="bookmark"><xsl:value-of select="@name" /></a></h2>
			</xsl:if>
			<xsl:if test="count(ancestor::*) = '2'">
				<h3 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}" rel="bookmark"><xsl:value-of select="@name" /></a></h3>
			</xsl:if>
			<xsl:if test="count(ancestor::*) = '3'">
				<h4 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}" rel="bookmark"><xsl:value-of select="@name" /></a></h4>
			</xsl:if>
			<xsl:if test="count(ancestor::*) = '4'">
				<h5 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}" rel="bookmark"><xsl:value-of select="@name" /></a></h5>
			</xsl:if>
			<xsl:if test="count(ancestor::*) = '5'">
				<h6 id="{@name}"><span><xsl:value-of select="@index" /> </span><a href="{@name}" rel="bookmark"><xsl:value-of select="@name" /></a></h6>
			</xsl:if>
			<p><xsl:value-of select="synopsis" /></p>
			<xsl:for-each select="note">
				<p class="note"><xsl:value-of select="." /></p>
			</xsl:for-each>
			<xsl:if test="prototype">
				<xsl:if test="count(prototype/ancestor::*) = '2'">
					<h3>Prototype:</h3>
				</xsl:if>
				<xsl:if test="count(prototype/ancestor::*) = '3'">
					<h4>Prototype:</h4>
				</xsl:if>
				<xsl:if test="count(prototype/ancestor::*) = '4'">
					<h5>Prototype:</h5>
				</xsl:if>
				<xsl:if test="count(prototype/ancestor::*) = '5'">
					<h6>Prototype:</h6>
				</xsl:if>				
				<xsl:for-each select="prototype">
					<pre class="prototype"><xsl:value-of select="." /></pre>
				</xsl:for-each>
			</xsl:if>
			<xsl:if test="example">
				<xsl:if test="count(example/ancestor::*) = 2">
					<h3>Example:</h3>
				</xsl:if>
				<xsl:if test="count(example/ancestor::*) = 3">
					<h4>Example:</h4>
				</xsl:if>
				<xsl:if test="count(example/ancestor::*) = 4">
					<h5>Example:</h5>
				</xsl:if>
				<xsl:if test="count(example/ancestor::*) = 5">
					<h6>Example:</h6>
				</xsl:if>
				<xsl:for-each select="example">
					<pre class="code"><xsl:value-of select="." /></pre>
				</xsl:for-each>
			</xsl:if>
		</div>
	</xsl:template>
	
	<xsl:template match="synopsis">
		<p><xsl:apply-templates /></p>
	</xsl:template>
	
	<xsl:template match="note">
		<p class="note"><xsl:apply-templates /></p>
	</xsl:template>
	
</xsl:stylesheet>