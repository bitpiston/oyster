<xsl:template match="/swaf/ssxslt[@mode = 'admin_config']" mode="heading">Server Side XSLT Configuration</xsl:template>

<xsl:template match="/swaf/ssxslt[@mode = 'admin_config']" mode="description"></xsl:template>

<xsl:template match="/swaf/ssxslt[@mode = 'admin_config']" mode="sidebar"></xsl:template>

<xsl:template match="/swaf/ssxslt[@mode = 'admin_config']">
	<form id="ssxslt_admin_config" method="post" action="{/swaf/@url}">
		<dl>
			<dt>
				<input type="checkbox" name="force_server_side" id="force_server_side">
					<xsl:if test="@force_server_side = 1"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
				</input>
				<label for="force_server_side">Force Server Side XSLT</label>
			</dt>
			<dt><input type="submit" value="Save" /></dt>
		</dl>
	</form>
</xsl:template>
