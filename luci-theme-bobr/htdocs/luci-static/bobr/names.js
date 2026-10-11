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
