<xsl:template match="/swaf/user[@action = 'admin_groups_delete']" mode="heading">
	Delete Group - <xsl:value-of select="@name" />
</xsl:template>

<xsl:template match="/swaf/user[@action = 'admin_groups_delete']" mode="description">
	User groups are sets of permissions that can be applied to multiple users.
</xsl:template>

<xsl:template match="/swaf/user[@action = 'admin_groups_delete']" mode="content">
	<form id="admin_groups_delete" method="post" action="{/swaf/@url}?group={@id}">
		<dl>
			<dt><label for="dest_group">Move Users From "<xsl:value-of select="@name" />" to:</label></dt>
			<dd><select name="dest_group" id="dest_group">
				<xsl:for-each select="groups/group[@id != current()/@id]">
					<option value="{@id}">
						<xsl:if test="../../@default_group = @id">
							<xsl:attribute name="selected">selected</xsl:attribute>
						</xsl:if>
						<xsl:apply-templates />
					</option>
				</xsl:for-each>
			</select></dd>
			<dt><strong>This action is permanent and cannot be undone!</strong></dt>
			<dt><input type="submit" value="Submit" /></dt>
		</dl>
	</form>
</xsl:template>
