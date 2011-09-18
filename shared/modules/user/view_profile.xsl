<xsl:template match="/oyster/user[@action = 'view_profile']" mode="heading">
	User Profile - <xsl:value-of select="@name" />
</xsl:template>

<xsl:template match="/oyster/user[@action = 'view_profile']" mode="description">

</xsl:template>

<xsl:template match="/oyster/user[@action = 'view_profile']" mode="content">
	<xsl:for-each select="group">
		<h2><xsl:value-of select="@name" /></h2>
		<dl>
			<xsl:for-each select="field">
				<dt><xsl:value-of select="@name" /></dt>
				<dd>
					<xsl:choose>
						<xsl:when test="@link">
							<a href="{@link}{@value}"><xsl:value-of select="@value" /></a>
						</xsl:when>
						<xsl:when test="not(@value)">
							<xsl:apply-templates select="node()" mode="xhtml" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="@value" />
						</xsl:otherwise>
					</xsl:choose>
				</dd>
			</xsl:for-each>
		</dl>
	</xsl:for-each>
</xsl:template>
