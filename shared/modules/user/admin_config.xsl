<xsl:template match="/oyster/user[@action = 'admin_config']" mode="heading">
	User Configuration
</xsl:template>

<xsl:template match="/oyster/user[@action = 'admin_config']" mode="description">
	These options control various aspects of your user module.
</xsl:template>

<xsl:template match="/oyster/user[@action = 'admin_config']" mode="content">
	<form id="user_admin_config" method="post" action="{/oyster/@url}">
		<div>
			<fieldset id="user_admin_config_general">
				<legend>Global Settings</legend>
				<dl>

					<!-- Max Avatar Size -->
					<dt><label for="avatar_max_size">Max Avatar Size:</label></dt>
					<dd class="small">The maximum file size, in kilobytes, an avatar can be.</dd>
					<dd><input type="text" name="avatar_max_size" id="avatar_max_size" value="{@avatar_max_size}" class="small" /></dd>

					<!-- Max Avatar Width -->
					<dt><label for="avatar_max_width">Max Avatar Width:</label></dt>
					<dd class="small">The maximum width, in pixels, an avatar can be.</dd>
					<dd><input type="text" name="avatar_max_width" id="avatar_max_width" value="{@avatar_max_width}" class="small" /></dd>

					<!-- Max Avatar Height -->
					<dt><label for="avatar_max_height">Max Avatar Height:</label></dt>
					<dd class="small">The maximum height, in pixels, an avatar can be.</dd>
					<dd><input type="text" name="avatar_max_height" id="avatar_max_height" value="{@avatar_max_height}" class="small" /></dd>

					<!-- Minimum Username Length -->
					<dt><label for="name_min_length">Minimum Username Length:</label></dt>
					<dd class="small">The minimum character length a username can be.</dd>
					<dd><input type="text" name="name_min_length" id="name_min_length" value="{@name_min_length}" class="small" /></dd>

					<!-- Maximum Username Length -->
					<dt><label for="name_max_length">Maximum Username Length:</label></dt>
					<dd class="small">The maximum character length a username can be.</dd>
					<dd><input type="text" name="name_max_length" id="name_max_length" value="{@name_max_length}" class="small" /></dd>

					<!-- Minimum Password Length -->
					<dt><label for="pass_min_length">Minimum Password Length:</label></dt>
					<dd class="small">The minimum character length a password can be.  It is not recommended that this setting be lowered.</dd>
					<dd><input type="text" name="pass_min_length" id="pass_min_length" value="{@pass_min_length}" class="small" /></dd>

					<!-- Enable Registration -->
					<dt><label for="enable_registration">Enable Registration:</label></dt>
					<dd class="small">This option controls whether new users will be allowed to register.  If disabled, users that have registered but have not yet validated their accounts are still allowed to do so.</dd>
					<dd>
						<select id="enable_registration" name="enable_registration">
							<xsl:choose>
								<xsl:when test="@enable_registration = '1'">
									<option value="1" selected="selected">Yes</option>
									<option value="0">No</option>
								</xsl:when>
								<xsl:otherwise>
									<option value="1">Yes</option>
									<option value="0" selected="selected">No</option>
								</xsl:otherwise>
							</xsl:choose>
						</select>
					</dd>
				</dl>
			</fieldset>
			<fieldset id="user_admin_config_specific">
				<legend>Site-Specific Settings</legend>
				<dl>

					<!-- Cookie Path -->
					<dt><label for="cookie_path">Cookie Path:</label></dt>
					<dd class="small"><u>Advanced</u>: The path cookies will be stored under, do not change this unless you know what you are doing.</dd>
					<dd><input type="text" name="cookie_path" id="cookie_path" value="{@cookie_path}" class="small" /></dd>

					<!-- Cookie Domain -->
					<dt><label for="cookie_domain">Cookie Domain:</label></dt>
					<dd class="small"><u>Advanced</u>: The path domain will be stored under, do not change this unless you know what you are doing.</dd>
					<dd><input type="text" name="cookie_domain" id="cookie_domain" value="{@cookie_domain}" class="small" /></dd>

					<!-- Guest Username -->
					<dt><label for="default_name">Guest Username:</label></dt>
					<dd class="small">The default name that will be given to users when they are not logged in.</dd>
					<dd><input type="text" name="default_name" id="default_name" value="{@default_name}" class="small" /></dd>

					<!-- Guest Group -->
					<dt><label for="guest_group">Guest Group:</label></dt>
					<dd class="small">The user permissions group guests will be assigned to.</dd>
					<dd>
						<select id="guest_group" name="guest_group">
							<xsl:for-each select="groups/group">
								<option>
									<xsl:if test="../../@guest_group = @id"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
									<xsl:attribute name="value"><xsl:value-of select="@id" /></xsl:attribute>
									<xsl:apply-templates />
								</option>
							</xsl:for-each>
						</select>
					</dd>

					<!-- Default Registered Group -->
					<dt><label for="default_group">Default Registered Group:</label></dt>
					<dd class="small">The default user permissions group newly registered users will be assigned to.</dd>
					<dd>
						<select id="default_group" name="default_group">
							<xsl:for-each select="groups/group">
								<option>
									<xsl:if test="../../@default_group = @id"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
									<xsl:attribute name="value"><xsl:value-of select="@id" /></xsl:attribute>
									<xsl:apply-templates />
								</option>
							</xsl:for-each>
						</select>
					</dd>

					<!-- Customizable Styles -->
					<dt><label for="customizable_styles">Customizable Styles:</label></dt>
					<dd class="small">Enabling customizable styles allows registered users to select which style is applied to the site.</dd>
					<dd>
						<select id="customizable_styles" name="customizable_styles">
							<xsl:choose>
								<xsl:when test="@customizable_styles = '1'">
									<option value="1" selected="selected">Yes</option>
									<option value="0">No</option>
								</xsl:when>
								<xsl:otherwise>
									<option value="1">Yes</option>
									<option value="0" selected="selected">No</option>
								</xsl:otherwise>
							</xsl:choose>
						</select>
					</dd>
				</dl>
			</fieldset>
			<input type="submit" value="Save" />
		</div>
	</form>
</xsl:template>
