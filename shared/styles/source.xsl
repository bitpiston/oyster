<?xml version="1.0" encoding="UTF-8"?>

<swaf:if_server_side>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns="http://www.w3.org/1999/xhtml">
</swaf:if_server_side>
<swaf:if_client_side>
<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:dt="http://xsltsl.org/date-time"
 xmlns:str="http://xsltsl.org/string"
 xmlns="http://www.w3.org/1999/xhtml">
<swaf:import_shared href="date-time.xsl" />
<swaf:import_shared href="string.xsl" />
</swaf:if_client_side>
	<xsl:output method="xml" indent="yes" />

<swaf:include_layout />

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

	<xsl:template match="/swaf/user[not(@mode)]" />

	<xsl:template match="*" mode="html_head"></xsl:template>
	<xsl:template match="*" mode="heading"></xsl:template>
	<xsl:template match="*" mode="description"></xsl:template>
	<xsl:template match="*" mode="content"></xsl:template>
	<xsl:template match="*" mode="sidebar"></xsl:template>

	<!-- LABELED MENUS (not id ones, like admin and navigation, those are styled elsewhere, usualy layout.xsl) -->
	<xsl:template match="/swaf/menu[not(@id)]" mode="heading"><xsl:value-of select="@label" /></xsl:template>
	<xsl:template match="/swaf/menu[not(@id)]" mode="description"><xsl:value-of select="@description" /></xsl:template>
	<xsl:template match="/swaf/menu[not(@id)]" mode="content">
		<ul class="menu">
			<xsl:apply-templates />
		</ul>
	</xsl:template>

	<xsl:template match="/swaf/menu[not(@id)]//item">
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

	<xsl:template match="/swaf/error[@status = '404']" mode="heading">File Not Found</xsl:template>
	<xsl:template match="/swaf/error[@status = '404']" mode="description">HTTP 404 Error</xsl:template>
	<xsl:template match="/swaf/error[@status = '404']" mode="content">
		<div class="error status">
			<p>The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.</p>
			<p>Please try the following:</p>
			<ul>
			<li>If you typed the page address in the Address bar, make sure that it is spelled correctly.</li>
			<li>Open the <a href="/">homepage</a>, and then look for the links to the information you want.</li>
			<li>Click the <a href="javascript:history.back(1)">back</a> button and try another link.</li>
			</ul>
		</div>
	</xsl:template>

	<!-- GENERAL ERROR -->

	<xsl:template match="error" mode="heading">Error</xsl:template>
	<xsl:template match="error" mode="content">
		<div class="error general">
			<p><img src="{/swaf/@styles}{/swaf/@style}/images/icon.error.png" alt="Error" /> <xsl:apply-templates /></p>
		</div>
	</xsl:template>

	<!-- INTERNAL ERROR -->

	<xsl:template match="/swaf/internal_error" mode="content">
		<div class="error internal">
			<p><img src="{/swaf/@styles}{/swaf/@style}/images/icon.error.png" alt="Error" /> 
				<xsl:choose>
					<xsl:when test="text() = ''">
						An internal error has occurred.
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="text()" />
					</xsl:otherwise>
				</xsl:choose>
			</p>
		</div>
	</xsl:template>

	<!-- ARE YOU SURE? -->

	<xsl:template match="confirm" mode="heading">Confirm</xsl:template>
	<xsl:template match="confirm" mode="content">
		<div class="confirm">
			<form id="confirm" method="post" action="{/swaf/@url}{/swaf/@query_string}">
				<p><strong>Are You Sure?</strong></p>
				<p><xsl:apply-templates /></p>
				<p>
					<input type="submit" name="confirm" value="Yes" />
					<input type="button" onclick="javascript:history.back()" value="No" />
				</p>
			</form>
		</div>
	</xsl:template>

	<!-- CONFIRMATION -->

	<xsl:template match="confirmation" mode="heading">Confirmation</xsl:template>
	<xsl:template match="confirmation" mode="content">
		<div class="confirmation">
			<p><xsl:value-of select="./text()" /></p>
			<xsl:if test="options">
				<xsl:if test="count(options/option) &gt; 1">
					<p><strong>Options</strong></p>
				</xsl:if>
				<xsl:for-each select="options/option">
					<p><a href="{@url}" class="options"><xsl:apply-templates /></a></p>
				</xsl:for-each>
			</xsl:if>
		</div>
	</xsl:template>

	<!-- DATE TRANSFORMER -->
<swaf:if_server_side>
	<xsl:template name="date">
		<xsl:param name="time" />
		<xsl:value-of select="$time" /> UTC
	</xsl:template>
</swaf:if_server_side>
<swaf:if_client_side>
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
					<xsl:value-of select="/swaf/user[@id]/@time_offset" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="date-format">
			<xsl:choose>
				<xsl:when test="$date_format">
					<xsl:value-of select="$date_format" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="/swaf/user[@id]/@date_format" />
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
		<xsl:if test="/swaf/user[@id]/@id = '0'"> UTC</xsl:if>
	</xsl:template>
</swaf:if_client_side>

<swaf:include_modules />

<swaf:include hook="global_includes" />

</xsl:stylesheet>


