<xsl:template match="/oyster/admin[@action = 'config']" mode="heading">Site Settings</xsl:template>
<xsl:template match="/oyster/admin[@action = 'config']" mode="description">
	This page contains various options that control your site.  For module-specific options, see the configuration section of each individual module.
</xsl:template>

<xsl:template match="/oyster/admin[@action = 'config']" mode="content">
	<form id="admin_config" method="post" action="{/oyster/@url}">
		<dl>
			<dt><label for="site_name">Site Name:</label></dt>
			<dd class="small">This is the title of your site, it can contain any characters.</dd>
			<dd><input type="text" name="site_name" id="site_name" value="{@site_name}" class="large" /></dd>
			<dt><label for="default_url">Default URL:</label></dt>
			<dd class="small">This is the url of the default page to be displayed when visiting the home page of your site.  For help on obtaining a url <a href="#">click here</a>.</dd>
			<dd><input type="text" name="default_url" id="default_url" value="{@default_url}" /></dd>
			<dt><label for="default_style">Default Style:</label></dt>
			<dd class="small">This is the default style for your site.  Users can choose other styles if their permissions permit it.</dd>
			<dd>
				<select id="default_style" name="default_style">
					<xsl:for-each select="styles/style">
						<option value="{@id}">
							<xsl:if test="../../@default_style = @id"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
							<xsl:value-of select="@name" />
						</option>
					</xsl:for-each>
				</select>
			</dd>
			<dt><label for="navigation_depth">Navigation Depth:</label></dt>
			<dd class="small">This is the depth of your navigation menu.  A setting of "1" would only display top-level items, "2" would display all top level items and their direct sub-pages..</dd>
			<dd><input type="text" name="navigation_depth" id="navigation_depth" value="{@navigation_depth}" class="small" /></dd>
			<dt><label for="time_offset">Time Offset:</label></dt>
			<dd class="small">This is your server's time offset from GMT.  It is applied before any user-defined time offsets.</dd>
			<dd><input type="text" name="time_offset" id="time_offset" value="{@time_offset}" class="small" /></dd>
			<dt><label for="error_message">Error Message:</label></dt>
			<dd class="small">This is the message that is displayed to a user when an internal error occurs.  This must be valid xhtml.</dd>
			<dd><input type="text" name="error_message" id="error_message" value="{@error_message}" class="large" /></dd>
			<dt><input type="submit" value="Save" /></dt>
		</dl>
	</form>
</xsl:template>
