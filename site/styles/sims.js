/*

SIMS Javascript Library

This are basically shortcuts to common MooTools tasks.

Most functions are available on all pages, however, some are called via sims/js.xsl.

This is part of SIMS and falls under the same licensing terms.

*/

//
// PUBLIC API
//

var sims = {

// Styling

/*
Description:
	Toggles the visibility of something
Prototype:
	sims.toggle_visibility(string some_element_id)
*/

toggle_visibility: function(id) {
	$(id).setStyle('display', ( $(id).getStyle('display') == 'block' ? 'none' : 'block' ))
},

/*
Description:
	Toggles a checkbox
Notes:
	* Does nothing if the id passed is not a checkbox
Prototype:
	sims.toggle_checkbox(some_checkbox_element_id)
*/

toggle_checkbox: function(id) {
	$(id).setProperty('checked', ( $(id).getProperty('checked') ? '' : 'checked' ))
},

// Ajax

ajax: {

	/*
	Description:
		Opens the ajax popup and requests a url to fill its contents
	Prototype:
		sims.ajax.popup(string url)
	*/

	popup: function(url) {

		// show the popup background overlay
		$('sims_ajax_popup_overlay').setStyle('height', window.getScrollHeight()) + window.getHeight();
		$('sims_ajax_popup_overlay').setStyle('display', 'block');


		// display the popup
		$('sims_ajax_popup').setStyle('display', 'block');

		// set the popup's content to the loading message
		$('sims_ajax_popup_content').innerHTML = $('sims_ajax_popup_loading').innerHTML;

		// center the popup
		sims.ajax.center_popup();

		// send the ajax request
		sims.ajax.submit_url(url, 'sims_ajax_popup_content');
	},

	/*
	Description:
		Closes the ajax popup
	Prototype:
		sims.ajax.close_popup()
	*/

	close_popup: function() {

		// hide the popup and background overlay
		$('sims_ajax_popup').setStyle('display', 'none');
		$('sims_ajax_popup_overlay').setStyle('display', 'none');

		// erase its contents
		sims.ajax.send('', 'sims_ajax_popup_content');

		// center it
		sims.ajax.center_popup();
	},

	/*
	Description:
		Submits a url via ajax and puts its contents into a div
	Prototype:
		sims.ajax.submit_url(string url, string content_div_id)
	*/

	submit_url: function(url, content_id) {
		var query_string = 'handler=ajax&ajax_target=' + content_id;
		if (url.indexOf('?') == -1) {
			url += '?' + query_string;
		} else if (url.substr(-1) == '&' || url.substr(-1) == '?') {
			url += query_string;
		} else {
			url += '&' + query_string;
		}
		$('sims_ajax_form').action = url;
		sims.ajax.submit_form('sims_ajax_form', content_id);
	},

	/*
	Description:
		Submits a form via ajax and puts its contents into a div
	Prototype:
		sims.ajax.submit_form(string form_id, string content_id)
	*/

	submit_form: function(form_id, content_id) {
		var form             = $(form_id);
		var old_form_action  = form.action;
		var old_form_target  = form.target;

		var query_string     = 'handler=ajax&ajax_target=' + content_id;
		if (form.action.indexOf('?') == -1) {
			form.action += '?' + query_string;
		} else if (form.action.substr(-1) == '&' || form.action.substr(-1) == '?') {
			form.action += query_string;
		} else {
			form.action += '&' + query_string;
		}

		form.target          = 'sims_ajax_iframe';

		form.submit();

		form.target          = old_form_target;
		form.action          = old_form_action;
	},

	send: function(xml, content_id) {
		$(content_id).innerHTML = xml;
		if (content_id == 'sims_ajax_popup_content') {
			sims.ajax.center_popup();
		}
	},

	center_popup: function() {
		var browser_width  = window.getWidth();
		var popup_width    = $('sims_ajax_popup').getStyle('width').replace('px', ''); // remove px -- what happens if it's em?
		var horiz_padding  = browser_width / 2 - popup_width / 2;
		$('sims_ajax_popup').setStyle('left', horiz_padding);

		var browser_height = window.getHeight();
		var popup_height   = $('sims_ajax_popup').getStyle('height').replace('px', ''); // remove px -- what happens if it's em?
		var vert_padding   = browser_height / 2 - popup_height / 2;
		$('sims_ajax_popup').setStyle('top', vert_padding);
	}
},

//
// PRIVATE API
//

// Edit Buttons

editbuttons: {

	/*
	Description:
		Initiates editbuttons for a field with a translation type
	Notes:
		* There must be a corresponding translation mode field with the name field_id_translation_mode
	Prototype:
		sims.editbuttons.install(string field_id)
	*/

	install: function(field_id) {
		var translation_mode_field_id = field_id + '_translation_mode';

		// add event so when translation mode is updated, so are the edit buttons
		$(translation_mode_field_id).addEvent('change', function() { sims.editbuttons.populate(field_id) });

		// set initial edit buttons
		sims.editbuttons.populate(field_id)
	},

	/*
	Description:
		Updates an editbuttons div based on the translation mode
	Notes:
		* There must be a corresponding translation mode field with the name field_id_translation_mode
	Prototype:
		sims.editbuttons.populate(string field_id)
	*/

	populate: function(field_id) {
		var translation_mode_field_id = field_id + '_translation_mode';

		// bbcode translation mode
		if ($(translation_mode_field_id).getValue() == 'bbcode') {
			$('sims_editbuttons_' + field_id + '_bbcode').setStyle('display', 'block');
			$('sims_editbuttons_' + field_id + '_xhtml').setStyle('display', 'none');
		}

		// xhtml translation mode
		if ($(translation_mode_field_id).getValue() == 'xhtml') {
			$('sims_editbuttons_' + field_id + '_bbcode').setStyle('display', 'none');
			$('sims_editbuttons_' + field_id + '_xhtml').setStyle('display', 'block');
		}
	},

	/*
	Description:
		Inserts a simple bbcode or xhtml tag
	Prototype:
		sims.editbuttons.insert_tag(obj triggering_button, string field_id, string tag, bool wrap)
	*/

	insert_tag: function (triggering_button, field_id, tag, wrap) {
		field = $(field_id)
		var translation_mode_field = $( field_id + '_translation_mode' );

		// get translation mode (bbcode or xhtml)
		var start_tag;
		var end_tag;
		if (translation_mode_field.getValue() == 'bbcode') {
			start_tag = '[' + tag + ']';
			end_tag   = '[/' + tag + ']';
		}
		else if (translation_mode_field.getValue() == 'xhtml') {
			start_tag = '<' + tag + '>';
			end_tag   = '</' + tag + '>';
		}

		// IE support
		if (document.selection) {
			field.focus();
			var sel = document.selection.createRange()
			if (triggering_button.value.substring(0, 1) == '/') {
				triggering_button.value = triggering_button.value.substring(1, triggering_button.value.length);
				sel.text = end_tag;
			} else {
				triggering_button.value = '/' + triggering_button.value;
				sel.text = start_tag;
			}
		}

		// Mozilla support
		else if (field.selectionStart || field.selectionStart == '0') {
			var start_pos = field.selectionStart;
			var end_pos   = field.selectionEnd;
			if (start_pos == end_pos || wrap == 0) {
				if (triggering_button.value.substring(0, 1) == '/') {
					triggering_button.value = triggering_button.value.substring(1, triggering_button.value.length);
					field.value = field.value.substring(0, start_pos)
						+ end_tag
						+ field.value.substring(start_pos, field.value.length);
				} else {
			      	triggering_button.value = '/' + triggering_button.value;
					field.value = field.value.substring(0, start_pos)
						+ start_tag
						+ field.value.substring(start_pos, field.value.length);
				}
			} else {
				field.value = field.value.substring(0, start_pos)
					+ start_tag
					+ field.value.substring(start_pos, end_pos)
					+ end_tag
					+ field.value.substring(end_pos, field.value.length);
			}
			field.focus();
		}

		// Otherwise, just append
		else {
			if (triggering_button.value.substring(0, 1) == '/') {
				triggering_button.value = triggering_button.value.substring(1, triggering_button.value.length);
				field.value += end_tag;
			} else {
				triggering_button.value = '/' + triggering_button.value;
				field.value += start_tag;
			}
		}
	},

	/*
	Description:
		Inserts the proper bbcode or xhtml to include a file
	Prototype:
		sims.editbuttons.insert_file(string field_id, int file_id)
	*/
	insert_file: function (field_id, file_id) {
		var translation_mode_field_id = field_id + '_translation_mode';

		if ($(translation_mode_field_id).getValue() == 'bbcode') {
			$(field_id).value += '[include#' + file_id + ']';
		}
		else if ($(translation_mode_field_id).getValue() == 'xhtml') {
			$(field_id).value += '<!--include#' + file_id + '-->';
		}
	}
}
}

/*

Copyright etc etc

*/