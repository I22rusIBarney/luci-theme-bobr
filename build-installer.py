files = [
 ("/usr/share/ucode/luci/template/themes/bobr/header.ut", "luci-theme-bobr/ucode/template/themes/bobr/header.ut"),
 ("/usr/share/ucode/luci/template/themes/bobr/footer.ut", "luci-theme-bobr/ucode/template/themes/bobr/footer.ut"),
 ("/usr/share/ucode/luci/template/themes/bobr/sysauth.ut", "luci-theme-bobr/ucode/template/themes/bobr/sysauth.ut"),
 ("/www/luci-static/bobr/cascade.css", "luci-theme-bobr/htdocs/luci-static/bobr/cascade.css"),
 ("/www/luci-static/bobr/names.js", "luci-theme-bobr/htdocs/luci-static/bobr/names.js"),
 ("/www/luci-static/resources/menu-bobr.js", "luci-theme-bobr/htdocs/luci-static/resources/menu-bobr.js"),
 ("/www/luci-static/resources/view/bobr/dashboard.js", "luci-theme-bobr/htdocs/luci-static/resources/view/bobr/dashboard.js"),
 ("/usr/share/luci/menu.d/luci-app-bobr-dashboard.json", "luci-theme-bobr/root/usr/share/luci/menu.d/luci-app-bobr-dashboard.json"),
 ("/usr/share/rpcd/acl.d/luci-app-bobr-dashboard.json", "luci-theme-bobr/root/usr/share/rpcd/acl.d/luci-app-bobr-dashboard.json"),
]
out = ['#!/bin/sh',
'# Тема «Бобр» для LuCI (OpenWrt 23.05) + Панель в духе Keenetic.',
'# Установка:  sh install-bobr-theme.sh        Откат на стандартную тему:  sh install-bobr-theme.sh --remove',
'set -e',
'if [ "$1" = "--remove" ]; then',
'  uci set luci.main.mediaurlbase=/luci-static/bootstrap; uci -q delete luci.themes.Bobr || true; uci commit luci',
'  rm -rf /usr/share/ucode/luci/template/themes/bobr /www/luci-static/bobr /www/luci-static/resources/menu-bobr.js \\',
'         /www/luci-static/resources/view/bobr /usr/share/luci/menu.d/luci-app-bobr-dashboard.json \\',
'         /usr/share/rpcd/acl.d/luci-app-bobr-dashboard.json /tmp/luci-*',
'  /etc/init.d/rpcd restart',
'  echo "Тема и Панель удалены, включена стандартная тема. Обновите страницу роутера."; exit 0',
'fi',
'[ -f /www/luci-static/bootstrap/cascade.css ] || { echo "Нет стандартной темы bootstrap: opkg install luci-theme-bootstrap"; exit 1; }',
'mkdir -p /usr/share/ucode/luci/template/themes/bobr /www/luci-static/bobr /www/luci-static/resources/view/bobr /usr/share/luci/menu.d /usr/share/rpcd/acl.d']
for dst, src in files:
    body = open(src).read()
    assert 'BOBR_EOF' not in body
    out += [f"cat > {dst} <<'BOBR_EOF'", body.rstrip('\n'), 'BOBR_EOF']
out += [
'uci set luci.themes.Bobr=/luci-static/bobr',
'uci set luci.main.mediaurlbase=/luci-static/bobr',
'uci commit luci',
'rm -rf /tmp/luci-*',
'/etc/init.d/rpcd restart',
'echo "Готово: тема «Бобр» и Панель установлены."',
'echo "Выйдите из веб-интерфейса и войдите снова, затем обновите страницу: Cmd+Shift+R."',
'echo "Вернуть стандартную тему:  sh /root/install-bobr-theme.sh --remove"']
open('install-bobr-theme.sh','w').write('\n'.join(out)+'\n')
