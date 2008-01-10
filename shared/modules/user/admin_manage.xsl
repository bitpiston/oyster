<xsl:template match="/swaf/user[@action = 'admin_manage']" mode="heading">
	Manage Users
</xsl:template>

<xsl:template match="/swaf/user[@action = 'admin_manage']" mode="description">
	TODO:
</xsl:template>

<xsl:template match="/swaf/user[@action = 'admin_manage']" mode="content">
	<form id="user_admin_manage" method="get" action="{/swaf/@url}">
		<dl>
			<dt><label for="find">Enter a user id or username:</label></dt>
			<dd><input type="text" name="find" id="find" class="small" value="{@find}" /></dd>
			<dt><input type="submit" value="Search" /></dt>
		</dl>
	</form>
</xsl:template>
