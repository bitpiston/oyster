<xsl:output method="html" version="1.0" encoding="UTF-8" media-type="text/html" indent="yes"
	doctype-public="-//W3C//DTD HTML 4.01//EN" doctype-system="http://www.w3.org/TR/html4/strict.dtd" />

<!-- Ajax Template -->
<!-- Re-implement this later -->
	
<!-- Base Template (Layout) -->

<xsl:template match="/oyster[not(@handler)]">
	<html lang="en">
		<head>
			<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
			<meta http-equiv="content-style-type" content="text/css" />
			<title>
				<xsl:variable name="title"><xsl:apply-templates mode="title" select="/oyster/*[1]" /></xsl:variable>
				<xsl:choose>
					<xsl:when test="string-length(/oyster/@page_title) != 0"><xsl:value-of select="/oyster/@page_title" /> | </xsl:when>
					<xsl:when test="string-length(normalize-space($title)) != 0"><xsl:value-of select="$title" /> | </xsl:when>
					<xsl:otherwise><xsl:apply-templates mode="heading" select="/oyster/*[1]" /> | </xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="@title" />
			</title>
			<link rel="stylesheet" type="text/css" media="screen" href="{@styles}{@style}/screen.css" />
			<link rel="stylesheet" type="text/css" media="print" href="{@styles}{@style}/print.css" />
			<xsl:comment>[if lt IE 9]>&gt;&lt;script src="http://ie7-js.googlecode.com/svn/version/2.1(beta4)/IE9.js"&gt;&lt;/script&gt;&lt;![endif]</xsl:comment>
			<xsl:comment>[if lt IE 10]&gt;&lt;link rel="stylesheet" type="text/css" media="screen" href="{@styles}{@style}/ie.css" /&gt;&lt;![endif]</xsl:comment>
			<xsl:comment>[if lt IE 8]&gt;&lt;style type="text/css"&gt;#search input[type=text] {margin-top: 1px}&lt;/style&gt;&lt;![endif]</xsl:comment>
			<xsl:comment>[if IE 9]&gt;&lt;style type="text/css"&gt;#search input[type=text] {padding-top: 5px}&lt;/style&gt;&lt;![endif]</xsl:comment>
			<xsl:comment>[if !IE]&gt;</xsl:comment><link rel="stylesheet" type="text/css" media="only screen and (max-device-width: 480px), only screen and (max-width: 480px)" href="{@styles}{@style}/mobile.css" /><xsl:comment>&lt;![endif]</xsl:comment>
			<meta name="viewport" content="width=device-width, minimum-scale=1.0, maximum-scale=1.0" />
			<link rel="alternate" type="application/rss+xml" href="{@base}rss/" title="All posts RSS feed" />
			<!-- oyster library -->
			<script src="{@styles}oyster-yui.js" type="text/javascript" />
			<!-- allow modules to hook into the head tag -->
			<xsl:apply-templates mode="html_head" />
		</head>
		<body class="{/oyster/@module} {/oyster/*[1]/@action}">
			<div id="header">
				<a id="title" href="/">BitPiston</a>
				<ul id="navigation">
					<xsl:for-each select="/oyster/menu[@id='navigation']/item">
						<li>
							<xsl:if test="substring(/oyster/@url,1,string-length(@url)) = @url">
								<xsl:attribute name="class">selected</xsl:attribute>
							</xsl:if>
							<a href="{@url}" class="{@label}">
								<xsl:value-of select="@label" />
							</a>
						</li>
					</xsl:for-each>
				</ul>
			</div>
			<hr />
			<div id="content">
				<div id="content-primary">
					<!-- <xsl:apply-templates mode="description" select="/oyster/*[1]" /> -->
					<xsl:if test="not(/oyster/@module = 'content')">
						<h1><span><xsl:apply-templates mode="heading" select="/oyster/*[1]" /></span></h1>
					</xsl:if>
					<xsl:apply-templates mode="content" />			
				</div>
				<div id="content-secondary">
					<xsl:apply-templates mode="sidebar" />
				</div>
			</div>
			<hr />
			<div id="footer">
				<p class="copyright">Copyright &#169; 2007&#8211;2011 BitPiston. All rights reserved.</p>
				<ul class="links">
					<li><a href="/accessiblity/">Accessibility</a></li>
					<li><a href="/privacy/">Privacy</a></li>
					<li><a href="/about/#jobs">Jobs</a></li>
					<li><a href="http://client.bitpiston.com/">Client Login</a></li>
					<li><a href="http://developer.bitpiston.com/">Project Tracker</a></li>
				</ul>
			</div>
			<!-- ajax popup -->
			<!-- ajax communication frame -->
		</body>
	</html>
</xsl:template>
