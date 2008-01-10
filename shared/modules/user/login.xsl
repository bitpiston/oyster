<xsl:template match="/swaf/user[@action = 'login']" mode="heading">
	Log In
</xsl:template>

<xsl:template match="/swaf/user[@action = 'login']" mode="description">
	Logging in gives you access to your account's settings and profile.
</xsl:template>

<xsl:template match="/swaf/user[@action = 'login']" mode="content">
	<form id="user_login" method="post" action="{/swaf/@url}">
		<div>
			<input type="hidden" name="referer" value="{@referer}" />
			<fieldset>
				<legend>Credentials</legend>
				<dl>
					<dt><label for="username">Username:</label></dt>
					<dd><input type="text" name="user" id="username" value="{@user}" class="small" /></dd>
					<dt><label for="password">Password:</label></dt>
					<dd><input type="password" name="password" id="password" value="" class="small" /></dd>
				</dl>
			</fieldset>
			<fieldset>
				<legend>Options</legend>
				<dl>
					<dt><label for="how_long">Stay logged in:</label></dt>
					<dd><select name="how_long" id="how_long">
						<option value="0">this browser session</option>
						<option value="60">one Hour</option>
						<option value="1440">one day</option>
						<option value="10080">one week</option>
						<option value="43200">one month</option>
						<option value="518400" selected="selected">until I log out</option>
					</select></dd>
					<dt><input type="checkbox" name="restrict_ip" id="restrict_ip" value="1" /> <label for="restrict_ip">Restrict session to IP address.</label></dt>
				</dl>
			</fieldset>
			<input type="submit" value="Log In" /><br />
			<p>Forgot your password? <a href="{/swaf/@base}user/recover/" class="options">Recover your password</a></p>
			<p>Don't have an account? <a href="{/swaf/@base}register/" class="options">Register an account</a></p>
		</div>
	</form>
</xsl:template>
