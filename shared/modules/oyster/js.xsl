
<xsl:template name="oyster_js_editbuttons">
	<xsl:param name="translation_mode_field_id" />
	<xsl:param name="field_id" />
<!--
	<script type="text/javascript">
		oyster.editbuttons.install('<xsl:value-of select="$field_id" />');
	</script>
-->
	<!-- xhtml editor buttons -->
	<div style="display: none" id="oyster_editbuttons_{$field_id}_xhtml">
		<input value="b" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'strong', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="u" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'u', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="i" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'em', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="p" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'p', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="url" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'a', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="img" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'img', 0)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="list" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'ul', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="item" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'li', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="insert file" onclick="oyster.ajax.popup('{/swaf/@base}file/ajax_insert/?field_id={$field_id}&amp;handler=ajax');" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
	</div>

	<!-- bbcode editor buttons -->
	<div style="display: none" id="oyster_editbuttons_{$field_id}_bbcode">
		<input value="b" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'b', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="u" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'u', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="i" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'i', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="url" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'url', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="img" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'img', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="list" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', 'list', 1)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="item" onclick="oyster.editbuttons.insert_tag(this, '{$field_id}', '*', 0)" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
		<input value="insert file" onclick="oyster.ajax.popup('{/swaf/@base}file/ajax_insert/?field_id={$field_id}&amp;handler=ajax');" style="padding: 0px; padding-left: 2px; padding-right: 2px; margin: 1px; font-size: 10pt" type="button" />
	</div>
</xsl:template>
