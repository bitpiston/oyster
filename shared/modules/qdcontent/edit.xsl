<xsl:template match="/oyster/qdcontent[@action = 'edit']" mode="heading">Edit a Page</xsl:template>
<xsl:template match="/oyster/qdcontent[@action = 'edit']" mode="description">
	asdfasdfsdf
</xsl:template>

<xsl:template match="/oyster/qdcontent[@action = 'edit']" mode="content">
	<form id="qdcontent_create" method="post" action="{/oyster/@url}">
		<dl>
			<dt><label for="url">URL:</label></dt>
			<dd class="small">The url this page will be accessed at; it is recommended that you use only lower-case characters, underscores, and forward slashes.  Leading and trailing slashes are not necessary.</dd>
			<dd><input type="text" name="url" id="url" value="{url/text()}" class="large" /></dd>

			<dt><label for="show_nav_link">Show This Item in Site Navigation:</label></dt>
			<dd>
				<input type="checkbox" name="show_nav_link" id="show_nav_link" value="1">
					<xsl:if test="show_nav_link/text() = '1'">
						<xsl:attribute name="checked">checked</xsl:attribute>
					</xsl:if>
				</input>
			</dd>

			<dt><label for="title">Title:</label></dt>
			<dd class="small">The title to give the URL for this page.</dd>
			<dd><input type="text" name="title" id="title" value="{title/text()}" class="large" /></dd>

			<dt><label for="template">Template:</label></dt>
			<dd>
				<textarea name="template" id="template" class="full"><xsl:value-of select="template/text()" /></textarea>
			</dd>

			<dt><input type="submit" value="Save" /></dt>
		</dl>
	</form>
</xsl:template>
