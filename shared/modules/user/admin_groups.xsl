<xsl:template match="/oyster/user[@action = 'admin_groups']" mode="heading">
	Manage User Groups
</xsl:template>

<xsl:template match="/oyster/user[@action = 'admin_groups']" mode="description">
	User groups are sets of permissions that can be applied to multiple users.
</xsl:template>

<xsl:template match="/oyster/user[@action = 'admin_groups']" mode="content">
	<p><a href="{/oyster/@base}admin/user/groups/create/">Create a New Group</a></p>
	<ul>
		<xsl:for-each select="groups/group">
			<li>
				<xsl:apply-templates />
				<small> [
					<a href="{/oyster/@base}admin/user/groups/edit/?group={@id}">Modify</a> -
					<a href="{/oyster/@base}admin/user/groups/delete/?group={@id}">Delete</a>
				]</small>
			</li>
		</xsl:for-each>
	</ul>
</xsl:template>
