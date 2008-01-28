<xsl:template match="/oyster/user[@action = 'recover']" mode="heading">
	Recover Account
</xsl:template>

<xsl:template match="/oyster/user[@action = 'recover']" mode="description">
	This page can help you recover access to your account.
</xsl:template>

<xsl:template match="/oyster/user[@action = 'recover']" mode="content">
	<form id="user_recover" method="post" action="{/oyster/@url}">
		<dl>
			<dt><label for="username">Your user name or email address:</label></dt>
			<dd><input type="text" name="user" id="username" value="{@find}" class="small" /></dd>
			<dt><input type="submit" value="Submit" /></dt>
		</dl>
		<p>Don't have an account? <a href="{/oyster/@base}register/" class="options">Register an account</a></p>
	</form>
</xsl:template>
