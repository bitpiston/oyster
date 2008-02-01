<xsl:template match="/oyster/admin[@action = 'styles']" mode="heading">Manage Styles</xsl:template>

<xsl:template match="/oyster/admin[@action = 'styles']" mode="description">
	Styles control the appearance of your site.
</xsl:template>

<xsl:template match="/oyster/admin[@action = 'styles']" mode="content">
	<ul>
		<xsl:for-each select="styles/style">
			<li>
				<xsl:value-of select="@name" />
				<small> [
					<xsl:if test="@status = '1'"><a href="{/oyster/@base}admin/styles/?disable={@id}">Disable</a></xsl:if>
					<xsl:if test="@status = '0'"><a href="{/oyster/@base}admin/styles/?enable={@id}">Enable</a></xsl:if>
					-					-
					<a href="{/oyster/@base}admin/styles/?preview={@id}">Preview</a>
				]</small>
			</li>
		</xsl:for-each>
	</ul>
</xsl:template>
