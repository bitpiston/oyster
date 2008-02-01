<xsl:template match="/oyster/admin[@action = 'styles']" mode="heading">Manage Styles</xsl:template>

<xsl:template match="/oyster/admin[@action = 'styles']" mode="description">
	Styles control the appearance of your site.
</xsl:template>

<xsl:template match="/oyster/admin[@action = 'styles']" mode="content">
	<xsl:for-each select="styles/style">

		<!-- name -->
		<h3><xsl:value-of select="@name" /></h3>

		<!-- actions -->
		<p><small>
			[ <xsl:if test="@status = '1'"><a href="{/oyster/@base}admin/styles/?disable={@id}">Disable</a></xsl:if><xsl:if test="@status = '0'"><a href="{/oyster/@base}admin/styles/?enable={@id}">Enable</a></xsl:if> ]
			[ <a href="{/oyster/@base}admin/styles/?preview={@id}">Preview</a> ]
		</small></p>
	</xsl:for-each>
</xsl:template>
