<xsl:template match="/swaf/user[@action = 'admin_groups_edit']" mode="heading">
	Edit Group - <xsl:value-of select="@name" />
</xsl:template>

<xsl:template match="/swaf/user[@action = 'admin_groups_edit']" mode="description">
	User groups are sets of permissions that can be applied to multiple users.
</xsl:template>

<xsl:template match="/swaf/user[@action = 'admin_groups_edit']" mode="content">
	<form id="admin_groups_edit" method="post" action="{/swaf/@url}?group={@id}">
		<div>
			<dl>
				<dt>
					<xsl:value-of select="@num_users" />
					<xsl:choose>
						<xsl:when test="@num_users = 1"> user belongs</xsl:when>
						<xsl:otherwise> users belong</xsl:otherwise>
					</xsl:choose>
					to this group.
				</dt>
				<dt><label for="name">Name:</label></dt>
				<dd><input type="text" id="name" name="name" value="{@name}" /></dd>
			</dl>
			<xsl:for-each select="permissions/module">
				<fieldset>
					<legend onclick="sims.toggle_visibility('permissions_{@id}')"><xsl:value-of select="@name" /></legend>
					<dl id="permissions_{@id}">
						<xsl:for-each select="permission">
							<dt><xsl:value-of select="@name" />:</dt>
							<dd>
								<select id="perm-{@id}" name="{@id}">
									<xsl:for-each select="level">
										<option>
											<xsl:if test="@selected = 'selected'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
											<xsl:attribute name="value"><xsl:value-of select="@id" /></xsl:attribute>
											<xsl:apply-templates />
										</option>
									</xsl:for-each>
								</select>
							</dd>
						</xsl:for-each>
					</dl>
				</fieldset>
			</xsl:for-each>
			<input type="submit" value="Save" /><br />
		</div>
	</form>
</xsl:template>
