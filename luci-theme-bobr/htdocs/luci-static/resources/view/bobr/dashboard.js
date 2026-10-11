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
