<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns="http://www.w3.org/1999/xhtml">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" media-type="application/xhtml+xml" indent="yes" doctype-public="-//W3C//DTD XHTML 1.1//EN"  doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" />
	
	<xsl:template match="/document">
		<html xml:lang="en">
			<head>
				<meta http-equiv="content-type" content="application/xhtml+xml; charset=UTF-8" />
				<meta http-equiv="content-style-type" content="text/css" />
				<link rel="stylesheet" type="text/css" media="screen" href="./document.css" />
				<title><xsl:value-of select="@title" /></title>
			</head>
			<body class="documentation">
				<div id="header">
					<div class="wrapper">
						<a id="title" href="">Oyster</a>
						<span id="subtitle">A Perl web application framework.</span>
					</div>
				</div>
				<hr />
				<div id="content">
					<div class="wrapper">
						<div id="content-primary">
							<h1><xsl:value-of select="@title" /></h1>
	
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
						</div>
						<div id="content-secondary">
					
						</div>
					</div>
				</div>
				<hr />
				<div id="footer">
					<div class="wrapper">
						<p class="copyright">Copyright &#169; 2007&#8211;2008 BitPiston, <abbr title="Limited Liability Company">LLC</abbr>. All rights reserved. <br /> Oyster is released under the <a href="./license.xhtml">Artistic License 2</a>, or the <a href="./license.xhtml">GNU General Public License (GPL) 2.</a></p>
						<a id="bitpiston" href="http://www.bitpiston.com/">A BitPiston Product.</a>
					</div>
				</div>
			</body>
		</html>
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
			<h2><xsl:value-of select="@title" /></h2>
		</xsl:if>
		<xsl:if test="count(ancestor::*) = '2'">
			<h3><xsl:value-of select="@title" /></h3>
		</xsl:if>
		<xsl:if test="count(ancestor::*) = '3'">
			<h4><xsl:value-of select="@title" /></h4>
		</xsl:if>
		<xsl:if test="count(ancestor::*) = '4'">
			<h5><xsl:value-of select="@title" /></h5>
		</xsl:if>
		<xsl:if test="count(ancestor::*) = '5'">
			<h6><xsl:value-of select="@title" /></h6>
		</xsl:if>
		<p><xsl:apply-templates /></p>
	</xsl:template>
	
	<xsl:template match="function">
		<div class="function">
			<xsl:if test="count(ancestor::*) = '1'">
				<h2><xsl:value-of select="@name" /></h2>
			</xsl:if>
			<xsl:if test="count(ancestor::*) = '2'">
				<h3><xsl:value-of select="@name" /></h3>
			</xsl:if>
			<xsl:if test="count(ancestor::*) = '3'">
				<h4><xsl:value-of select="@name" /></h4>
			</xsl:if>
			<xsl:if test="count(ancestor::*) = '4'">
				<h5><xsl:value-of select="@name" /></h5>
			</xsl:if>
			<xsl:if test="count(ancestor::*) = '5'">
				<h6><xsl:value-of select="@name" /></h6>
			</xsl:if>
			<p><xsl:value-of select="synopsis" /></p>
			<xsl:for-each select="note">
				<p class="note"><xsl:value-of select="." /></p>
			</xsl:for-each>
			<xsl:if test="prototype">
				<xsl:if test="count(prototype/ancestor::*) = '2'">
					<h3><xsl:value-of select="@name" /></h3>
				</xsl:if>
				<xsl:if test="count(prototype/ancestor::*) = '3'">
					<h4><xsl:value-of select="@name" /></h4>
				</xsl:if>
				<xsl:if test="count(prototype/ancestor::*) = '4'">
					<h5><xsl:value-of select="@name" /></h5>
				</xsl:if>
				<xsl:if test="count(prototype/ancestor::*) = '5'">
					<h6><xsl:value-of select="@name" /></h6>
				</xsl:if>
				<h3>Prototype:</h3>
				<xsl:for-each select="prototype">
					<pre class="prototype"><xsl:value-of select="." /></pre>
				</xsl:for-each>
			</xsl:if>
			<xsl:if test="example">
				<xsl:if test="count(example/ancestor::*) = 2">
					<h3><xsl:value-of select="@name" /></h3>
				</xsl:if>
				<xsl:if test="count(example/ancestor::*) = 3">
					<h4><xsl:value-of select="@name" /></h4>
				</xsl:if>
				<xsl:if test="count(example/ancestor::*) = 4">
					<h5><xsl:value-of select="@name" /></h5>
				</xsl:if>
				<xsl:if test="count(example/ancestor::*) = 5">
					<h6><xsl:value-of select="@name" /></h6>
				</xsl:if>
				<h3>Example:</h3>
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