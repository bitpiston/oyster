<xsl:template match="/swaf/user[@action = 'admin_groups_create']" mode="heading">
	Create a User Group
</xsl:template>

<xsl:template match="/swaf/user[@action = 'admin_groups_create']" mode="description">
	User groups are sets of permissions that can be applied to multiple users.
</xsl:template>

<xsl:template match="/swaf/user[@action = 'admin_groups_create']" mode="content">
	<form id="admin_groups_create" method="post" action="{/swaf/@url}">
		<div>
			<dl>
				<dt><label for="name">Group Name:</label></dt>
				<dd><input type="text" name="name" id="name" value="{@name}" class="small" /></dd>
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
