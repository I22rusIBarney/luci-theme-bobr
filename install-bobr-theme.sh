#!/bin/sh
# Тема «Бобр» для LuCI (OpenWrt 23.05) + Панель в духе Keenetic.
# Установка:  sh install-bobr-theme.sh        Откат на стандартную тему:  sh install-bobr-theme.sh --remove
set -e
if [ "$1" = "--remove" ]; then
  uci set luci.main.mediaurlbase=/luci-static/bootstrap; uci -q delete luci.themes.Bobr || true; uci commit luci
  rm -rf /usr/share/ucode/luci/template/themes/bobr /www/luci-static/bobr /www/luci-static/resources/menu-bobr.js \
         /www/luci-static/resources/view/bobr /usr/share/luci/menu.d/luci-app-bobr-dashboard.json \
         /usr/share/rpcd/acl.d/luci-app-bobr-dashboard.json /tmp/luci-*
  /etc/init.d/rpcd restart
  echo "Тема и Панель удалены, включена стандартная тема. Обновите страницу роутера."; exit 0
fi
[ -f /www/luci-static/bootstrap/cascade.css ] || { echo "Нет стандартной темы bootstrap: opkg install luci-theme-bootstrap"; exit 1; }
mkdir -p /usr/share/ucode/luci/template/themes/bobr /www/luci-static/bobr /www/luci-static/resources/view/bobr /usr/share/luci/menu.d /usr/share/rpcd/acl.d
cat > /usr/share/ucode/luci/template/themes/bobr/header.ut <<'BOBR_EOF'
{#
 Тема «Бобр» для LuCI (OpenWrt 23.05): боковое меню, карточки, светлая и тёмная версии.
 Основана на luci-theme-bootstrap (Apache License 2.0).
-#}
{%
	import { getuid, getspnam } from 'luci.core';
	const boardinfo = ubus.call('system', 'board');
	http.prepare_content('text/html; charset=UTF-8');
-%}
<!DOCTYPE html>
<html lang="{{ dispatcher.lang }}">
	<head>
		<meta charset="utf-8">
		<title>{{ striptags(`${boardinfo.hostname ?? '?'}${node ? ` - ${node.title}` : ''}`) }} - LuCI</title>
		<script type="text/javascript">
			(function() {
				var root = document.documentElement, mq = window.matchMedia('(prefers-color-scheme: dark)');
				window.bobrApplyTheme = function() {
					var m = 'auto';
					try { m = localStorage.getItem('bobr-theme') || 'auto'; } catch (e) {}
					root.setAttribute('data-theme-mode', m);
					root.setAttribute('data-darkmode', m == 'dark' || (m == 'auto' && mq.matches));
				};
				mq.addEventListener('change', window.bobrApplyTheme);
				window.bobrApplyTheme();
			})();
		</script>
		<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<meta name="theme-color" content="#2a6df4">
		<link rel="stylesheet" href="{{ media }}/cascade.css">
		<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='8' fill='%232a6df4'/%3E%3Cpath d='M9 19a7 7 0 0 1 14 0' stroke='white' stroke-width='2.4' fill='none' stroke-linecap='round'/%3E%3Ccircle cx='16' cy='20' r='2.2' fill='white'/%3E%3C/svg%3E">
		{% if (node?.css): %}
		<link rel="stylesheet" href="{{ resource }}/{{ node.css }}">
		{% endif %}
		{% if (css): %}
		<style title="text/css">{{ css }}</style>
		{% endif %}
		<script src="{{ dispatcher.build_url('admin/translations', dispatcher.lang) }}"></script>
		<script src="{{ resource }}/cbi.js"></script>
		<script src="{{ media }}/names.js"></script>
	</head>

	<body class="bobr lang_{{ dispatcher.lang }} {{ blank_page ? 'bobr-blank' : '' }} {{ entityencode(striptags(node?.title ?? ''), true) }}" data-page="{{ entityencode(join('-', ctx.request_path), true) }}">
		{% if (!blank_page): %}
		<aside id="sidebar">
			<a class="bobr-brand" href="/">
				<span class="bobr-logo"><svg viewBox="0 0 32 32" aria-hidden="true"><path d="M9 19a7 7 0 0 1 14 0" stroke="currentColor" stroke-width="2.4" fill="none" stroke-linecap="round"/><path d="M5 15.5a11.5 11.5 0 0 1 22 0" stroke="currentColor" stroke-width="2.4" fill="none" stroke-linecap="round" opacity=".55"/><circle cx="16" cy="20.5" r="2.4" fill="currentColor"/></svg></span>
				<span class="bobr-host">{{ striptags(boardinfo.hostname ?? '?') }}<small>{{ striptags(boardinfo.model ?? '') }}</small></span>
			</a>
			<nav id="sidemenu"></nav>
			<div class="bobr-side-bottom" id="sidebottom"></div>
		</aside>
		<div id="sidebar-overlay"></div>
		<div id="page">
		<header class="topbar">
			<button id="menutoggle" type="button" aria-label="Меню"><span></span><span></span><span></span></button>
			<div class="crumbs" id="crumbs"></div>
			<div id="indicators" class="pull-right"></div>
		</header>

		<div id="maincontent" class="container">
			{% if (getuid() == 0 && getspnam('root')?.pwdp === ''): %}
				<div class="alert-message warning">
					<h4>{{ _('No password set!') }}</h4>
					<p>{{ _('There is no password set on this router. Please configure a root password to protect the web interface.') }}</p>
					{% if (dispatcher.lookup("admin/system/admin")): %}
					  <div class="right"><a class="btn" href="{{ dispatcher.build_url("admin/system/admin") }}">{{ _('Go to password configuration...') }}</a></div>
					{% endif %}
				</div>
			{% endif %}

			{% if (boardinfo.rootfs_type == "initramfs"): %}
				<div class="alert-message warning">
					<h4>{{ _('System running in recovery (initramfs) mode.') }}</h4>
					<p>{{ _('No changes to settings will be stored and are lost after rebooting. This mode should only be used to install a firmware upgrade') }}</p>
					{% if (dispatcher.lookup("admin/system/flash")): %}
					  <div class="right"><a class="btn" href="{{ dispatcher.build_url("admin/system/flash") }}">{{ _('Go to firmware upgrade...') }}</a></div>
					{% endif %}
				</div>
			{% endif %}

			<noscript>
				<div class="alert-message warning">
					<h4>{{ _('JavaScript required!') }}</h4>
					<p>{{ _('You must enable JavaScript in your browser or LuCI will not work properly.') }}</p>
				</div>
			</noscript>

			<div id="tabmenu" style="display:none"></div>
		{% endif %}
BOBR_EOF
cat > /usr/share/ucode/luci/template/themes/bobr/footer.ut <<'BOBR_EOF'
{#
 Тема «Бобр» для LuCI. Основана на luci-theme-bootstrap (Apache License 2.0).
-#}
		{% if (!blank_page): %}
		</div>
		<footer>
			<span>
				<a href="https://github.com/openwrt/luci" target="_blank" rel="noreferrer">{{ version.luciname }} ({{ version.luciversion }})</a>
				·
				<a href="{{ entityencode(version.disturl ?? '#', true) }}" target="_blank" rel="noreferrer">{{ version.distname }} {{ version.distversion }} ({{ version.distrevision }})</a>
				{% if (lua_active): %}
					· {{ _('Lua compatibility mode active') }}
				{% endif %}
			</span>
		</footer>
		</div>
		<script type="text/javascript">L.require('menu-bobr')</script>
		{% endif %}
	</body>
</html>
BOBR_EOF
cat > /usr/share/ucode/luci/template/themes/bobr/sysauth.ut <<'BOBR_EOF'
{#
 Тема «Бобр» для LuCI: страница входа. Основана на luci-theme-bootstrap (Apache License 2.0).
-#}

{% include('header', { blank_page: true }) %}

<section hidden>
	<div class="bobr-login-brand">
		<span class="bobr-logo"><svg viewBox="0 0 32 32" aria-hidden="true"><path d="M9 19a7 7 0 0 1 14 0" stroke="currentColor" stroke-width="2.4" fill="none" stroke-linecap="round"/><path d="M5 15.5a11.5 11.5 0 0 1 22 0" stroke="currentColor" stroke-width="2.4" fill="none" stroke-linecap="round" opacity=".55"/><circle cx="16" cy="20.5" r="2.4" fill="currentColor"/></svg></span>
	</div>
	<form method="post" class="cbi-map">
		<div class="cbi-section">
			<div class="cbi-section-node">
				<div class="cbi-value">
					<label class="cbi-value-title" for="luci_username">{{ _('Username') }}</label>
					<div class="cbi-value-field">
						<input name="luci_username" id="luci_username" type="text" autocomplete="username" value="{{ entityencode(duser, true) }}">
					</div>
				</div>
				<div class="cbi-value">
					<label class="cbi-value-title" for="luci_password">{{ _('Password') }}</label>
					<div class="cbi-value-field">
						<input name="luci_password" id="luci_password" type="password" autocomplete="current-password">
					</div>
				</div>
			</div>
		</div>
	</form>

	{% if (fuser): %}
	<div class="alert-message error">
		{{ _('Invalid username and/or password! Please try again.') }}
	</div>
	{% endif %}

	<button class="btn cbi-button-positive important">{{ _('Log in') }}</button>
</section>

<div id="view">
	<div class="spinning">{{ _('Loading view…') }}</div>
	<script type="text/javascript">
		L.require('ui').then(function(ui) {
			ui.instantiateView('bootstrap.sysauth');
		});
	</script>
</div>

{% include('footer', { blank_page: true }) %}
BOBR_EOF
cat > /www/luci-static/bobr/cascade.css <<'BOBR_EOF'
/*
 * Тема «Бобр» для LuCI (OpenWrt 23.05)
 * Боковое меню, карточки, светлая и тёмная версии.
 * Поверх стандартной темы bootstrap (Apache License 2.0): все её компоненты работают,
 * здесь меняются раскладка и внешний вид.
 */
@import url("../bootstrap/cascade.css");
@import url("../bootstrap/mobile.css") only screen and (max-width: 860px);

/* ---------- Цвета ---------- */
:root {
	--background-color-h: 218;
	--background-color-s: 22%;
	--background-color-l: 100%;
	--text-color-h: 222;
	--text-color-s: 28%;
	--text-color-l: 12%;

	--primary-color-high: #2a6df4;
	--primary-color-medium: #1f5fe0;
	--primary-color-low: #174bc0;
	--on-primary-color: #fff;

	--b-bg: #f2f4f8;
	--b-card: #ffffff;
	--b-side: #ffffff;
	--b-line: #e3e7ee;
	--b-line-soft: #eef1f5;
	--b-text: #1b2333;
	--b-muted: #6b7486;
	--b-hover: #f1f4f9;
	--b-chip: #e9edf3;
	--b-accent: #2a6df4;
	--b-accent-soft: rgba(42, 109, 244, .1);
	--b-ok: #12a150;
	--b-warn: #e5a50a;
	--b-err: #e5484d;
	--b-shadow: 0 1px 2px rgba(16, 24, 40, .05), 0 1px 3px rgba(16, 24, 40, .06);
	--b-shadow-lg: 0 12px 32px rgba(16, 24, 40, .14);
	--b-radius: 14px;
	--b-radius-sm: 10px;
	--b-side-w: 252px;
	color-scheme: light;
}

:root[data-darkmode="true"] {
	--background-color-h: 216;
	--background-color-s: 18%;
	--background-color-l: 12%;
	--text-color-h: 216;
	--text-color-s: 20%;
	--text-color-l: 96%;

	--primary-color-high: #4c8dff;
	--primary-color-medium: #3b7cf0;
	--primary-color-low: #2d6ad8;

	--b-bg: #0e131a;
	--b-card: #161c25;
	--b-side: #121821;
	--b-line: #252e3b;
	--b-line-soft: #1e2632;
	--b-text: #e7eaf0;
	--b-muted: #8d96a7;
	--b-hover: #1c2430;
	--b-chip: #1d2530;
	--b-accent: #4c8dff;
	--b-accent-soft: rgba(76, 141, 255, .14);
	--b-ok: #2fbf71;
	--b-warn: #f0b429;
	--b-err: #ff6b6b;
	--b-shadow: 0 1px 2px rgba(0, 0, 0, .3);
	--b-shadow-lg: 0 16px 40px rgba(0, 0, 0, .5);
	color-scheme: dark;
}

/* ---------- Основа ---------- */
body.bobr {
	display: block;
	padding: 0;
	margin: 0;
	min-height: 100vh;
	background: var(--b-bg);
	color: var(--b-text);
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
	font-size: 14px;
	line-height: 1.5;
	-webkit-font-smoothing: antialiased;
}

body.bobr label, body.bobr input, body.bobr button, body.bobr select, body.bobr textarea {
	font-family: inherit;
	font-size: 14px;
}

body.bobr a { color: var(--b-accent); }
body.bobr a:hover { color: var(--primary-color-low); text-decoration: none; }

/* ---------- Боковое меню ---------- */
#sidebar {
	position: fixed;
	top: 0;
	left: 0;
	bottom: 0;
	width: var(--b-side-w);
	background: var(--b-side);
	border-right: 1px solid var(--b-line);
	display: flex;
	flex-direction: column;
	z-index: 900;
	overflow-y: auto;
	overscroll-behavior: contain;
	transition: transform .22s ease;
}

.bobr-brand {
	display: flex;
	align-items: center;
	gap: 12px;
	padding: 20px 20px 16px;
	color: var(--b-text) !important;
	text-decoration: none !important;
}

.bobr-logo {
	flex: 0 0 38px;
	height: 38px;
	border-radius: 11px;
	background: linear-gradient(135deg, #3b82ff, #1f5fe0);
	color: #fff;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	box-shadow: 0 4px 12px rgba(42, 109, 244, .35);
}

.bobr-logo svg { width: 26px; height: 26px; }

.bobr-host {
	display: flex;
	flex-direction: column;
	font-size: 16px;
	font-weight: 650;
	line-height: 1.2;
	min-width: 0;
}

.bobr-host small {
	font-size: 12px;
	font-weight: 400;
	color: var(--b-muted);
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

#sidemenu { flex: 1; padding: 4px 0 12px; }

.side-cats, .side-sub { list-style: none; margin: 0; padding: 0; }

.side-head {
	display: flex;
	align-items: center;
	gap: 12px;
	margin: 2px 12px;
	padding: 10px 12px;
	border-radius: var(--b-radius-sm);
	color: var(--b-text) !important;
	font-weight: 550;
	text-decoration: none !important;
	transition: background .15s;
}

.side-head:hover { background: var(--b-hover); }

.side-cat.active > .side-head { color: var(--b-accent) !important; }
.side-cat.active:not(.open) > .side-head { background: var(--b-accent-soft); }

.bobr-ico {
	flex: 0 0 20px;
	width: 20px;
	height: 20px;
	fill: none;
	stroke: currentColor;
	stroke-width: 1.8;
	stroke-linecap: round;
	stroke-linejoin: round;
	opacity: .9;
}

.side-head span { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.bobr-chev {
	width: 16px;
	height: 16px;
	fill: none;
	stroke: var(--b-muted);
	stroke-width: 2;
	stroke-linecap: round;
	stroke-linejoin: round;
	transition: transform .2s;
}

.side-cat.open .bobr-chev { transform: rotate(90deg); }

.side-sub {
	display: none;
	margin: 2px 12px 6px 30px;
	padding-left: 14px;
	border-left: 1px solid var(--b-line);
}

.side-cat.open .side-sub { display: block; }

.side-sub a {
	display: block;
	padding: 7px 12px;
	margin: 1px 0;
	border-radius: 8px;
	color: var(--b-muted) !important;
	text-decoration: none !important;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.side-sub a:hover { color: var(--b-text) !important; background: var(--b-hover); }

.side-sub li.active a {
	color: var(--b-accent) !important;
	background: var(--b-accent-soft);
	font-weight: 600;
}

.bobr-side-bottom {
	padding: 10px 12px 16px;
	border-top: 1px solid var(--b-line);
	display: flex;
	flex-direction: column;
	gap: 2px;
}

.side-mode, .side-logout {
	display: flex;
	align-items: center;
	gap: 12px;
	width: 100%;
	padding: 9px 12px;
	border: 0;
	border-radius: var(--b-radius-sm);
	background: transparent;
	color: var(--b-muted) !important;
	font-size: 14px;
	text-align: left;
	cursor: pointer;
	text-decoration: none !important;
	box-shadow: none;
}

.side-mode:hover, .side-logout:hover { background: var(--b-hover); color: var(--b-text) !important; }
.side-logout:hover { color: var(--b-err) !important; }

#sidebar-overlay { display: none; }

/* ---------- Страница и шапка ---------- */
#page {
	margin-left: var(--b-side-w);
	min-height: 100vh;
	display: flex;
	flex-direction: column;
}

header.topbar {
	position: sticky;
	top: 0;
	z-index: 800;
	display: flex;
	align-items: center;
	gap: 14px;
	min-height: 60px;
	margin: 0;
	padding: 0 32px;
	background: color-mix(in srgb, var(--b-bg) 82%, transparent);
	-webkit-backdrop-filter: saturate(160%) blur(12px);
	backdrop-filter: saturate(160%) blur(12px);
	border-bottom: 1px solid var(--b-line);
	box-shadow: none;
	color: var(--b-text);
}

#menutoggle {
	display: none;
	flex-direction: column;
	justify-content: center;
	gap: 4px;
	width: 38px;
	height: 38px;
	padding: 0 9px;
	border: 1px solid var(--b-line);
	border-radius: var(--b-radius-sm);
	background: var(--b-card);
	box-shadow: none;
	cursor: pointer;
}

#menutoggle span { display: block; height: 2px; border-radius: 2px; background: var(--b-text); }

.crumbs { display: flex; align-items: baseline; gap: 8px; min-width: 0; }

.crumb-cat { color: var(--b-muted); font-size: 14px; white-space: nowrap; }
.crumb-cat::after { content: "›"; margin-left: 8px; }

.crumb-page {
	font-size: 17px;
	font-weight: 650;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

header.topbar .pull-right { margin-left: auto; margin-right: 0; display: flex; flex-wrap: wrap; gap: 6px; justify-content: flex-end; }

header.topbar [data-indicator] {
	margin: 0;
	padding: 5px 11px;
	border-radius: 999px;
	font-size: 12px;
	font-weight: 600;
	text-transform: none;
	letter-spacing: 0;
	color: var(--b-muted);
	background: var(--b-chip);
}

header.topbar [data-indicator][data-style="active"] {
	color: #fff;
	background: var(--b-accent);
}

#maincontent.container {
	width: 100%;
	max-width: 1200px;
	margin: 0 auto;
	padding: 26px 32px 32px;
	box-sizing: border-box;
	flex: 1;
}

footer {
	margin: 0;
	padding: 18px 32px 22px;
	border-top: 0;
	color: var(--b-muted);
	font-size: 12px;
	justify-content: center;
}

footer a { color: var(--b-muted) !important; }
footer a:hover { color: var(--b-accent) !important; }

/* ---------- Заголовки ---------- */
body.bobr h2 {
	font-size: 24px;
	line-height: 1.25;
	font-weight: 700;
	margin: 0 0 6px;
	color: var(--b-text);
	letter-spacing: -.01em;
}

body.bobr h3, body.bobr legend, body.bobr fieldset legend {
	font-size: 16px;
	line-height: 1.35;
	font-weight: 650;
	margin: 0 0 12px;
	padding: 0;
	color: var(--b-text);
	border: 0;
}

body.bobr h4 { font-size: 15px; font-weight: 650; }

.cbi-map-descr, .cbi-section-descr {
	color: var(--b-muted);
	margin-bottom: 18px;
}

/* ---------- Карточки ---------- */
#view > .cbi-section,
#view > div > .cbi-section,
.cbi-map > .cbi-section,
.cbi-map > div > .cbi-section,
#view > fieldset.cbi-section,
#maincontent > .cbi-section,
#maincontent > form > .cbi-section,
#maincontent > fieldset {
	background: var(--b-card);
	border: 1px solid var(--b-line);
	border-radius: var(--b-radius);
	box-shadow: var(--b-shadow);
	padding: 20px 22px;
	margin: 0 0 18px;
}

.cbi-section .cbi-section {
	background: transparent;
	border: 0;
	box-shadow: none;
	padding: 0;
}

fieldset { margin-bottom: 0; padding-top: 0; }

/* ---------- Вкладки: сегментированный переключатель ---------- */
#tabmenu { margin-bottom: 18px; }

body.bobr .tabs, body.bobr .cbi-tabmenu {
	display: inline-flex;
	flex-wrap: wrap;
	gap: 4px;
	max-width: 100%;
	margin: 0 0 18px;
	padding: 4px;
	background: var(--b-chip) !important;
	border-radius: 12px;
	box-sizing: border-box;
}

body.bobr #tabmenu .tabs { margin-bottom: 8px; }
body.bobr #tabmenu .tabs + .tabs { display: flex; width: fit-content; }

body.bobr .tabs > li, body.bobr .cbi-tabmenu > li {
	height: auto;
	max-width: none;
	margin: 0;
	border: 0 !important;
	border-radius: 9px;
	background: transparent !important;
	color: var(--b-muted);
}

body.bobr .tabs > li > a, body.bobr .cbi-tabmenu > li > a {
	padding: 7px 14px;
	line-height: 1.3;
	border-radius: 9px;
	color: inherit;
	font-weight: 550;
}

body.bobr .tabs > li:not(.active):hover, body.bobr .cbi-tabmenu > .cbi-tab-disabled:hover {
	color: var(--b-text);
	background: color-mix(in srgb, var(--b-card) 55%, transparent) !important;
}

body.bobr .tabs > li.active, body.bobr .cbi-tabmenu > li.cbi-tab {
	background: var(--b-card) !important;
	color: var(--b-text);
	box-shadow: var(--b-shadow);
}

/* ---------- Таблицы ---------- */
body.bobr .table {
	border: 0;
	border-collapse: separate;
	border-spacing: 0;
	width: 100%;
	margin-bottom: 4px;
}

body.bobr .table .th {
	padding: 10px 12px;
	font-size: 12px;
	font-weight: 600;
	color: var(--b-muted);
	text-transform: uppercase;
	letter-spacing: .04em;
	background: transparent;
	border-top: 0;
	border-bottom: 1px solid var(--b-line);
}

body.bobr .table .td {
	padding: 11px 12px;
	border-top: 1px solid var(--b-line-soft);
	vertical-align: middle;
}

body.bobr .table .tr:first-child .td { border-top: 0; }

body.bobr .table .td.left[width="33%"],
body.bobr .table .tr > .td:first-child[width="33%"] { color: var(--b-muted); }

body.bobr .cbi-section-table .tr:hover .td,
body.bobr .cbi-section-table .tr:hover .th,
body.bobr .cbi-section-table .tr:hover::before { background: var(--b-hover); }

body.bobr .cbi-section-table-row .td:first-child { border-radius: 8px 0 0 8px; }
body.bobr .cbi-section-table-row .td:last-child { border-radius: 0 8px 8px 0; }

/* ---------- Поля формы ---------- */
body.bobr .cbi-value {
	margin: 0;
	padding: 13px 0;
	border-top: 1px solid var(--b-line-soft);
	align-items: center;
}

body.bobr .cbi-section-node > .cbi-value:first-child,
body.bobr .cbi-section-node .cbi-value:first-of-type { border-top: 0; }

body.bobr .cbi-value label.cbi-value-title {
	flex: 0 0 240px;
	padding-top: 0;
	font-size: 14px;
	font-weight: 500;
	color: var(--b-text);
}

body.bobr .cbi-value-field { margin-left: 16px; }

body.bobr .cbi-value-description {
	color: var(--b-muted);
	font-size: 13px;
	margin-top: 4px;
}

body.bobr input[type="text"],
body.bobr input[type="password"],
body.bobr input[type="number"],
body.bobr input[type="email"],
body.bobr input[type="url"],
body.bobr input[type="search"],
body.bobr input:not([type]),
body.bobr select,
body.bobr textarea,
body.bobr .cbi-dropdown:not(.btn):not(.cbi-button) {
	min-height: 38px;
	padding: 0 12px;
	border: 1px solid var(--b-line);
	border-radius: var(--b-radius-sm);
	background-color: var(--b-card);
	color: var(--b-text);
	box-shadow: none;
	box-sizing: border-box;
	transition: border-color .15s, box-shadow .15s;
}

body.bobr textarea { padding: 10px 12px; }

body.bobr input:focus, body.bobr select:focus, body.bobr textarea:focus,
body.bobr .cbi-dropdown:not(.btn):not(.cbi-button):focus,
body.bobr .cbi-dropdown[open] {
	border-color: var(--b-accent) !important;
	box-shadow: 0 0 0 3px var(--b-accent-soft) !important;
	outline: none;
}

body.bobr .cbi-dropdown > ul.dropdown {
	border-radius: var(--b-radius-sm);
	border: 1px solid var(--b-line);
	box-shadow: var(--b-shadow-lg);
	background: var(--b-card);
}

body.bobr input[type="checkbox"] { accent-color: var(--b-accent); width: 18px; height: 18px; }

/* ---------- Кнопки ---------- */
body.bobr .btn, body.bobr .cbi-button, body.bobr button:not(#menutoggle):not(.side-mode) {
	min-height: 36px;
	padding: 0 16px;
	border: 1px solid var(--b-line);
	border-radius: var(--b-radius-sm);
	background: var(--b-card);
	color: var(--b-text);
	font-weight: 550;
	line-height: 34px;
	text-shadow: none;
	box-shadow: var(--b-shadow);
	transition: background .15s, border-color .15s, color .15s, transform .05s;
	background-image: none;
}

body.bobr .btn:hover, body.bobr .cbi-button:hover { border-color: color-mix(in srgb, var(--b-accent) 40%, var(--b-line)); text-decoration: none; }
body.bobr .btn:active, body.bobr .cbi-button:active { transform: translateY(1px); }

body.bobr .btn.primary,
body.bobr .cbi-button-apply,
body.bobr .cbi-button-action.important,
body.bobr .cbi-button-positive.important,
body.bobr .cbi-page-actions .cbi-button-save,
body.bobr .cbi-button-add,
body.bobr .modal .btn.primary,
body.bobr .modal .cbi-button-positive {
	background: var(--b-accent) !important;
	border-color: var(--b-accent) !important;
	color: #fff !important;
}

body.bobr .btn.primary:hover,
body.bobr .cbi-button-apply:hover,
body.bobr .cbi-button-action.important:hover,
body.bobr .cbi-button-positive.important:hover,
body.bobr .cbi-page-actions .cbi-button-save:hover,
body.bobr .cbi-button-add:hover {
	background: var(--primary-color-medium) !important;
}

body.bobr .cbi-button-edit, body.bobr .cbi-button-action:not(.important), body.bobr .cbi-button-neutral {
	color: var(--b-accent);
	background: var(--b-accent-soft);
	border-color: transparent;
	box-shadow: none;
}

body.bobr .cbi-button-positive:not(.important), body.bobr .cbi-button-save:not(.cbi-page-actions *) {
	color: var(--b-ok);
	border-color: color-mix(in srgb, var(--b-ok) 35%, var(--b-line));
}

body.bobr .cbi-button-remove,
body.bobr .cbi-button-negative,
body.bobr .cbi-button-reset,
body.bobr .btn.danger {
	color: var(--b-err) !important;
	background: var(--b-card) !important;
	border-color: color-mix(in srgb, var(--b-err) 35%, var(--b-line)) !important;
}

body.bobr .cbi-button-remove:hover,
body.bobr .cbi-button-negative:hover,
body.bobr .cbi-button-reset:hover { background: color-mix(in srgb, var(--b-err) 8%, var(--b-card)) !important; }

body.bobr .btn[disabled], body.bobr .cbi-button[disabled] { opacity: .5; }

/* Кнопки «Сохранить / Применить» внизу — прилипают к низу экрана */
body.bobr .cbi-page-actions {
	position: sticky;
	bottom: 12px;
	z-index: 50;
	display: flex;
	flex-wrap: wrap;
	justify-content: flex-end;
	align-items: center;
	gap: 8px;
	margin: 6px 0 0;
	padding: 12px 14px;
	background: color-mix(in srgb, var(--b-card) 88%, transparent);
	-webkit-backdrop-filter: blur(10px);
	backdrop-filter: blur(10px);
	border: 1px solid var(--b-line);
	border-radius: var(--b-radius);
	box-shadow: var(--b-shadow-lg);
}

body.bobr .cbi-page-actions > * { margin: 0 !important; float: none !important; }
body.bobr .cbi-page-actions form { display: inline-flex; }

/* ---------- Сообщения ---------- */
body.bobr .alert-message {
	border: 1px solid var(--b-line);
	border-left: 4px solid var(--b-accent);
	border-radius: var(--b-radius-sm);
	background: var(--b-card);
	color: var(--b-text);
	box-shadow: var(--b-shadow);
	padding: 14px 16px;
	text-shadow: none;
	background-image: none;
}

body.bobr .alert-message.warning { border-left-color: var(--b-warn); }
body.bobr .alert-message.error, body.bobr .alert-message.danger { border-left-color: var(--b-err); }
body.bobr .alert-message.success { border-left-color: var(--b-ok); }

/* ---------- Окна ---------- */
body.bobr #modal_overlay {
	background: rgba(10, 14, 20, .45);
	-webkit-backdrop-filter: blur(4px);
	backdrop-filter: blur(4px);
}

body.bobr .modal {
	border: 1px solid var(--b-line);
	border-radius: 18px;
	background: var(--b-card);
	box-shadow: var(--b-shadow-lg);
	padding: 22px 24px;
}

/* ---------- Интерфейсы и мелочи ---------- */
body.bobr .ifacebox {
	border: 1px solid var(--b-line);
	border-radius: 12px;
	background: var(--b-card);
	box-shadow: var(--b-shadow);
	overflow: hidden;
}

body.bobr .ifacebox .ifacebox-head { font-weight: 650; padding: 6px 8px; }

body.bobr .cbi-progressbar {
	border: 0;
	border-radius: 999px;
	background: var(--b-chip);
	height: 20px;
	overflow: hidden;
}

body.bobr .cbi-progressbar > div {
	background: linear-gradient(90deg, #3b82ff, #2a6df4);
	border-radius: 999px;
}

body.bobr .cbi-progressbar::before { color: var(--b-text); font-weight: 600; font-size: 12px; }

body.bobr .cbi-tooltip { border-radius: 10px; box-shadow: var(--b-shadow-lg); }

body.bobr pre, body.bobr code, body.bobr #syslog {
	border-radius: var(--b-radius-sm);
	border-color: var(--b-line);
	background: var(--b-bg);
}

body.bobr .spinning { color: var(--b-muted); }

/* ---------- Вход ---------- */
body.bobr-blank { display: flex !important; align-items: center; justify-content: center; }

body.bobr-blank .modal.login,
body.bobr .modal.login {
	max-width: 380px;
	width: calc(100% - 32px);
	margin: 12vh auto 0;
	padding: 28px 28px 24px;
	text-align: left;
}

.modal.login .bobr-login-brand { display: flex; justify-content: center; margin-bottom: 10px; }
.modal.login .bobr-login-brand .bobr-logo { width: 54px; height: 54px; flex-basis: 54px; border-radius: 16px; }
.modal.login .bobr-login-brand .bobr-logo svg { width: 34px; height: 34px; }
.modal.login h4 { text-align: center; font-size: 19px; margin: 0 0 16px; }
.modal.login .cbi-section { padding: 0; border: 0; box-shadow: none; background: none; }
.modal.login .cbi-value { display: block; padding: 0 0 12px; border: 0; }
.modal.login .cbi-value label.cbi-value-title { display: block; margin-bottom: 6px; color: var(--b-muted); font-size: 13px; }
.modal.login .cbi-value-field { margin: 0; }
.modal.login input { width: 100%; }
.modal.login .btn { width: 100%; margin-top: 8px; }

/* ---------- Телефон и узкий экран ---------- */
@media (max-width: 860px) {
	#sidebar { transform: translateX(-100%); box-shadow: var(--b-shadow-lg); }
	body.sidebar-open #sidebar { transform: none; }
	body.sidebar-open #sidebar-overlay {
		display: block;
		position: fixed;
		inset: 0;
		z-index: 850;
		background: rgba(10, 14, 20, .4);
	}
	#page { margin-left: 0; }
	#menutoggle { display: flex; }
	header.topbar { padding: 0 14px; min-height: 56px; }
	.crumb-cat { display: none; }
	#maincontent.container { padding: 16px 14px 24px; }
	#view > .cbi-section, .cbi-map > .cbi-section, .cbi-map > div > .cbi-section, #view > div > .cbi-section { padding: 16px; }
	body.bobr .cbi-value { display: block; }
	body.bobr .cbi-value label.cbi-value-title { display: block; margin-bottom: 6px; }
	body.bobr .cbi-value-field { margin-left: 0; }
	body.bobr .tabs, body.bobr .cbi-tabmenu { display: flex; overflow-x: auto; flex-wrap: nowrap; }
	body.bobr .tabs > li, body.bobr .cbi-tabmenu > li { flex: 0 0 auto; }
	body.bobr .cbi-page-actions { bottom: 8px; justify-content: stretch; }
	body.bobr .cbi-page-actions > * { flex: 1 1 auto; }
	footer { padding: 14px; }
}

/* ---------- Быстрый доступ (SSClash) ---------- */
.side-label {
	margin: 18px 24px 4px;
	font-size: 11px;
	font-weight: 600;
	letter-spacing: .06em;
	text-transform: uppercase;
	color: var(--b-muted);
}

.side-quick .bobr-ext { flex: 0 0 15px; width: 15px; height: 15px; opacity: .5; }
.side-quick:hover .bobr-ext { opacity: .9; }

/* ---------- Поправки ---------- */
body.bobr .cbi-value label.cbi-value-title { text-align: left; }
body.bobr .cbi-section-actions > div { display: inline-flex; flex-wrap: wrap; gap: 6px; justify-content: flex-end; }
body.bobr .cbi-section-actions .cbi-button { margin: 0; }
#page { min-width: 0; overflow-x: clip; }

@media (max-width: 860px) {
	body.bobr .tabs, body.bobr .cbi-tabmenu { width: 100%; max-width: 100%; scrollbar-width: none; }
	body.bobr .tabs::-webkit-scrollbar, body.bobr .cbi-tabmenu::-webkit-scrollbar { display: none; }
	body.bobr .cbi-section-actions > div { justify-content: flex-start; }
	body.bobr .table .td.cbi-section-actions { flex-basis: 100%; }
}

/* ---------- Флажки ---------- */
body.bobr input[type="checkbox"]::before {
	width: 18px;
	height: 18px;
	border-radius: 5px;
	background: var(--b-card);
	border: 1.5px solid color-mix(in srgb, var(--b-muted) 45%, var(--b-line));
	box-sizing: border-box;
}
body.bobr input[type="checkbox"]:checked::before { background: var(--b-accent); border-color: var(--b-accent); }
body.bobr input[type="checkbox"]::after { top: 4px; left: 4px; width: 10px; height: 10px; }
body.bobr input[type="checkbox"]:checked::after { background: #fff; }

/* ---------- Современные значки вместо старых картинок LuCI ---------- */
body.bobr img[src*="/resources/icons/"]:not([src$=".gif"]) { width: 22px !important; height: 22px !important; vertical-align: middle; object-fit: contain; }
body.bobr img[src*="/icons/ethernet.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%233b82f6' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3.5' y='6' width='17' height='12' rx='2.5'/%3E%3Cpath d='M8 18v-3.5h8V18M8 9.5h.01M12 9.5h.01M16 9.5h.01'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/ethernet_disabled.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3.5' y='6' width='17' height='12' rx='2.5'/%3E%3Cpath d='M8 18v-3.5h8V18M8 9.5h.01M12 9.5h.01M16 9.5h.01'/%3E%3C/svg%3E"); opacity: .7; }
body.bobr img[src*="/icons/bridge.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%233b82f6' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='5.5' cy='15' r='2.5'/%3E%3Ccircle cx='18.5' cy='15' r='2.5'/%3E%3Ccircle cx='12' cy='6.5' r='2.5'/%3E%3Cpath d='M8 15h8M7 13l3.5-4.5M17 13l-3.5-4.5'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/bridge_disabled.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Ccircle cx='5.5' cy='15' r='2.5'/%3E%3Ccircle cx='18.5' cy='15' r='2.5'/%3E%3Ccircle cx='12' cy='6.5' r='2.5'/%3E%3Cpath d='M8 15h8M7 13l3.5-4.5M17 13l-3.5-4.5'/%3E%3C/svg%3E"); opacity: .7; }
body.bobr img[src*="/icons/wifi.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%233b82f6' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M2 9a15 15 0 0 1 20 0'/%3E%3Ccircle cx='12' cy='19.5' r='.9' fill='%233b82f6'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/wifi_disabled.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M2 9a15 15 0 0 1 20 0'/%3E%3Ccircle cx='12' cy='19.5' r='.9' fill='%2394a3b8'/%3E%3C/svg%3E"); opacity: .7; }
body.bobr img[src*="/icons/switch.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%233b82f6' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='7' width='18' height='10' rx='2.5'/%3E%3Cpath d='M7 12h.01M10.3 12h.01M13.7 12h.01M17 12h.01'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/switch_disabled.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='7' width='18' height='10' rx='2.5'/%3E%3Cpath d='M7 12h.01M10.3 12h.01M13.7 12h.01M17 12h.01'/%3E%3C/svg%3E"); opacity: .7; }
body.bobr img[src*="/icons/vlan.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%233b82f6' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M3 12V4.5A1.5 1.5 0 0 1 4.5 3H12l9 9-9 9-9-9z'/%3E%3Ccircle cx='7.5' cy='7.5' r='1.3'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/vlan_disabled.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M3 12V4.5A1.5 1.5 0 0 1 4.5 3H12l9 9-9 9-9-9z'/%3E%3Ccircle cx='7.5' cy='7.5' r='1.3'/%3E%3C/svg%3E"); opacity: .7; }
body.bobr img[src*="/icons/alias.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%233b82f6' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/alias_disabled.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1'/%3E%3C/svg%3E"); opacity: .7; }
body.bobr img[src*="/icons/tunnel.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%233b82f6' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3z'/%3E%3Cpath d='M9 12h6M12 9v6'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/tunnel_disabled.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3z'/%3E%3Cpath d='M9 12h6M12 9v6'/%3E%3C/svg%3E"); opacity: .7; }
body.bobr img[src*="/icons/port_up.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2322c55e' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3.5' y='6' width='17' height='12' rx='2.5'/%3E%3Cpath d='M8 18v-3.5h8V18'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/port_down.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='%2394a3b8' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3.5' y='6' width='17' height='12' rx='2.5'/%3E%3Cpath d='M8 18v-3.5h8V18'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/signal-none.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='none' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='4.0' y='16' width='3' height='4' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='8.5' y='12' width='3' height='8' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='13.0' y='8' width='3' height='12' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='17.5' y='4' width='3' height='16' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/signal-0.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='none' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='4.0' y='16' width='3' height='4' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='8.5' y='12' width='3' height='8' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='13.0' y='8' width='3' height='12' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='17.5' y='4' width='3' height='16' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/signal-0-25.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='none' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='4.0' y='16' width='3' height='4' rx='1' fill='%23ef4444' stroke='none' opacity='1'/%3E%3Crect x='8.5' y='12' width='3' height='8' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='13.0' y='8' width='3' height='12' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='17.5' y='4' width='3' height='16' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/signal-25-50.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='none' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='4.0' y='16' width='3' height='4' rx='1' fill='%23f59e0b' stroke='none' opacity='1'/%3E%3Crect x='8.5' y='12' width='3' height='8' rx='1' fill='%23f59e0b' stroke='none' opacity='1'/%3E%3Crect x='13.0' y='8' width='3' height='12' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3Crect x='17.5' y='4' width='3' height='16' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/signal-50-75.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='none' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='4.0' y='16' width='3' height='4' rx='1' fill='%2322c55e' stroke='none' opacity='1'/%3E%3Crect x='8.5' y='12' width='3' height='8' rx='1' fill='%2322c55e' stroke='none' opacity='1'/%3E%3Crect x='13.0' y='8' width='3' height='12' rx='1' fill='%2322c55e' stroke='none' opacity='1'/%3E%3Crect x='17.5' y='4' width='3' height='16' rx='1' fill='%2394a3b8' stroke='none' opacity='.35'/%3E%3C/svg%3E"); }
body.bobr img[src*="/icons/signal-75-100.png"] { content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='none' stroke-width='1.9' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='4.0' y='16' width='3' height='4' rx='1' fill='%2322c55e' stroke='none' opacity='1'/%3E%3Crect x='8.5' y='12' width='3' height='8' rx='1' fill='%2322c55e' stroke='none' opacity='1'/%3E%3Crect x='13.0' y='8' width='3' height='12' rx='1' fill='%2322c55e' stroke='none' opacity='1'/%3E%3Crect x='17.5' y='4' width='3' height='16' rx='1' fill='%2322c55e' stroke='none' opacity='1'/%3E%3C/svg%3E"); }

/* Плашки интерфейсов в духе карточек */
body.bobr .ifacebox { min-width: 120px; border-radius: 14px; }
body.bobr .ifacebox .ifacebox-head { color: var(--b-text) !important; font-size: 13px; font-weight: 650; letter-spacing: .02em; text-shadow: none !important; border-bottom: 1px solid var(--b-line-soft); padding: 7px 8px; }
body.bobr .ifacebox .ifacebox-head[style] { background: rgba(var(--zone-color-rgb, 148, 163, 184), .26) !important; }
body.bobr .ifacebox .ifacebox-head:not([style]) { background: var(--b-accent-soft) !important; color: var(--b-accent) !important; }
body.bobr .ifacebox .ifacebox-body { padding: 8px 8px 9px; display: flex; flex-direction: column; align-items: center; gap: 4px; font-size: 12.5px; color: var(--b-muted); }
body.bobr .ifacebox .ifacebox-body > span { display: inline-flex; align-items: center; gap: 2px; flex-wrap: wrap; justify-content: center; }
/* Значки-бейджи устройств (br-lan, radio0, уровень сигнала) */
body.bobr .ifacebadge { display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; border: 1px solid var(--b-line); border-radius: 999px; background: var(--b-card); box-shadow: none; font-size: 13px; color: var(--b-text); }
body.bobr .ifacebadge img { width: 18px !important; height: 18px !important; }
/* Кнопки действий в списках — в ряд, а не столбиком */
body.bobr .table .td.cbi-section-actions { width: 1%; white-space: nowrap; }
body.bobr .table .td.cbi-section-actions > div { display: flex; flex-direction: row; flex-wrap: nowrap; gap: 6px; justify-content: flex-end; }
body.bobr .table .td.cbi-section-actions .cbi-button { width: auto; flex: 0 0 auto; margin: 0 !important; }
@media (max-width: 860px) {
	body.bobr .table .td.cbi-section-actions { width: auto; white-space: normal; }
	body.bobr .table .td.cbi-section-actions > div { flex-wrap: wrap; justify-content: flex-start; }
}

/* ---------- Таблицы: компактнее и спокойнее ---------- */
body.bobr .cbi-rowstyle-2 { background: transparent; }
body.bobr .tr.table-titles, body.bobr .tr.cbi-section-table-titles { background: transparent; }
body.bobr .table .tr:not(.table-titles):not(.cbi-section-table-titles):hover > .td { background: var(--b-hover); }
body.bobr .table .td { padding: 10px 12px; }
body.bobr .table .th { font-size: 11.5px; line-height: 1.35; padding: 8px 12px 10px; }

/* Кнопки внутри таблиц: мягкие и небольшие */
body.bobr .table .cbi-button, body.bobr .table .btn {
	min-height: 30px;
	line-height: 28px;
	padding: 0 12px;
	font-size: 13px;
	box-shadow: none;
}
body.bobr .table .cbi-button-apply, body.bobr .table .cbi-button-action, body.bobr .table .cbi-button-positive {
	background: var(--b-accent-soft) !important;
	border-color: transparent !important;
	color: var(--b-accent) !important;
}
body.bobr .table .cbi-button-apply:hover, body.bobr .table .cbi-button-action:hover, body.bobr .table .cbi-button-positive:hover {
	background: color-mix(in srgb, var(--b-accent) 22%, transparent) !important;
}
body.bobr .table .cbi-button-remove, body.bobr .table .cbi-button-negative {
	background: transparent !important;
	border-color: transparent !important;
}
body.bobr .table .cbi-button-remove:hover, body.bobr .table .cbi-button-negative:hover {
	background: color-mix(in srgb, var(--b-err) 12%, transparent) !important;
}
body.bobr .table .cbi-section-table-row .td.cbi-section-actions .cbi-button-action.important,
body.bobr .table .td.cbi-section-actions .cbi-button-edit { background: var(--b-accent-soft) !important; color: var(--b-accent) !important; border-color: transparent !important; }

/* Плашки в таблицах (точка доступа, сигнал): в одну строку */
body.bobr .table .ifacebadge {
	white-space: nowrap;
	padding: 4px 10px;
	font-size: 12.5px;
	background: var(--b-chip);
	border-color: transparent;
}
body.bobr .table .ifacebadge small { display: none; }
body.bobr .table .ifacebadge img { width: 16px !important; height: 16px !important; }

/* ---------- Обзор: карточки радиомодулей Wi-Fi ---------- */
body.bobr .network-status-table { gap: 14px; }
body.bobr .network-status-table .ifacebox {
	margin: 0;
	flex: 1 1 320px;
	text-align: left;
	white-space: normal;
	border-radius: 14px;
}
body.bobr .network-status-table .ifacebox .ifacebox-head {
	text-align: left;
	padding: 12px 16px;
	font-size: 14px;
	background: transparent !important;
	color: var(--b-text) !important;
	border-bottom: 1px solid var(--b-line-soft);
	display: flex;
	align-items: center;
	gap: 8px;
}
body.bobr .network-status-table .ifacebox .ifacebox-head::before {
	content: "";
	width: 9px;
	height: 9px;
	border-radius: 50%;
	background: var(--b-muted);
	opacity: .5;
}
body.bobr .network-status-table .ifacebox .ifacebox-head.active::before {
	background: var(--b-ok);
	opacity: 1;
	box-shadow: 0 0 0 4px color-mix(in srgb, var(--b-ok) 18%, transparent);
}
body.bobr .network-status-table .ifacebox-body {
	padding: 12px 16px 14px;
	align-items: stretch;
	color: var(--b-text);
	font-size: 13.5px;
	line-height: 1.7;
}
body.bobr .network-status-table .ifacebox-body > * { margin: 0; }
body.bobr .network-status-table .ifacebox-body strong { color: var(--b-muted); font-weight: 500; }
body.bobr .network-status-table .ifacebox-body > div { margin: 10px 0 0; gap: 8px; }
body.bobr .ifacebadge.large,
body.bobr .network-status-table .ifacebox-body .ifacebadge {
	padding: 10px 12px;
	gap: 10px;
	align-items: flex-start;
	border: 0;
	border-radius: 12px;
	background: var(--b-bg);
	line-height: 1.6;
	white-space: normal;
}
body.bobr .network-status-table .ifacebox-body .ifacebadge img { margin-top: 2px; }

/* Поправки к плашкам и карточкам Wi-Fi */
body.bobr .assoclist .ifacebadge { flex-direction: row; align-items: center; gap: 6px; }
body.bobr .network-status-table .ifacebox-body > span { display: block; text-align: left; }
body.bobr .network-status-table .ifacebox { text-align: left; }
body.bobr .assoclist .td > span > span { white-space: nowrap; }
BOBR_EOF
cat > /www/luci-static/bobr/names.js <<'BOBR_EOF'
/* Тема «Бобр»: понятные названия вместо технических терминов.
 * Ключ — исходная английская фраза LuCI, значение — как показывать по-русски.
 * Работает поверх обычного перевода: всё, чего здесь нет, переводится как раньше. */
(function() {
	var NAMES = {
		/* Wi-Fi */
		'SSID': 'Имя сети',
		'Network SSID': 'Имя сети',
		'<abbr title="Extended Service Set Identifier">ESSID</abbr>': 'Имя сети',
		'Hide <abbr title="Extended Service Set Identifier">ESSID</abbr>': 'Скрыть сеть',
		'BSSID': 'MAC точки доступа',
		'<abbr title="Basic Service Set Identifier">BSSID</abbr>': 'MAC точки доступа',
		'Encryption': 'Защита',
		'No Encryption': 'Без пароля',
		'open network': 'открытая сеть',
		'Key': 'Пароль',
		'Cipher': 'Алгоритм шифрования',
		'Master': 'Точка доступа',
		'Associations': 'Клиентов',
		'Associated Stations': 'Подключённые устройства',
		'Bitrate': 'Скорость',
		'Signal / Noise': 'Сигнал / шум',
		'RX Rate / TX Rate': 'Скорость приёма / отправки',
		'RX Rate': 'Приём',
		'TX Rate': 'Отправка',
		'Host': 'Устройство',
		'Disconnect': 'Отключить',
		'Width': 'Ширина канала',
		'Operating frequency': 'Частота и канал',
		'Tx-Power': 'Мощность сигнала',
		'Maximum transmit power': 'Мощность сигнала',
		'Country Code': 'Страна',
		'Wireless': 'Wi-Fi',
		'Wireless Overview': 'Сети Wi-Fi',
		'Wireless is disabled': 'Wi-Fi выключен',
		'Wireless network is disabled': 'Сеть выключена',
		'Wireless network is enabled': 'Сеть включена',
		'Edit wireless network': 'Настройки сети Wi-Fi',
		'Join Network': 'Подключиться к сети',
		'Find and join network': 'Найти сеть и подключиться',
		'WMM Mode': 'Режим WMM (приоритет мультимедиа)',

		/* DHCP и устройства */
		'Active DHCP Leases': 'Устройства, получившие адрес',
		'Active DHCPv6 Leases': 'Устройства, получившие адрес IPv6',
		'Hostname': 'Имя устройства',
		'Lease time remaining': 'Адрес выдан ещё на',
		'Static Lease': 'Закрепить адрес',
		'Set Static': 'Закрепить IP',
		'There are no active leases': 'Пока никто не получил адрес',
		'unlimited': 'бессрочно',
		'Static Leases': 'Закреплённые адреса',

		/* Интерфейсы и сеть */
		'Devices': 'Порты и адаптеры',
		'Global network options': 'Общие настройки сети',
		'DHCP and DNS': 'Раздача адресов и DNS',
		'DHCP client': 'Автоматически (DHCP)',
		'Static address': 'Вручную (статический адрес)',
		'Protocol': 'Тип подключения',
		'Routing': 'Маршруты',
		'Diagnostics': 'Проверка связи',

		/* Система и статус */
		'Realtime Graphs': 'Графики',
		'Software': 'Пакеты',
		'Startup': 'Автозапуск',
		'Scheduled Tasks': 'Расписание задач',
		'Backup / Flash Firmware': 'Резервная копия и прошивка',
		'Router Password': 'Пароль роутера',
		'Uptime': 'Работает без перезагрузки',
		'Firmware Version': 'Версия прошивки',
		'Kernel Version': 'Версия ядра',
		'Local Time': 'Время на роутере',
		'Load Average': 'Нагрузка',
		'Target Platform': 'Платформа',

		/* Индикаторы на корпусе */
		'LED Configuration': 'Индикаторы',
		'<abbr title="Light Emitting Diode">LED</abbr> Configuration': 'Индикаторы на корпусе',
		'<abbr title="Light Emitting Diode">LED</abbr> Name': 'Индикатор',
		'Customizes the behaviour of the device <abbr title="Light Emitting Diode">LED</abbr>s if possible.': 'Что показывают лампочки на корпусе роутера. Можно выключить их на ночь или настроить мигание.',
		'Trigger': 'Когда горит',
		'Add LED action': 'Добавить правило',
		'Always off (kernel: none)': 'Не горит',
		'Always on (kernel: default-on)': 'Горит всегда',
		'Heartbeat interval (kernel: heartbeat)': 'Мигает в такт нагрузке',
		'Network device activity (kernel: netdev)': 'Мигает при работе сети',
		'Custom flash interval (kernel: timer)': 'Мигает с заданной частотой',
		'Default state': 'Включён по умолчанию',
		'Invert blinking': 'Обратное мигание',
		'Trigger Mode': 'Реагировать на',
		'Link On': 'Подключение кабеля',
		'Transmit': 'Отправку данных',
		'Receive': 'Приём данных',
		'On-State Delay': 'Горит, мс',
		'Off-State Delay': 'Не горит, мс'
	};

	/* ---------- Доводка текста прямо на странице ----------
	 * radio0/radio1 → «Wi-Fi 5 ГГц / 2,4 ГГц», скорости без технических MCS/NSS,
	 * адрес устройства без длинного IPv6, понятные названия индикаторов. */
	var BANDS = {};
	try { BANDS = JSON.parse(sessionStorage.getItem('bobr-bands') || '{}'); } catch (e) {}

	function bandOf(text) {
		var m = /(\d+[.,]\d+)\s*(?:ГГц|GHz)/.exec(text || '');
		if (!m) return null;
		var f = parseFloat(m[1].replace(',', '.'));
		return f >= 5.9 ? '6 ГГц' : f >= 4.9 ? '5 ГГц' : '2,4 ГГц';
	}

	var LED_COLORS = { blue: 'Синий', red: 'Красный', green: 'Зелёный', white: 'Белый', yellow: 'Жёлтый', amber: 'Жёлтый', orange: 'Оранжевый', purple: 'Фиолетовый' };
	var LED_FUNCS = { system: 'система', internet: 'интернет', wan: 'интернет', lan: 'локальная сеть', net: 'сеть', wlan: 'Wi-Fi', wifi: 'Wi-Fi', power: 'питание', status: 'состояние', usb: 'USB' };
	var LED_TRIG = { 'none': 'Не горит', 'default-on': 'Горит всегда', 'heartbeat': 'Мигает в такт нагрузке', 'timer': 'Мигает с заданной частотой', 'netdev': 'Мигает при работе сети' };

	function fixText(node) {
		var t = node.nodeValue, n = t, el = node.parentNode;
		if (!el || /^(SCRIPT|STYLE|TEXTAREA|OPTION)$/.test(el.nodeName)) return;

		var rm = /^\s*(radio\d+)\s*$/.exec(t);
		if (rm) {
			var box = el.closest('.ifacebox, .tr, .cbi-section-table-row');
			var b = box ? bandOf(box.textContent) : null;
			if (b && BANDS[rm[1]] != b) {
				BANDS[rm[1]] = b;
				try { sessionStorage.setItem('bobr-bands', JSON.stringify(BANDS)); } catch (e) {}
			}
			b = b || BANDS[rm[1]];
			if (b) n = t.replace(rm[1], 'Wi-Fi ' + b);
		}
		else if (/(Мбит\/с|Mbit\/s)/.test(t) && /MCS|NSS|GI/.test(t)) {
			n = t.replace(/,\s*(?:HE-|VHT-)?(?:MCS|NSS)\s*\d+/g, '').replace(/,\s*(?:Короткий GI|Short GI)/g, '');
		}
		else if (/^\s*Master\s*$/.test(t)) {
			n = t.replace('Master', 'Точка доступа');
		}
		else if (/\(\d{1,3}(?:\.\d{1,3}){3},\s*[0-9a-f:]{6,}\)/i.test(t)) {
			n = t.replace(/,\s*[0-9a-f:]{6,}\)/i, ')');
		}
		else if (document.body.getAttribute('data-page') == 'admin-system-leds' && el.closest('.td')) {
			var lm = /^\s*([a-z]+):([a-z0-9_-]+)\s*$/i.exec(t);
			if (lm && LED_COLORS[lm[1].toLowerCase()])
				n = LED_COLORS[lm[1].toLowerCase()] + ' — ' + (LED_FUNCS[lm[2].toLowerCase()] || lm[2]);
			else if (Object.prototype.hasOwnProperty.call(LED_TRIG, t.trim()))
				n = LED_TRIG[t.trim()];
		}

		if (n !== t) node.nodeValue = n;
	}

	function sweep(root) {
		var w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, null), x;
		while ((x = w.nextNode())) fixText(x);
	}

	var pending = false;
	function schedule() {
		if (pending) return;
		pending = true;
		setTimeout(function() {
			pending = false;
			var mc = document.getElementById('maincontent');
			if (mc) sweep(mc);
		}, 60);
	}

	document.addEventListener('DOMContentLoaded', function() {
		var mc = document.getElementById('maincontent');
		if (!mc) return;
		new MutationObserver(schedule).observe(mc, { childList: true, subtree: true, characterData: true });
		schedule();
	});

	var orig = window._;
	if (typeof orig != 'function')
		return;

	window._ = function(s, c) {
		if (c == null && typeof s == 'string') {
			var k = s.trim();
			if (Object.prototype.hasOwnProperty.call(NAMES, k))
				return NAMES[k];
		}
		return orig.apply(this, arguments);
	};
})();
BOBR_EOF
cat > /www/luci-static/resources/menu-bobr.js <<'BOBR_EOF'
'use strict';
'require baseclass';
'require ui';
'require fs';

/* Тема «Бобр»: боковое меню с разделами, вкладки и строка «раздел › страница».
 * Основано на menu-bootstrap.js из luci-theme-bootstrap (Apache License 2.0). */

const ICONS = {
	status:     'M3 12h4l3-8 4 16 3-8h4',
	system:     'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z',
	network:    'M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M2 9a15 15 0 0 1 20 0M12 20h.01',
	services:   'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z',
	vpn:        'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3zM9 12l2 2 4-4',
	nas:        'M4 5h16v5H4zM4 14h16v5H4zM8 7.5h.01M8 16.5h.01',
	statistics: 'M4 20V10M10 20V4M16 20v-7M22 20H2',
	control:    'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zM12 6v6l4 2',
	docker:     'M3 13h18c-1 4-4.5 7-9 7s-8-3-9-7zM6 9h3v4H6zM10 9h3v4h-3zM10 5h3v4h-3zM14 9h3v4h-3z',
	_default:   'M4 6h16M4 12h16M4 18h10'
};

function icon(name, extra) {
	const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
	svg.setAttribute('viewBox', '0 0 24 24');
	svg.setAttribute('aria-hidden', 'true');
	svg.setAttribute('class', 'bobr-ico' + (extra ? ' ' + extra : ''));
	const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
	p.setAttribute('d', ICONS[name] || ICONS._default);
	svg.appendChild(p);
	return svg;
}

function chevron() {
	const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
	svg.setAttribute('viewBox', '0 0 24 24');
	svg.setAttribute('class', 'bobr-chev');
	const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
	p.setAttribute('d', 'M9 6l6 6-6 6');
	svg.appendChild(p);
	return svg;
}

const MODES = [ ['auto', 'Тема: авто'], ['light', 'Тема: светлая'], ['dark', 'Тема: тёмная'] ];

return baseclass.extend({
	__init__() {
		ui.menu.load().then(L.bind(this.render, this));
		this.bindMobile();
	},

	bindMobile() {
		const toggle = document.querySelector('#menutoggle'),
		      overlay = document.querySelector('#sidebar-overlay');
		const close = () => document.body.classList.remove('sidebar-open');

		if (toggle)
			toggle.addEventListener('click', () => document.body.classList.toggle('sidebar-open'));
		if (overlay)
			overlay.addEventListener('click', close);
		document.addEventListener('keydown', ev => { if (ev.key == 'Escape') close(); });
	},

	render(tree) {
		let node = tree;
		let url = '';

		const mode = this.findMode(tree);
		if (mode)
			this.renderSideMenu(mode.node, mode.node.name);

		if (L.env.dispatchpath.length >= 3) {
			for (let i = 0; i < 3 && node; i++) {
				node = node.children[L.env.dispatchpath[i]];
				url = url + (url ? '/' : '') + L.env.dispatchpath[i];
			}

			if (node)
				this.renderTabMenu(node, url);
		}
	},

	findMode(tree) {
		const children = ui.menu.getChildren(tree);
		let found = null;

		children.forEach((child, index) => {
			const isActive = L.env.requestpath.length
				? child.name === L.env.requestpath[0]
				: index === 0;
			if (isActive)
				found = { node: child };
		});

		return found;
	},

	renderSideMenu(modeNode, base) {
		const nav = document.querySelector('#sidemenu'),
		      bottom = document.querySelector('#sidebottom'),
		      crumbs = document.querySelector('#crumbs'),
		      path = L.env.dispatchpath;
		const ul = E('ul', { 'class': 'side-cats' });
		let logout = null, crumbCat = null, crumbPage = null;

		ui.menu.getChildren(modeNode).forEach(cat => {
			if (cat.name == 'logout') {
				logout = cat;
				return;
			}

			const pages = ui.menu.getChildren(cat);
			const catActive = (path[1] == cat.name);
			const li = E('li', { 'class': 'side-cat' + (catActive ? ' active open' : '') });

			if (catActive)
				crumbCat = _(cat.title);

			if (pages.length) {
				const head = E('a', { 'href': '#', 'class': 'side-head' }, [ icon(cat.name), E('span', {}, [ _(cat.title) ]), chevron() ]);
				head.addEventListener('click', ev => {
					ev.preventDefault();
					const wasOpen = li.classList.contains('open');
					ul.querySelectorAll('.side-cat.open').forEach(o => o.classList.remove('open'));
					if (!wasOpen)
						li.classList.add('open');
				});

				const sub = E('ul', { 'class': 'side-sub' });
				pages.forEach(page => {
					const pageActive = catActive && path[2] == page.name;
					if (pageActive)
						crumbPage = _(page.title);
					sub.appendChild(E('li', { 'class': pageActive ? 'active' : '' }, [
						E('a', { 'href': L.url(base, cat.name, page.name) }, [ _(page.title) ])
					]));
				});

				li.appendChild(head);
				li.appendChild(sub);
			}
			else {
				li.appendChild(E('a', { 'href': L.url(base, cat.name), 'class': 'side-head' }, [ icon(cat.name), E('span', {}, [ _(cat.title) ]) ]));
			}

			ul.appendChild(li);
		});

		nav.appendChild(ul);

		/* быстрые ссылки: панель SSClash, если он установлен на роутере */
		ICONS._clash = 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3zM9 12l2 2 4-4';
		ICONS._ext = 'M14 4h6v6M20 4l-9 9M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5';
		L.resolveDefault(fs.stat('/etc/init.d/ssclash'), null).then(st => {
			if (!st) return;
			nav.appendChild(E('div', { 'class': 'side-label' }, [ 'Быстрый доступ' ]));
			nav.appendChild(E('a', {
				'class': 'side-head side-quick',
				'href': '%s//%s:9091/settings'.format(location.protocol, location.hostname),
				'target': '_blank',
				'rel': 'noopener'
			}, [ icon('_clash'), E('span', {}, [ 'SSClash' ]), icon('_ext', 'bobr-ext') ]));
		});

		/* переключатель темы и выход внизу меню */
		const modeBtn = E('button', { 'type': 'button', 'class': 'side-mode' });
		const paintMode = () => {
			const m = document.documentElement.getAttribute('data-theme-mode') || 'auto';
			const label = (MODES.find(x => x[0] == m) || MODES[0])[1];
			modeBtn.innerHTML = '';
			modeBtn.appendChild(icon('_mode', 'mode-' + m));
			modeBtn.appendChild(E('span', {}, [ label ]));
		};
		ICONS._mode = 'M12 3a9 9 0 1 0 9 9 7 7 0 0 1-9-9z';
		modeBtn.addEventListener('click', () => {
			const cur = document.documentElement.getAttribute('data-theme-mode') || 'auto';
			const next = MODES[(MODES.findIndex(x => x[0] == cur) + 1) % MODES.length][0];
			try { localStorage.setItem('bobr-theme', next); } catch (e) {}
			window.bobrApplyTheme && window.bobrApplyTheme();
			paintMode();
		});
		paintMode();
		bottom.appendChild(modeBtn);

		if (logout) {
			ICONS._logout = 'M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3M10 17l5-5-5-5M15 12H3';
			bottom.appendChild(E('a', { 'class': 'side-logout', 'href': L.url(base, logout.name) }, [ icon('_logout'), E('span', {}, [ _(logout.title) ]) ]));
		}

		/* строка «раздел › страница» в шапке */
		if (crumbs) {
			if (crumbCat)
				crumbs.appendChild(E('span', { 'class': 'crumb-cat' }, [ crumbCat ]));
			crumbs.appendChild(E('span', { 'class': 'crumb-page' }, [ crumbPage || crumbCat || document.title.replace(/ - LuCI$/, '') ]));
		}
	},

	renderTabMenu(tree, url, level) {
		const container = document.querySelector('#tabmenu');
		const ul = E('ul', { 'class': 'tabs' });
		const children = ui.menu.getChildren(tree);
		let activeNode = null;

		children.forEach(child => {
			const isActive = (L.env.dispatchpath[3 + (level || 0)] == child.name);
			const activeClass = isActive ? ' active' : '';
			const className = 'tabmenu-item-%s %s'.format(child.name, activeClass);

			ul.appendChild(E('li', { 'class': className }, [
				E('a', { 'href': L.url(url, child.name) }, [ _(child.title) ] )]));

			if (isActive)
				activeNode = child;
		});

		if (ul.children.length == 0)
			return E([]);

		container.appendChild(ul);
		container.style.display = '';

		if (activeNode)
			this.renderTabMenu(activeNode, url + '/' + activeNode.name, (level || 0) + 1);

		return ul;
	}
});
BOBR_EOF
cat > /www/luci-static/resources/view/bobr/dashboard.js <<'BOBR_EOF'
'use strict';
'require view';
'require rpc';
'require poll';
'require uci';
'require ui';
'require fs';

/* Панель в духе Keenetic для темы «Бобр»: интернет с графиком, Wi-Fi, устройства, порты, система, службы. */

const callHints     = rpc.declare({ object: 'luci-rpc', method: 'getHostHints', expect: { '': {} } });
const callLeases    = rpc.declare({ object: 'luci-rpc', method: 'getDHCPLeases', expect: { '': {} } });
const callDevices   = rpc.declare({ object: 'luci-rpc', method: 'getNetworkDevices', expect: { '': {} } });
const callWireless  = rpc.declare({ object: 'luci-rpc', method: 'getWirelessDevices', expect: { '': {} } });
const callAssoc     = rpc.declare({ object: 'iwinfo', method: 'assoclist', params: [ 'device' ], expect: { results: [] } });
const callIfaces    = rpc.declare({ object: 'network.interface', method: 'dump', expect: { interface: [] } });
const callSysInfo   = rpc.declare({ object: 'system', method: 'info', expect: { '': {} } });
const callBoard     = rpc.declare({ object: 'system', method: 'board', expect: { '': {} } });
const callService   = rpc.declare({ object: 'service', method: 'list', params: [ 'name' ], expect: { '': {} } });
const callInit      = rpc.declare({ object: 'luci', method: 'setInitAction', params: [ 'name', 'action' ], expect: { result: false } });

const SERVICES = [
	[ 'ssclash', 'SSClash', 'VPN для всей домашней сети' ],
	[ 'podkop', 'Podkop', 'Обход блокировок для выбранных сайтов' ],
	[ 'jarvis-music', 'Музыкальный агент', 'Музыка на колонках Алисы' ],
	[ 'dnsmasq', 'DNS и DHCP', 'Раздаёт адреса устройствам в сети' ]
];

const CSS = `
.bd { --c: var(--b-card, #fff); --l: var(--b-line, #e3e7ee); --ls: var(--b-line-soft, #eef1f5); --t: var(--b-text, #1b2333);
	--m: var(--b-muted, #6b7486); --a: var(--b-accent, #2a6df4); --as: var(--b-accent-soft, rgba(42,109,244,.1));
	--ok: var(--b-ok, #12a150); --err: var(--b-err, #e5484d); --warn: var(--b-warn, #e5a50a); --chip: var(--b-chip, #e9edf3); color: var(--t); }
.bd-grid { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 18px; align-items: start; }
.bd-col { display: flex; flex-direction: column; gap: 18px; min-width: 0; }
.bd-card { background: var(--c); border: 1px solid var(--l); border-radius: var(--b-radius, 14px); box-shadow: var(--b-shadow, 0 1px 3px rgba(0,0,0,.06)); padding: 18px 20px 20px; }
.bd-title { display: flex; align-items: center; justify-content: space-between; margin: 0 0 14px; font-size: 13px; font-weight: 650; letter-spacing: .08em; text-transform: uppercase; color: var(--m); }
.bd-count { min-width: 26px; padding: 2px 8px; border-radius: 999px; background: var(--as); color: var(--a); text-align: center; letter-spacing: 0; }
.bd-sub { color: var(--m); font-size: 12.5px; line-height: 1.4; }
.bd-sub.ok { color: var(--ok); } .bd-sub.warn { color: var(--warn); }
.bd-empty { color: var(--m); text-align: center; padding: 10px 0; }
.bd-ico { width: 20px; height: 20px; fill: none; stroke: currentColor; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; flex: 0 0 auto; }
.bd-ico.small { width: 13px; height: 13px; vertical-align: -1px; }
.bd-pill { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 11.5px; font-weight: 650; white-space: nowrap; }
.bd-pill-ok { color: var(--ok); background: color-mix(in srgb, var(--ok) 12%, transparent); }
.bd-pill-err { color: var(--err); background: color-mix(in srgb, var(--err) 12%, transparent); }
.bd-btn { display: inline-flex; align-items: center; min-height: 32px !important; line-height: 30px !important; padding: 0 12px !important; border: 1px solid var(--l) !important; border-radius: 9px !important;
	background: var(--c) !important; color: var(--a) !important; font-size: 13px; font-weight: 550; white-space: nowrap; box-shadow: none !important; cursor: pointer; text-decoration: none !important; }
.bd-btn:hover { border-color: var(--a) !important; }
.bd-kv { display: grid; grid-template-columns: minmax(110px, 38%) 1fr; column-gap: 14px; font-size: 13.5px; }
.bd-k, .bd-v { padding: 8px 0; border-top: 1px solid var(--ls); }
.bd-k { color: var(--m); } .bd-v { word-break: break-word; }
.bd-kv > :nth-child(1), .bd-kv > :nth-child(2) { border-top: 0; }
.bd-conn { display: flex; align-items: center; gap: 12px; padding-bottom: 14px; border-bottom: 1px solid var(--ls); margin-bottom: 12px; }
.bd-conn-ico, .bd-wifi-ico, .bd-client-ico { width: 38px; height: 38px; flex: 0 0 38px; border-radius: 11px; display: inline-flex; align-items: center; justify-content: center; background: var(--chip); color: var(--m); }
.bd-conn-ico { background: var(--as); color: var(--a); }
.bd-conn-name { flex: 1; font-weight: 600; display: flex; flex-direction: column; }
.bd-conn-name small, .bd-conn-state small { font-weight: 400; color: var(--m); font-size: 12px; }
.bd-conn-state { display: flex; flex-direction: column; align-items: flex-end; gap: 3px; }
.bd-chart { position: relative; height: 170px; margin: 4px 0 6px; }
.bd-chart svg { position: absolute; left: 0; right: 0; top: 18px; width: 100%; height: 132px; overflow: visible; }
.bd-chart .grid { stroke: var(--ls); stroke-width: 1; vector-effect: non-scaling-stroke; }
.bd-chart .area { fill: var(--a); opacity: .12; }
.bd-chart .rx { fill: none; stroke: var(--a); stroke-width: 2; vector-effect: non-scaling-stroke; stroke-linejoin: round; }
.bd-chart .tx { fill: none; stroke: #f0605d; stroke-width: 1.6; vector-effect: non-scaling-stroke; stroke-linejoin: round; }
.bd-chart-max { position: absolute; top: 0; left: 0; font-size: 12px; color: var(--m); }
.bd-chart-time { position: absolute; bottom: 0; left: 0; right: 0; display: flex; justify-content: space-between; font-size: 11.5px; color: var(--m); }
.bd-legend { display: flex; justify-content: flex-end; gap: 16px; font-size: 12.5px; color: var(--m); margin-bottom: 10px; }
.bd-legend .dl::first-letter { color: var(--a); } .bd-legend .ul::first-letter { color: #f0605d; }
.bd-legend span span { color: var(--t); font-weight: 600; }
.bd-wifi, .bd-client, .bd-svc { display: flex; align-items: center; gap: 12px; padding: 11px 0; border-top: 1px solid var(--ls); }
.bd-wifi:first-child, .bd-client:first-child, .bd-svc:first-child { border-top: 0; padding-top: 2px; }
.bd-wifi-ico.on { background: var(--as); color: var(--a); }
.bd-wifi-main, .bd-client-main, .bd-svc-main { flex: 1; min-width: 0; }
.bd-wifi-name { display: flex; align-items: center; gap: 10px; font-weight: 600; }
.bd-switch { appearance: none; -webkit-appearance: none; width: 38px !important; height: 22px !important; min-height: 0 !important; margin: 0; padding: 0 !important; border: 0 !important; border-radius: 999px !important;
	background: var(--l) !important; position: relative; cursor: pointer; transition: background .2s; flex: 0 0 auto; box-shadow: none !important; }
.bd-switch::after { content: ""; position: absolute; top: 3px; left: 3px; width: 16px; height: 16px; border-radius: 50%; background: #fff; box-shadow: 0 1px 2px rgba(0,0,0,.25); transition: transform .2s; }
.bd-switch::before { display: none !important; }
.bd-switch::after { -webkit-mask: none !important; mask: none !important; background: #fff !important; }
.bd-switch:checked { background: var(--a) !important; }
.bd-switch:checked::after { transform: translateX(16px); }
.bd-client-ico.wifi { background: var(--as); color: var(--a); }
.bd-client-name { font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.bd-client-link { display: flex; align-items: center; gap: 8px; }
.bd-tag { padding: 2px 8px; border-radius: 7px; background: var(--chip); color: var(--m); font-size: 12px; white-space: nowrap; }
.bd-bars { display: inline-flex; align-items: flex-end; gap: 2px; height: 14px; }
.bd-bars i { width: 3px; border-radius: 1px; background: var(--l); }
.bd-bars i:nth-child(1) { height: 4px; } .bd-bars i:nth-child(2) { height: 7px; } .bd-bars i:nth-child(3) { height: 10px; } .bd-bars i:nth-child(4) { height: 14px; }
.bd-bars i.on { background: var(--a); }
.bd-ports { display: flex; flex-wrap: wrap; gap: 14px; }
.bd-port { width: 66px; text-align: center; }
.bd-port-box { position: relative; height: 46px; border: 1.5px solid var(--l); border-radius: 10px; display: flex; align-items: center; justify-content: center; color: var(--m); margin-bottom: 6px; }
.bd-port.up .bd-port-box { border-color: var(--a); background: var(--as); color: var(--a); }
.bd-port-led { position: absolute; top: -4px; right: -4px; width: 9px; height: 9px; border-radius: 50%; background: var(--l); border: 2px solid var(--c); }
.bd-port.up .bd-port-led { background: var(--ok); }
.bd-port-name { font-size: 12.5px; font-weight: 600; }
.bd-meter { display: flex; align-items: center; gap: 10px; }
.bd-meter-bar { flex: 0 0 38%; height: 8px; border-radius: 999px; background: var(--chip); overflow: hidden; }
.bd-meter-bar i { display: block; height: 100%; border-radius: 999px; background: linear-gradient(90deg, #3b82ff, var(--a)); }
.bd-meter span { font-size: 12.5px; min-width: 0; }
.bd-svc { align-items: flex-start; }
.bd-svc-state { padding-top: 5px; }
.bd-svc-state i { display: block; width: 10px; height: 10px; border-radius: 50%; background: var(--l); }
.bd-svc-state i.on { background: var(--ok); box-shadow: 0 0 0 4px color-mix(in srgb, var(--ok) 18%, transparent); }
.bd-svc-state i.off { background: var(--warn); }
.bd-svc-main { flex: 0 0 34%; }
.bd-svc-name { font-weight: 600; }
.bd-svc-descr { flex: 1; font-size: 13px; color: var(--m); }
.bd-svc-descr a { white-space: nowrap; }
@media (max-width: 1100px) { .bd-grid { grid-template-columns: minmax(0, 1fr); } }
@media (max-width: 560px) {
	.bd-card { padding: 16px; }
	.bd-svc { flex-wrap: wrap; } .bd-svc-main { flex: 1; } .bd-svc-descr { flex-basis: 100%; order: 3; padding-left: 22px; }
	.bd-wifi { flex-wrap: wrap; } .bd-wifi-main { flex: 1 1 calc(100% - 52px); } .bd-wifi .bd-btn { margin-left: 50px; }
	.bd-kv { grid-template-columns: 1fr 1.4fr; }
}
`;

const HISTORY = 60;          /* точек на графике, по одной в 2 секунды */

function bits(v) {
	if (v == null || isNaN(v)) return '—';
	if (v >= 1e9) return (v / 1e9).toFixed(2) + ' Гбит/с';
	if (v >= 1e6) return (v / 1e6).toFixed(2) + ' Мбит/с';
	if (v >= 1e3) return (v / 1e3).toFixed(1) + ' кбит/с';
	return Math.round(v) + ' бит/с';
}

function bytes(v) {
	if (v == null || isNaN(v)) return '—';
	const u = [ 'Б', 'КБ', 'МБ', 'ГБ', 'ТБ' ];
	let i = 0;
	while (v >= 1024 && i < u.length - 1) { v /= 1024; i++; }
	return (i ? v.toFixed(v < 10 ? 2 : 1) : v) + ' ' + u[i];
}

function duration(s) {
	if (!s) return '—';
	const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
	return (d ? d + ' д ' : '') + (d || h ? h + ' ч ' : '') + m + ' мин';
}

function clock(t) {
	const d = new Date(t);
	return ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2) + ':' + ('0' + d.getSeconds()).slice(-2);
}

function svg(tag, attrs, kids) {
	const el = document.createElementNS('http://www.w3.org/2000/svg', tag);
	for (const k in attrs || {}) el.setAttribute(k, attrs[k]);
	(kids || []).forEach(c => el.appendChild(c));
	return el;
}

const ICON = {
	wifi:  'M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M2 9a15 15 0 0 1 20 0M12 20h.01',
	cable: 'M7 3v5M17 3v5M5 8h14v4a7 7 0 0 1-14 0zM12 19v2',
	globe: 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zM2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20',
	port:  'M4 6h16v12H4zM8 18v-3h8v3M8 10h.01M12 10h.01M16 10h.01',
	ext:   'M14 4h6v6M20 4l-9 9M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5'
};

function ico(name, cls) {
	return svg('svg', { viewBox: '0 0 24 24', 'class': 'bd-ico ' + (cls || '') }, [ svg('path', { d: ICON[name] }) ]);
}

function card(title, body, extra) {
	return E('section', { 'class': 'bd-card' }, [
		E('div', { 'class': 'bd-title' }, [ E('span', {}, [ title ]), extra || '' ]),
		E('div', { 'class': 'bd-body' }, body)
	]);
}

function kv(rows) {
	return E('div', { 'class': 'bd-kv' }, rows.filter(r => r).map(r => [
		E('div', { 'class': 'bd-k' }, [ r[0] ]), E('div', { 'class': 'bd-v' }, [ r[1] ])
	]).flat());
}

function pill(text, kind) {
	return E('span', { 'class': 'bd-pill bd-pill-' + kind }, [ text ]);
}

function signalBars(dbm) {
	const lvl = dbm >= -55 ? 4 : dbm >= -65 ? 3 : dbm >= -75 ? 2 : 1;
	return E('span', { 'class': 'bd-bars', 'title': dbm + ' дБм' }, [1, 2, 3, 4].map(i => E('i', { 'class': i <= lvl ? 'on' : '' })));
}

return view.extend({
	history: [],
	last: null,

	load() {
		return Promise.all([
			callIfaces(), callDevices(), callWireless(), callHints(), callLeases(),
			callSysInfo(), callBoard(), L.resolveDefault(fs.read('/proc/net/arp'), ''),
			uci.load('wireless').catch(() => null),
			Promise.all(SERVICES.map(s => Promise.all([ L.resolveDefault(callService(s[0]), {}), L.resolveDefault(fs.stat('/etc/init.d/' + s[0]), null) ])))
		]).then(r => this.loadAssoc(r[2]).then(assoc => r.concat([ assoc ])));
	},

	loadAssoc(wireless) {
		const list = [];
		Object.keys(wireless || {}).forEach(radio => {
			const r = wireless[radio];
			(r.interfaces || []).forEach(i => {
				if (i.ifname)
					list.push(L.resolveDefault(callAssoc(i.ifname), []).then(res => res.map(a => Object.assign(a, {
						band: this.band(r), ssid: i.config?.ssid, ifname: i.ifname
					}))));
			});
		});
		return Promise.all(list).then(x => x.flat());
	},

	band(radio) {
		const b = radio?.config?.band, ch = +(radio?.config?.channel || 0);
		if (b == '5g' || ch > 14) return '5 ГГц';
		if (b == '6g') return '6 ГГц';
		return '2,4 ГГц';
	},

	/* ---------- Интернет ---------- */
	wan(ifaces) {
		return ifaces.find(i => i.interface == 'wan') || ifaces.find(i => (i.route || []).some(r => r.target == '0.0.0.0'));
	},

	renderInternet(ifaces, devices) {
		const w = this.wan(ifaces) || {};
		const dev = devices[w.l3_device || w.device] || {};
		const addr = (w['ipv4-address'] || [])[0];
		const gw = (w.route || []).find(r => r.target == '0.0.0.0');
		const st = dev.stats || {};

		this.wanDev = w.l3_device || w.device;
		this.chart = E('div', { 'class': 'bd-chart' });
		this.rateDown = E('span', {}, [ '…' ]);
		this.rateUp = E('span', {}, [ '…' ]);

		return card('Интернет', [
			E('div', { 'class': 'bd-conn' }, [
				E('span', { 'class': 'bd-conn-ico' }, [ ico('globe') ]),
				E('div', { 'class': 'bd-conn-name' }, [ 'Подключение через WAN', E('small', {}, [ (w.proto == 'dhcp' ? 'DHCP-клиент' : w.proto || '') + (this.wanDev ? ' · ' + this.wanDev : '') ]) ]),
				E('div', { 'class': 'bd-conn-state' }, [ w.up ? pill('● Подключено', 'ok') : pill('● Нет подключения', 'err'), E('small', {}, [ w.up ? duration(w.uptime) : '' ]) ])
			]),
			this.chart,
			E('div', { 'class': 'bd-legend' }, [ E('span', { 'class': 'dl' }, [ '● Загрузка ', this.rateDown ]), E('span', { 'class': 'ul' }, [ '● Отдача ', this.rateUp ]) ]),
			kv([
				[ 'IP-адрес', addr ? addr.address + '/' + addr.mask : '—' ],
				[ 'Шлюз', gw ? gw.nexthop : '—' ],
				[ 'MAC-адрес', dev.mac || '—' ],
				[ 'DNS-серверы', (w['dns-server'] || []).join(', ') || '—' ],
				[ 'Получено', bytes(st.rx_bytes) ],
				[ 'Отправлено', bytes(st.tx_bytes) ]
			])
		]);
	},

	pollTraffic() {
		if (!this.wanDev) return Promise.resolve();
		return callDevices().then(devs => {
			const s = (devs[this.wanDev] || {}).stats;
			if (!s) return;
			const now = Date.now();
			if (this.last) {
				const dt = (now - this.last.t) / 1000;
				if (dt > 0) {
					this.history.push({ t: now, rx: Math.max(0, (s.rx_bytes - this.last.rx) * 8 / dt), tx: Math.max(0, (s.tx_bytes - this.last.tx) * 8 / dt) });
					if (this.history.length > HISTORY) this.history.shift();
				}
			}
			this.last = { t: now, rx: s.rx_bytes, tx: s.tx_bytes };
			this.drawChart();
		});
	},

	drawChart() {
		const h = this.history, W = 600, H = 150;
		if (!this.chart) return;
		const max = Math.max(1e6, ...h.map(p => Math.max(p.rx, p.tx))) * 1.15;
		const x = i => (h.length < 2 ? 0 : i * W / (HISTORY - 1)) + (HISTORY - h.length) * W / (HISTORY - 1);
		const y = v => H - v / max * (H - 6);
		const line = key => h.map((p, i) => (i ? 'L' : 'M') + x(i).toFixed(1) + ' ' + y(p[key]).toFixed(1)).join(' ');
		const area = h.length > 1 ? line('rx') + ' L' + x(h.length - 1).toFixed(1) + ' ' + H + ' L' + x(0).toFixed(1) + ' ' + H + ' Z' : '';
		const grid = [0.25, 0.5, 0.75].map(f => svg('line', { x1: 0, x2: W, y1: H * f, y2: H * f, 'class': 'grid' }));

		this.chart.innerHTML = '';
		this.chart.appendChild(E('div', { 'class': 'bd-chart-max' }, [ bits(max / 1.15) ]));
		this.chart.appendChild(svg('svg', { viewBox: '0 0 ' + W + ' ' + H, preserveAspectRatio: 'none' }, grid.concat(h.length > 1 ? [
			svg('path', { d: area, 'class': 'area' }),
			svg('path', { d: line('rx'), 'class': 'rx' }),
			svg('path', { d: line('tx'), 'class': 'tx' })
		] : [])));
		this.chart.appendChild(E('div', { 'class': 'bd-chart-time' }, [
			E('span', {}, [ h.length ? clock(h[0].t) : '' ]), E('span', {}, [ h.length ? clock(h[h.length - 1].t) : '' ])
		]));

		const p = h[h.length - 1];
		if (p) {
			this.rateDown.textContent = bits(p.rx);
			this.rateUp.textContent = bits(p.tx);
		}
	},

	/* ---------- Wi-Fi ---------- */
	renderWifi(wireless, assoc) {
		const blocks = [];
		Object.keys(wireless || {}).sort().forEach(radio => {
			const r = wireless[radio];
			const band = this.band(r);
			(r.interfaces || []).forEach(i => {
				const cfg = i.config || {};
				if (cfg.mode && cfg.mode != 'ap') return;
				const on = !cfg.disabled && !r.config?.disabled;
				const clients = assoc.filter(a => a.ifname == i.ifname).length;
				const sw = E('input', { 'type': 'checkbox', 'class': 'bd-switch', 'checked': on ? '' : null });
				sw.addEventListener('change', ev => this.toggleWifi(i.section, ev.target.checked, cfg.ssid));

				blocks.push(E('div', { 'class': 'bd-wifi' }, [
					E('span', { 'class': 'bd-wifi-ico' + (on ? ' on' : '') }, [ ico('wifi') ]),
					E('div', { 'class': 'bd-wifi-main' }, [
						E('div', { 'class': 'bd-wifi-name' }, [ cfg.ssid || i.ifname, sw ]),
						E('div', { 'class': 'bd-sub' }, [
							band + (i.iwinfo?.channel || r.config?.channel ? ' · канал ' + (i.iwinfo?.channel || r.config.channel) : '') +
							(r.config?.htmode ? ' · ' + r.config.htmode.replace(/^[A-Z]+/, '') + ' МГц' : '') +
							' · клиентов: ' + clients
						])
					]),
					E('a', { 'class': 'bd-btn', 'href': L.url('admin/network/wireless') }, [ 'Настроить' ])
				]));
			});
		});

		return card('Мои сети и Wi-Fi', blocks.length ? blocks : [ E('div', { 'class': 'bd-empty' }, [ 'Wi-Fi не найден' ]) ]);
	},

	toggleWifi(section, on, ssid) {
		if (!on && !confirm('Выключить сеть «' + (ssid || section) + '»? Устройства в ней отключатся. Если вы сами подключены через неё, связь с роутером пропадёт.'))
			return location.reload();
		uci.set('wireless', section, 'disabled', on ? null : '1');
		return uci.save().then(() => ui.changes.apply(true));
	},

	/* ---------- Устройства ---------- */
	renderClients(hints, leases, arp, assoc) {
		const byMac = {};
		const add = (mac, o) => {
			mac = (mac || '').toUpperCase();
			if (!mac || mac == '00:00:00:00:00:00') return;
			byMac[mac] = Object.assign(byMac[mac] || { mac }, o);
		};

		(leases.dhcp_leases || []).forEach(l => add(l.macaddr, { name: l.hostname, ip: l.ipaddr }));
		Object.keys(hints || {}).forEach(mac => {
			const h = hints[mac];
			add(mac, { name: byMac[mac.toUpperCase()]?.name || h.name, ip: byMac[mac.toUpperCase()]?.ip || (h.ipaddrs || h.ipv4 || [])[0] });
		});
		String(arp || '').split('\n').slice(1).forEach(line => {
			const f = line.trim().split(/\s+/);
			if (f.length >= 6 && f[2] == '0x2' && /^br-|^lan/.test(f[5]))
				add(f[3], { ip: byMac[f[3].toUpperCase()]?.ip || f[0], wired: true, online: true });
		});
		assoc.forEach(a => add(a.mac, { wifi: true, online: true, wired: false, band: a.band, signal: a.signal, rate: a.rx?.rate }));

		const list = Object.values(byMac).filter(c => c.online);
		list.sort((a, b) => (b.wifi ? 1 : 0) - (a.wifi ? 1 : 0) || (b.signal || -999) - (a.signal || -999) || String(a.name || a.ip).localeCompare(String(b.name || b.ip)));

		const rows = list.map(c => E('div', { 'class': 'bd-client' }, [
			E('span', { 'class': 'bd-client-ico' + (c.wifi ? ' wifi' : '') }, [ ico(c.wifi ? 'wifi' : 'cable') ]),
			E('div', { 'class': 'bd-client-main' }, [
				E('div', { 'class': 'bd-client-name' }, [ c.name && c.name != '*' ? c.name : (c.ip || c.mac) ]),
				E('div', { 'class': 'bd-sub' }, [ [ c.ip, c.mac ].filter(x => x).join(' · ') ])
			]),
			E('div', { 'class': 'bd-client-link' }, c.wifi
				? [ E('span', { 'class': 'bd-tag' }, [ c.band ]), signalBars(c.signal) ]
				: [ E('span', { 'class': 'bd-tag' }, [ 'Кабель' ]) ])
		]));

		return card('Устройства в сети', rows.length ? rows : [ E('div', { 'class': 'bd-empty' }, [ 'Нет активных устройств' ]) ],
			E('span', { 'class': 'bd-count' }, [ String(list.length) ]));
	},

	/* ---------- Порты ---------- */
	renderPorts(devices) {
		const names = Object.keys(devices).filter(n => /^(wan|lan\d+|eth\d+)$/.test(n))
			.sort((a, b) => (a == 'wan' ? -1 : b == 'wan' ? 1 : a.localeCompare(b, undefined, { numeric: true })));
		if (!names.length) return '';

		return card('Сетевые порты', [ E('div', { 'class': 'bd-ports' }, names.map(n => {
			const d = devices[n], link = d.link || {};
			const up = link.carrier != null ? link.carrier : d.up;
			const sp = link.speed > 0 ? (link.speed >= 1000 ? link.speed / 1000 + ' Гбит' : link.speed + ' Мбит') : '';
			return E('div', { 'class': 'bd-port' + (up ? ' up' : '') }, [
				E('div', { 'class': 'bd-port-box' }, [ ico(n == 'wan' ? 'globe' : 'port'), E('i', { 'class': 'bd-port-led' }) ]),
				E('div', { 'class': 'bd-port-name' }, [ n == 'wan' ? 'WAN' : n.replace(/^lan/, 'LAN ') ]),
				E('div', { 'class': 'bd-sub' }, [ up ? (sp || 'подключён') : '—' ])
			]);
		})) ]);
	},

	/* ---------- Система ---------- */
	renderSystem(info, board) {
		const m = info.memory || {}, sw = info.swap || {};
		const used = m.total ? (m.total - (m.available || m.free)) : 0;
		const swUsed = sw.total ? sw.total - sw.free : 0;
		const load = (info.load || [0])[0] / 65536;
		const bar = (f, txt) => E('div', { 'class': 'bd-meter' }, [ E('div', { 'class': 'bd-meter-bar' }, [ E('i', { 'style': 'width:' + Math.min(100, Math.round(f * 100)) + '%' }) ]), E('span', {}, [ txt ]) ]);

		return card('О системе', [ kv([
			[ 'Нагрузка', bar(load / 4, load.toFixed(2)) ],
			[ 'Память', bar(m.total ? used / m.total : 0, Math.round(used / m.total * 100) + '% · ' + bytes(used) + ' из ' + bytes(m.total)) ],
			sw.total ? [ 'Swap', bar(swUsed / sw.total, Math.round(swUsed / sw.total * 100) + '% (' + bytes(swUsed) + ')') ] : null,
			[ 'Время работы', duration(info.uptime) ],
			[ 'Модель', board.model || '—' ],
			[ 'Прошивка', board.release?.description || '—' ],
			[ 'Ядро', board.kernel || '—' ]
		]) ]);
	},

	/* ---------- Службы ---------- */
	renderServices(states) {
		const rows = SERVICES.map((s, idx) => {
			const [ st, installed ] = states[idx] || [ {}, null ];
			if (!installed) return null;                   /* службы нет на этом роутере — не показываем */
			const inst = (st || {})[s[0]]?.instances || {};
			const known = true;
			const running = Object.values(inst).some(i => i.running);
			const btn = E('button', { 'class': 'bd-btn', 'type': 'button' }, [ 'Перезапустить' ]);
			btn.addEventListener('click', () => {
				btn.disabled = true;
				btn.textContent = 'Перезапускаю…';
				callInit(s[0], 'restart').then(() => setTimeout(() => location.reload(), 4000));
			});

			return E('div', { 'class': 'bd-svc' }, [
				E('label', { 'class': 'bd-svc-state' }, [ E('i', { 'class': running ? 'on' : (known ? 'off' : 'none') }) ]),
				E('div', { 'class': 'bd-svc-main' }, [
					E('div', { 'class': 'bd-svc-name' }, [ s[1] ]),
					E('div', { 'class': 'bd-sub ' + (running ? 'ok' : 'warn') }, [ running ? 'Работает' : (known ? 'Остановлена' : 'Не установлена') ])
				]),
				E('div', { 'class': 'bd-svc-descr' }, [ s[2],
					s[0] == 'ssclash' ? E('a', { 'href': '%s//%s:9091/settings'.format(location.protocol, location.hostname), 'target': '_blank', 'rel': 'noopener' }, [ ' Открыть панель ', ico('ext', 'small') ]) : '' ]),
				known ? btn : ''
			]);
		});

		const shown = rows.filter(r => r);
		return shown.length ? card('Службы', shown) : '';
	},

	render(data) {
		const [ ifaces, devices, wireless, hints, leases, info, board, arp, , services, assoc ] = data;

		const view = E('div', { 'class': 'bd' }, [
			E('style', {}, [ CSS ]),
			E('div', { 'class': 'bd-grid' }, [
				E('div', { 'class': 'bd-col' }, [ this.renderInternet(ifaces, devices), this.renderClients(hints, leases, arp, assoc) ]),
				E('div', { 'class': 'bd-col' }, [ this.renderWifi(wireless, assoc), this.renderPorts(devices), this.renderSystem(info, board), this.renderServices(services) ])
			])
		]);

		this.drawChart();
		poll.add(L.bind(this.pollTraffic, this), 2);
		return view;
	},

	handleSaveApply: null,
	handleSave: null,
	handleReset: null
});
BOBR_EOF
cat > /usr/share/luci/menu.d/luci-app-bobr-dashboard.json <<'BOBR_EOF'
{
	"admin/status/dashboard": {
		"title": "Панель",
		"order": -1,
		"action": {
			"type": "view",
			"path": "bobr/dashboard"
		},
		"depends": {
			"acl": [ "luci-app-bobr-dashboard" ]
		}
	}
}
BOBR_EOF
cat > /usr/share/rpcd/acl.d/luci-app-bobr-dashboard.json <<'BOBR_EOF'
{
	"luci-app-bobr-dashboard": {
		"description": "Панель темы «Бобр»",
		"read": {
			"ubus": {
				"luci-rpc": [
					"getHostHints",
					"getDHCPLeases",
					"getNetworkDevices",
					"getWirelessDevices"
				],
				"iwinfo": [
					"assoclist",
					"info"
				],
				"network.interface": [
					"dump"
				],
				"system": [
					"info",
					"board"
				],
				"service": [
					"list"
				]
			},
			"file": {
				"/proc/net/arp": [
					"read"
				],
				"/etc/init.d/ssclash": [
					"list",
					"read"
				],
				"/etc/init.d/podkop": [
					"list",
					"read"
				],
				"/etc/init.d/jarvis-music": [
					"list",
					"read"
				],
				"/etc/init.d/dnsmasq": [
					"list",
					"read"
				]
			},
			"uci": [
				"wireless"
			]
		},
		"write": {
			"ubus": {
				"luci": [
					"setInitAction"
				]
			},
			"uci": [
				"wireless"
			]
		}
	}
}
BOBR_EOF
uci set luci.themes.Bobr=/luci-static/bobr
uci set luci.main.mediaurlbase=/luci-static/bobr
uci commit luci
rm -rf /tmp/luci-*
/etc/init.d/rpcd restart
echo "Готово: тема «Бобр» и Панель установлены."
echo "Выйдите из веб-интерфейса и войдите снова, затем обновите страницу: Cmd+Shift+R."
echo "Вернуть стандартную тему:  sh /root/install-bobr-theme.sh --remove"
