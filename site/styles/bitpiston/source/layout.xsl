	<xsl:output method="xml" version="1.0" encoding="UTF-8" media-type="application/xhtml+xml" indent="yes"
		doctype-public="-//W3C//DTD XHTML 1.1//EN" doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" />

	<!-- Ajax Template -->

	<xsl:template match="/swaf[@handler = 'ajax']">
		<html xml:lang="en">

			<head>
				<meta http-equiv="content-type" content="application/xhtml+xml; charset=UTF-8" />

				<!-- mootools library -->
				<script src="{@styles}mootools.js" type="text/javascript"></script>

				<!-- oyster library -->
				<script src="{@styles}oyster.js" type="text/javascript"></script>
			</head>

			<!-- admin menu -->
			<xsl:if test="count(/swaf/menu[@id = 'admin']/menu) > 0 or count(/swaf/menu[@id = 'admin']/item) > 0">
				<div id="admin">
					<script type="text/javascript">
						function toggleMenu(menu_id, link) {
						      menu_element = document.getElementById(menu_id)
						      if (menu_element.className == '') {
						          link.title = 'Expand this menu'
						          menu_element.className = 'hidden'
						      } else {
						          link.title = 'Collapse this menu'
						          menu_element.className = ''
						      }
						  }
					</script>
					<a class="toggle" href="#" onclick="toggleMenu('admin', this)" title="Collapse this item">Administration</a>
					<xsl:if test="count(/swaf/menu[@id = 'admin']/item) > 0">
						<div>
							<span>Other</span>
							<ul>
								<xsl:for-each select="/swaf/menu[@id = 'admin']/item">
									<li><a href="{@url}"><xsl:value-of select="@label" /></a></li>
								</xsl:for-each>
							</ul>
						</div>
					</xsl:if>
					<xsl:for-each select="/swaf/menu[@id = 'admin']/menu">
						<xsl:sort select="position()" data-type="number" order="descending" />
						<div>
							<span><xsl:value-of select="@label" /></span>
							<ul>
								<xsl:for-each select="item">
									<li><a href="{@url}"><xsl:value-of select="@label" /></a></li>
								</xsl:for-each>
							</ul>
						</div>
					</xsl:for-each>
				</div>

				<!-- send admin to parent page -->
				<script type="text/javascript">
					parent.oyster.ajax.send(document.getElementById('admin').innerHTML, 'admin')
				</script>
			</xsl:if>

			<!-- this should essentially be whatever is in your "content" id div, in an ajax request, this will be inserted in place of the current content -->
			<div id="content">

					<!-- title -->
					<div id="title">
						<h1><xsl:apply-templates mode="heading" select="/swaf/*[1]" /></h1>
						<p>
							<xsl:if test="/swaf/content/@title = 'Home'">
								<xsl:attribute name="class">frontpage</xsl:attribute>
							</xsl:if>
							<xsl:apply-templates mode="description" select="/swaf/*[1]" />
						</p>
					</div>

					<!-- body -->
					<xsl:apply-templates mode="content" />
			</div>

			<!-- send content to parent page -->
			<script type="text/javascript">
				parent.oyster.ajax.send(document.getElementById('content').innerHTML, '<xsl:value-of select="/swaf/@ajax_target" />')
			</script>
		</html>
	</xsl:template>

	<!-- Base Template (Layout) -->

	<xsl:template match="/swaf[not(@handler)]">
		<html xml:lang="en">
			<head>
				<meta http-equiv="content-type" content="application/xhtml+xml; charset=UTF-8" />
				<meta http-equiv="content-style-type" content="text/css" />
				<title><xsl:apply-templates mode="heading" select="/swaf/*[1]" /> | <xsl:value-of select="@title" /></title>

				<!-- IE7.js for IE6 compatibility -->
				<xsl:comment>[if lt IE 7]&gt;&lt;script src="{@styles}ie7/ie7-standard-p.js" type="text/javascript"&gt;&lt;/script&gt;&lt;![endif]</xsl:comment>

				<!-- base stylesheet -->
				<link rel="stylesheet" type="text/css" media="screen, projection" href="{@styles}{@style}/base.css" />

				<!-- mootools library -->
				<script src="{@styles}mootools.js" type="text/javascript"></script>

				<!-- oyster library -->
				<script src="{@styles}oyster.js" type="text/javascript"></script>

				<!-- allow modules to hook into the head tag -->
				<xsl:apply-templates mode="html_head" />
			</head>
			<body>
				<div id="container">

					<!-- admin menu -->
					<xsl:if test="count(/swaf/menu[@id = 'admin']/item) > 0">
						<div id="admin">
							<script type="text/javascript">
								function toggleMenu(menu_id, link) {
								      menu_element = document.getElementById(menu_id)
								      if (menu_element.className == '') {
								          link.title = 'Expand this menu'
								          menu_element.className = 'hidden'
								      } else {
								          link.title = 'Collapse this menu'
								          menu_element.className = ''
								      }
								  }
							</script>
							<a class="toggle" href="#" onclick="toggleMenu('admin', this)" title="Collapse this item">Administration</a>
							<xsl:for-each select="/swaf/menu[@id = 'admin']/item">
								<xsl:sort select="position()" data-type="number" order="descending" />
								<div>
									<span>
										<xsl:choose>
											<xsl:when test="@label">
												<xsl:value-of select="@label" />
											</xsl:when>
											<xsl:otherwise>
												Other
											</xsl:otherwise>
										</xsl:choose>
									</span>
									<ul>
										<xsl:for-each select="item">
											<li><a href="{@url}"><xsl:value-of select="@label" /></a></li>
										</xsl:for-each>
									</ul>
								</div>
							</xsl:for-each>
						</div>
					</xsl:if>

					<!-- header / navigation -->
					<div id="header">
						<a href="{/swaf/@base}"><img src="{@styles}{@style}/images/header.logo.png" alt="BitPiston" /></a>
						<ul id="navigation">
							<xsl:for-each select="/swaf/menu[@id='navigation']/item">
								<li>
									<xsl:if test="@selected = 'true'">
										<xsl:attribute name="class">selected</xsl:attribute>
									</xsl:if>
									<a href="{@url}">
										<xsl:attribute name="title"><xsl:apply-templates /></xsl:attribute>
										<xsl:value-of select="@label" />
									</a>
								</li>
							</xsl:for-each>
						</ul>
						<ul id="user">
							<xsl:choose>
								<xsl:when test="user/@id > 0">
									<li><a href="{@base}user/settings/">Settings</a></li>
									<li><a href="{@base}user/profile/">Profile</a></li>
									<li><a href="{@base}logout/">Log Out</a></li>
								</xsl:when>
								<xsl:otherwise>
									<li><a href="{@base}login/">Client Login</a></li>
									<!--<li><a href="{@base}register/">Register</a></li>-->
								</xsl:otherwise>
							</xsl:choose>
						</ul>
					</div>
					<hr />

					<!-- content -->
					<div id="wrapper">
						<div id="content">

							<!-- title -->
							<div id="title">
								<h1><xsl:apply-templates mode="heading" select="/swaf/*[1]" /></h1>
								<p>
									<xsl:if test="/swaf/content/@title = 'Home'">
										<xsl:attribute name="class">frontpage</xsl:attribute>
									</xsl:if>
									<xsl:apply-templates mode="description" select="/swaf/*[1]" />
								</p>
							</div>

							<!-- body -->
							<!--
							<div id="#content-primary">
							-->
								<xsl:apply-templates mode="content" />
							<!--
							</div>
							<hr />
							-->

							<!-- sidebar -->
							<!--
							<div id="content-secondary">
							<xsl:apply-templates mode="sidebar" />
							</div>
							-->
						</div>
					</div>
					<hr />

					<!-- footer -->
					<div id="footer">
						<p class="copyright">Copyright &#169; 2007 BitPiston, <abbr title="Limited Liability Company">LLC</abbr>. All rights reserved.</p>
						<p class="links">
							<a href="/legal/privacy/">Privacy Policy</a> | 
							<a href="/legal/tos/">Terms of Service</a> | 
							<a href="/login/">Client Login</a> | 
							<a href="/about/jobs/">Jobs</a>
						</p>
					</div>
				</div>

				<!-- ajax popup -->
				<div id="oyster_ajax_popup_loading" style="display: none">
					Loading...
				</div>
				<div style="width: 650px;" id="sims_ajax_popup">
					<input type="button" value="Close" onclick="oyster.ajax.close_popup()" />
					<div id="oyster_ajax_popup_content"></div>
				</div>
				<div id="oyster_ajax_popup_overlay" />

				<!-- ajax communication frame -->
				<form id="oyster_ajax_form" method="post" action="" style="display: none">
				</form>
				<iframe id="oyster_ajax_iframe" style="height: 1px; width: 1px; border: 0px; margin: 0px; padding: 0px"></iframe>
			</body>
		</html>
	</xsl:template>
