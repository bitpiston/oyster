<xsl:template match="/swaf/admin[@action = 'modules']" mode="heading">Manage Modules</xsl:template>

<xsl:template match="/swaf/admin[@action = 'modules']" mode="description">
	Modules add functionality to Oyster.  This page allows you to manage modules.
</xsl:template>

<xsl:template match="/swaf/admin[@action = 'modules']" mode="content">
	<p>Some modules cannot be disabled; this is because they are either part of the Oyster core or because other modules depend on them.</p>

	<!-- iterate through modules -->
	<xsl:for-each select="module">

		<!-- name -->
		<h3><xsl:value-of select="@name" /></h3>

		<!-- required
		<xsl:if test="@required">
			<p><small>(required)</small></p>	
		</xsl:if> -->

		<!-- description -->
		<xsl:if test="@description">
			<p><xsl:value-of select="@description" /></p>
		</xsl:if>

		<!-- dependencies
		<xsl:if test="count(requires)">
			<label id="{@id}_deps">Dependencies</label>
			<ul>
				<xsl:for-each select="requires">
					<li>
						<xsl:value-of select="../../module[@id = current()/@id]/@name" />
					</li>
				</xsl:for-each>
			</ul>
		</xsl:if> -->

		<!-- dependencies -->
		<xsl:if test="count(requires)">
			<small>
				Dependencies: 
				<xsl:for-each select="requires">
					<xsl:value-of select="../../module[@id = current()/@id]/@name" />
					<xsl:if test="not(position() = last())">, </xsl:if>
				</xsl:for-each>
			</small>
		</xsl:if>

		<!-- actions -->
		<p><small>
			<xsl:if test="@loaded and not(@required) and count(../module[@enabled ]/requires[@id = current()/@id]) = 0">
				[ <a href="{/swaf/@base}admin/modules/?a=disable&amp;id={@id}">Disable</a> ]
			</xsl:if>
			<xsl:if test="not(@loaded)">
				[ <a href="{/swaf/@base}admin/modules/?a=enable&amp;id={@id}">Enable</a> ]
			</xsl:if>
			<xsl:if test="@rev &lt; @latest_rev">
				[ <a href="{/swaf/@base}admin/modules/?a=update&amp;id={@id}">Update or Install</a> ]
			</xsl:if>
		</small></p>
	</xsl:for-each>
</xsl:template>

