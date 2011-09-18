<xsl:template match="/oyster/user[@action = 'edit_account']" mode="heading">
	User Account
	<xsl:if test="@id">
		- <xsl:value-of select="@name" />
	</xsl:if>
</xsl:template>

<xsl:template match="/oyster/user[@action = 'edit_account']" mode="description">
	<!-- TODO: some blurb about user settings -->
</xsl:template>

<xsl:template match="/oyster/user[@action = 'edit_account']" mode="content">
	<form id="user_edit_account" method="post" action="{/oyster/@url}">
		<xsl:if test="@id">
			<input type="hidden" name="id" value="{@id}" />
		</xsl:if>
		<fieldset>
			<legend>Settings</legend>
			<dl>
				<!-- User Group -->
				<xsl:if test="@group_id">
					<dt><label for="group_id">User Group:</label></dt>
					<dd><select id="group_id" name="group_id">
						<xsl:for-each select="settings/groups/group">
							<option>
								<xsl:if test="@id = /oyster/user[@mode = 'edit_account']/@group_id"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								<xsl:attribute name="value"><xsl:value-of select="@id" /></xsl:attribute>
								<xsl:apply-templates />
							</option>
						</xsl:for-each>
					</select></dd>
				</xsl:if>

				<!-- Password -->
				<dt><label for="password">Password:</label></dt>
				<dd><input type="password" name="password" id="password" value="" class="small" /></dd>
				<dt><label for="password2">Confirm Password:</label></dt>
				<dd><input type="password" name="password2" id="password2" value="" class="small" /></dd>
				<dd><small>Password and confirm password are optional, only update them if you wish to change your existing password.</small></dd>

				<!-- Email -->
				<dt><label for="email">Email:</label></dt>
				<dd><input type="text" name="email" id="email" value="{@email}" /></dd>
				<dd><small>Changing this will require confirmation via email before the update takes effect.</small></dd>

				<!-- Date Format -->
				<dt><label for="date_format">Date Format:</label></dt>
				<dd><select id="date_format" name="date_format">
					<xsl:for-each select="settings/date_formats/format">
						<option>
							<xsl:if test="../../@date_format = ./text()"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
							<xsl:attribute name="value"><xsl:apply-templates /></xsl:attribute>
							<xsl:call-template name="date">
								<xsl:with-param name="date_format"><xsl:apply-templates /></xsl:with-param>
								<xsl:with-param name="time" select="'2006-01-29 02:06:45'" />
							</xsl:call-template>
						</option>
					</xsl:for-each>
				</select></dd>

				<!-- Time Offset -->
				<dt><label for="time_offset">GMT Time Offset:</label></dt>
				<dd><select id="time_offset" name="time_offset">
					<option value="-12">
						<xsl:if test="@time_offset = '-12'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-12
					</option>
					<option value="-11">
						<xsl:if test="@time_offset = '-11'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-11
					</option>
					<option value="-10">
						<xsl:if test="@time_offset = '-10'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-10
					</option>
					<option value="-9">
						<xsl:if test="@time_offset = '-9'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-9
					</option>
					<option value="-8">
						<xsl:if test="@time_offset = '-8'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-8
					</option>
					<option value="-7">
						<xsl:if test="@time_offset = '-7'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-7
					</option>
					<option value="-6">
						<xsl:if test="@time_offset = '-6'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-6
					</option>
					<option value="-5">
						<xsl:if test="@time_offset = '-5'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-5
					</option>
					<option value="-4">
						<xsl:if test="@time_offset = '-4'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-4
					</option>
					<option value="-3">
						<xsl:if test="@time_offset = '-3'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-3
					</option>
					<option value="-2">
						<xsl:if test="@time_offset = '-2'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-2
					</option>
					<option value="-1">
						<xsl:if test="@time_offset = '-1'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						-1
					</option>
					<option value="0">
						<xsl:if test="@time_offset = '0'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						0
					</option>
					<option value="1">
						<xsl:if test="@time_offset = '1'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+1
					</option>
					<option value="2">
						<xsl:if test="@time_offset = '2'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+2
					</option>
					<option value="3">
						<xsl:if test="@time_offset = '3'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+3
					</option>
					<option value="4">
						<xsl:if test="@time_offset = '4'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+4
					</option>
					<option value="5">
						<xsl:if test="@time_offset = '5'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+5
					</option>
					<option value="6">
						<xsl:if test="@time_offset = '6'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+6
					</option>
					<option value="7">
						<xsl:if test="@time_offset = '7'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+7
					</option>
					<option value="8">
						<xsl:if test="@time_offset = '8'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+8
					</option>
					<option value="9">
						<xsl:if test="@time_offset = '9'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+9
					</option>
					<option value="10">
						<xsl:if test="@time_offset = '10'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+10
					</option>
					<option value="11">
						<xsl:if test="@time_offset = '11'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+11
					</option>
					<option value="12">
						<xsl:if test="@time_offset = '12'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+12
					</option>
					<option value="13">
						<xsl:if test="@time_offset = '13'"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
						+13
					</option>
				</select></dd>

				<!-- Custom Style -->
				<xsl:if test="@customizable_styles">
					<dt><label for="style">Style:</label></dt>
					<dd>
						<select id="style" name="style">
							<option value="">
								<xsl:if test="@style = ''"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
								Default
							</option>
							<xsl:for-each select="styles/style">
								<option value="{@id}">
									<xsl:if test="../../@style = @id"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
									<xsl:value-of select="@name" />
								</option>
							</xsl:for-each>
						</select>
					</dd>
				</xsl:if>
			</dl>	
		</fieldset>
		<xsl:if test="profile">
			<fieldset>
				<legend>Profile</legend>
				<dl>
					<xsl:for-each select="profile/group">
						<dt><xsl:value-of select="@name" /></dt>
						<dd>
							<dl>
								<xsl:for-each select="field">
									<dt><label for="{@name}"><xsl:value-of select="@name" /></label></dt>
									<xsl:if test="@note">
										<dd><small><xsl:value-of select="@note" /></small></dd>
									</xsl:if>
									<dd>
										<xsl:choose>
											<xsl:when test="@type = 'select'">
												<select id="{@name}" name="{@name}">
													<xsl:for-each select="value">
														<option value="{node()}">
															<xsl:if test="../@default = node()">
																<xsl:attribute name="selected">selected</xsl:attribute>
															</xsl:if>
															<xsl:value-of select="node()" />
														</option>
													</xsl:for-each>
												</select>
											</xsl:when>
											<xsl:when test="@type = 'textarea'">
												<textarea id="{@name}" name="{@name}"><xsl:value-of select="node()" /></textarea>
											</xsl:when>
											<xsl:when test="@type = 'text'">
												<input id="{@name}" name="{@name}" type="text" value="{@value}" />
											</xsl:when>
											<xsl:when test="@type = 'checkbox'">
												<input id="{@name}" name="{@name}" type="checkbox" value="{@value}">
													<xsl:if test="@value = 1">
														<xsl:attribute name="checked">checked</xsl:attribute>
													</xsl:if>
												</input>
											</xsl:when>
										</xsl:choose>
									</dd>
								</xsl:for-each>
							</dl>
						</dd>
					</xsl:for-each>
				</dl>
			</fieldset>
		</xsl:if>
		<input type="submit" value="Save" />		
	</form>
</xsl:template>
