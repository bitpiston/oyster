<xsl:template match="/oyster/admin[@action = 'config_navigation']" mode="heading">Manage Navigation</xsl:template>
<xsl:template match="/oyster/admin[@action = 'config_navigation']" mode="description">

</xsl:template>

<xsl:template match="/oyster/admin[@action = 'config_navigation']" mode="content">
	<xsl:choose>
		<xsl:when test="@parent = '0' and count(url) = 0">
			<p>There are currently no top level navigation items.</p>
		</xsl:when>
		<xsl:when test="count(url) = 0">
			<p>There selected navigation item has no sub-items.</p>
		</xsl:when>
		<xsl:otherwise>
			<xsl:for-each select="url">
				<h3><a href="{@url}"><xsl:value-of select="@title" /></a></h3>
				<p><small>
					<xsl:if test="not(position() = 0)">
						[ <a href="{/oyster/@base}admin/config/navigation/?parent={../@parent}&amp;move={@id}&amp;dir=up">up</a> ]
					</xsl:if>
					<xsl:if test="not(position() = count())">
						[ <a href="{/oyster/@base}admin/config/navigation/?parent={../@parent}&amp;move={@id}&amp;dir=down">down</a> ]
					</xsl:if>
					[ <a href="{/oyster/@base}admin/config/navigation/?parent={@id}">sub-items</a> ]
				</small></p>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
