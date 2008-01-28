<xsl:template match="/oyster/user[@action = 'register']" mode="heading">
	Register
</xsl:template>

<xsl:template match="/oyster/user[@action = 'register']" mode="description">
	<!-- TODO: some blurb about creating an account -->
</xsl:template>

<xsl:template match="/oyster/user[@action = 'register']" mode="content">
	<form id="user_register" method="post" action="{/oyster/@url}">
		<p>All fields are required.</p>
		<dl>
			<dt><label for="username">Username:</label></dt>
			<dd><input type="text" name="username" id="username" value="{@username}" class="small" /></dd>
			<dt><label for="password">Password:</label></dt>
			<dd><input type="password" name="password" id="password" value="" class="small" /></dd>
			<dt><label for="password2">Confirm Password:</label></dt>
			<dd><input type="password" name="password2" id="password2" value="" class="small" /></dd>
			<dt><label for="email">Email:</label></dt>
			<dd><input type="text" name="email" id="email" value="{@email}" /></dd>
			<dt><label for="email2">Confirm Email:</label></dt>
			<dd><input type="text" name="email2" id="email2" value="{@email2}" /></dd>
			<dt><input type="submit" value="Submit" /></dt>
		</dl>
	</form>
</xsl:template>
