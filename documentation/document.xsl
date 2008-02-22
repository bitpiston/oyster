<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns="http://www.w3.org/1999/xhtml">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" media-type="application/xhtml+xml" indent="yes" doctype-public="-//W3C//DTD XHTML 1.1//EN"  doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" />
	
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