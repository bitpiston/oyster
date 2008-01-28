<xsl:template match="/oyster/admin[@action = 'logs']" mode="heading">Logs</xsl:template>

<xsl:template match="/oyster/admin[@action = 'logs']" mode="description">
	Logs can contain useful information about your site including simple status messages or fatal errors.
</xsl:template>

<xsl:template match="/oyster/admin[@action = 'logs']" mode="content">
	<xsl:if test="count(entry) = 0">
		<p>There are currently no entries in this log.</p>
	</xsl:if>
	<xsl:if test="count(entry)">
		<p><a href="?clear={@log}">Clear This Log</a></p>
	</xsl:if>
	<div class="offset">
		<xsl:if test="@prev_offset">
			<a href="{/oyster/@url}?view={@log}&amp;offset={@prev_offset}" class="previous">Previous Page (Newer)</a>
		</xsl:if>
		<xsl:if test="@prev_offset and @next_offset"> | </xsl:if>
		<xsl:if test="@next_offset">
			<a href="{/oyster/@url}?view={@log}&amp;offset={@next_offset}" class="next">Next Page (Older)</a>
		</xsl:if>
	</div>
	<xsl:for-each select="entry">
		<xsl:if test="not(substring(preceding-sibling::*/@time, 0, 11) = substring(@time, 0, 11))">
			<h2>
				<xsl:call-template name="date">
					<xsl:with-param name="time" select="@time" />
					<xsl:with-param name="date_format" select="'%B %e, %Y'" />
				</xsl:call-template>
			</h2>
		</xsl:if>
		<h3>
			<xsl:call-template name="date">
				<xsl:with-param name="time" select="@time" />
				<xsl:with-param name="date_format" select="'%H:%M:%S'" />
			</xsl:call-template>
		</h3>
		<pre><xsl:value-of select="message/text()" /></pre>
		<xsl:if test="count(trace)">
			<div>
				<a onclick="oyster.toggle_visibility('error_log_trace_{@id}')">[ View Trace ]</a>
				<pre id="error_log_trace_{@id}" style="display: none; margin-top: 5px"><xsl:value-of select="trace/text()" /></pre>
			</div>
		</xsl:if>
	</xsl:for-each>
	<div class="offset">
		<xsl:if test="@prev_offset">
			<a href="{/oyster/@url}?view={@log}&amp;offset={@prev_offset}" class="previous">Previous Page (Newer)</a>
		</xsl:if>
		<xsl:if test="@prev_offset and @next_offset"> | </xsl:if>
		<xsl:if test="@next_offset">
			<a href="{/oyster/@url}?view={@log}&amp;offset={@next_offset}" class="next">Next Page (Older)</a>
		</xsl:if>
	</div>
</xsl:template>

