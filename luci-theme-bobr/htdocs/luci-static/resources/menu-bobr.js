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
			nav.appendChild(E('div', { 'class': 'side-label' }, [ _('Быстрый доступ') ]));
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
			const label = _((MODES.find(x => x[0] == m) || MODES[0])[1]);
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
