<?xml version="1.0" encoding="UTF-8"?>
<oyster:include_layout />

	<!-- Transform XML to (X)HTML -->
	<xsl:template match="*" mode="xhtml">
		<!-- remove element prefix (if any) -->
		<xsl:element name="{local-name()}">
			<!-- process attributes -->
			<xsl:for-each select="@*">
				<!-- remove attribute prefix (if any) -->
				<xsl:attribute name="{local-name()}">
					<xsl:value-of select="."/>
				</xsl:attribute>
			</xsl:for-each>
			<xsl:apply-templates mode="xhtml" />
		</xsl:element>
	</xsl:template>

	<xsl:template match="xhtml" mode="content">
		<xsl:apply-templates select="node()" />
	</xsl:template>

	<!-- HIDDEN STUFF -->

	<xsl:template match="/oyster/user[not(@mode)]" />

	<xsl:template match="*" mode="html_head"></xsl:template>
	<xsl:template match="*" mode="heading"></xsl:template>
	<xsl:template match="*" mode="description"></xsl:template>
	<xsl:template match="*" mode="content"></xsl:template>
	<xsl:template match="*" mode="sidebar"></xsl:template>

	<!-- LABELED MENUS (not id ones, like admin and navigation, those are styled elsewhere, usually layout.xsl) -->
	<xsl:template match="/oyster/menu[not(@id)]" mode="heading"><xsl:value-of select="@label" /></xsl:template>
	<xsl:template match="/oyster/menu[not(@id)]" mode="description"><xsl:value-of select="@description" /></xsl:template>
	<xsl:template match="/oyster/menu[not(@id)]" mode="content">
		<ul class="menu">
			<xsl:apply-templates />
		</ul>
	</xsl:template>

	<xsl:template match="/oyster/menu[not(@id)]//item">
		<li>
			<a href="{@url}"><xsl:value-of select="@label" /></a>
			<xsl:if test="count(item) > 0">
				<ul class="menu">
					<xsl:apply-templates />
				</ul>
			</xsl:if>
		</li>
	</xsl:template>

	<!-- LITERAL TEXT -->
	<xsl:template match="literal" mode="content">
		<pre><xsl:apply-templates /></pre>
	</xsl:template>

	<!-- 404 ERROR -->

	<xsl:template match="/oyster/error[@status = '404']" mode="heading">File Not Found</xsl:template>
	<xsl:template match="/oyster/error[@status = '404']" mode="description">HTTP 404</xsl:template>
	<xsl:template match="/oyster/error[@status = '404']" mode="content">
		<div class="error status">
			<p>The page you were trying to view was not found. The result of either a mistyped address, an out-of-date bookmark or a broken link on the page you just came from.</p>
			<p>You may want to try searching this site or the following:</p>
			<ul>
				<li>If you typed the page address in the Address bar, make sure that it is spelled correctly.</li>
				<li>Open the <a href="/">homepage</a>, and then look for the links to the information you want.</li>
				<li>Click the <a href="javascript:history.back(1)">back</a> button in your browser to return and try another link.</li>

			</ul>
			<small>HTTP 404 &#8211; File Not Found<br />
			<xsl:value-of select="@url" /></small>
		</div>
	</xsl:template>

	<!-- GENERAL ERROR -->

	<!--<xsl:template match="error" mode="heading">Error</xsl:template>-->
	<xsl:template match="error" mode="content">
		<div class="error general">
			<strong>Error: </strong> <xsl:apply-templates />
		</div>
	</xsl:template>

	<!-- INTERNAL ERROR -->

	<xsl:template match="internal_error" mode="content">
		<div class="error internal">
			<span>
				<xsl:choose>
					<xsl:when test="text() = ''">
						An internal error has occurred.
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="text()" />
					</xsl:otherwise>
				</xsl:choose>
			</span>
		</div>
	</xsl:template>

	<!-- ARE YOU SURE? -->

	<xsl:template match="confirm" mode="heading">Confirm</xsl:template>
	<xsl:template match="confirm" mode="content">
		<div class="confirm">
			<form id="confirm" method="post" action="{/oyster/@url}{/oyster/@query_string}">
				<div><strong>Are You Sure?</strong></div>
				<div><xsl:apply-templates /></div>
				<div>
					<input type="submit" name="confirm" value="Yes" />
					<input type="button" onclick="javascript:history.back()" value="No" />
				</div>
			</form>
		</div>
	</xsl:template>

	<!-- CONFIRMATION -->

	<xsl:template match="confirmation" mode="heading">Confirmation</xsl:template>
	<xsl:template match="confirmation" mode="content">
		<div class="confirmation">
			<div><xsl:value-of select="./text()" /></div>
			<xsl:if test="options">
				<xsl:if test="count(options/option) &gt; 1">
					<div><strong>Options</strong></div>
				</xsl:if>
				<xsl:for-each select="options/option">
					<div><a href="{@url}" class="options"><xsl:apply-templates /></a></div>
				</xsl:for-each>
			</xsl:if>
		</div>
	</xsl:template>

	<!-- DATE TRANSFORMER -->
<oyster:if_server_side>
	<xsl:template name="date">
		<xsl:param name="time" />
		<xsl:value-of select="$time" /><!-- UTC-->
	</xsl:template>
</oyster:if_server_side>
<oyster:if_client_side>
	<xsl:template name="date">
		<xsl:param name="time" />
		<xsl:param name="time_offset" />
		<xsl:param name="date_format" />
		<xsl:variable name="time-offset">
			<xsl:choose>
				<xsl:when test="$time_offset">
					<xsl:value-of select="$time_offset" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="/oyster/user[@id]/@time_offset" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="date-format">
			<xsl:choose>
				<xsl:when test="$date_format">
					<xsl:value-of select="$date_format" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="/oyster/user[@id]/@date_format" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="temp-hour" select="substring($time, 12, 2) + $time-offset" />
		<xsl:variable name="hour">
			<xsl:choose>
				<xsl:when test="$temp-hour &lt; 0">
					<xsl:value-of select="24 + $temp-hour" />
				</xsl:when>
				<xsl:when test="$temp-hour &gt; 23">
					<xsl:value-of select="24 - $temp-hour" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$temp-hour" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="temp-day">
			<xsl:choose>
				<xsl:when test="$temp-hour &lt; 0">
					<xsl:value-of select="substring($time, 9, 2) - 1" />
				</xsl:when>
				<xsl:when test="$temp-hour &gt; 23">
					<xsl:value-of select="substring($time, 9, 2) + 1" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring($time, 9, 2)" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="temp-month" select="substring($time, 6, 2)" />
		<xsl:variable name="temp-year" select="substring($time, 1, 4)" />
		<xsl:variable name="days-this-month">
			<xsl:if test="$temp-hour &gt; 23">
				<xsl:call-template name="dt:calculate-last-day-of-month">
					<xsl:with-param name="year" select="$temp-year" />
					<xsl:with-param name="month" select="$temp-month" />
				</xsl:call-template>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="day">
			<xsl:choose>
				<xsl:when test="$temp-day &lt; 1">
					<xsl:call-template name="dt:calculate-last-day-of-month">
						<xsl:with-param name="year">
							<xsl:choose>
								<xsl:when test="$temp-month = '01'">
									<xsl:value-of select="$temp-year - 1" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$temp-year" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
						<xsl:with-param name="month">
							<xsl:choose>
								<xsl:when test="$temp-month = '01'">
									<xsl:value-of select="'12'" />
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$temp-month - 1" />
								</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="not($days-this-month = '') and $temp-day &gt; $days-this-month">1</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$temp-day" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="month">
			<xsl:choose>
				<xsl:when test="$temp-day &lt; 1 and $temp-month = '01'">12</xsl:when>
				<xsl:when test="$temp-day &lt; 1">
					<xsl:value-of select="$temp-month - 1" />
				</xsl:when>
				<xsl:when test="not($days-this-month = '') and $temp-month = '12'">1</xsl:when>
				<xsl:when test="not($days-this-month = '') and $temp-day &gt; $days-this-month">
					<xsl:value-of select="$temp-month + 1" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$temp-month" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="year">
			<xsl:choose>
				<xsl:when test="$month = '12' and $temp-day &lt; 1">
					<xsl:value-of select="$temp-year - 1" />
				</xsl:when>
				<xsl:when test="not($days-this-month = '') and $temp-day &gt; $days-this-month and $temp-month = '12'">
					<xsl:value-of select="$temp-year + 1" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$temp-year" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="dt:format-date-time">
			<xsl:with-param name="year" select="$year" />
			<xsl:with-param name="month" select="$month" />
			<xsl:with-param name="day" select="$day" />
			<xsl:with-param name="hour" select="$hour" />
			<xsl:with-param name="minute" select="substring($time, 15, 2)" />
			<xsl:with-param name="second" select="substring($time, 18, 2)" />
			<xsl:with-param name="time-zone" select="$time-offset" />
			<xsl:with-param name="format" select="$date-format" />
		</xsl:call-template>
		<!--
		<xsl:if test="/oyster/user[@id]/@id = '0'"> UTC</xsl:if>
		-->
	</xsl:template>
</oyster:if_client_side>

<oyster:include_modules />

<oyster:include hook="global_includes" />

</xsl:stylesheet>


