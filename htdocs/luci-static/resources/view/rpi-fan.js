'use strict';
'require view';
'require form';
'require rpc';
'require poll';

var getStatus = rpc.declare({ object: 'rpi-fan', method: 'status', expect: {} });
function integer(section, value) {
 return /^(0|[1-9][0-9]*)$/.test(value) ? true : '请输入不带前导零的整数';
}

return view.extend({
 render: function() {
  var m = new form.Map('rpi-fan', '树莓派风扇',
   'GPIO18 · PWM0 · 1 kHz。保存并应用后约 2 秒生效。超温、温度故障或配置错误时强制全速；停止服务时保持全速。占空比不代表实际转速。');
  var s = m.section(form.NamedSection, 'main', 'fan', '控制设置');
  var o = s.option(form.Flag, 'enabled', '开启风扇');
  o.rmempty = false;
  o = s.option(form.ListValue, 'mode', '模式');
  o.value('auto', '自动温控'); o.value('manual', '手动'); o.rmempty = false;
  o = s.option(form.Value, 'manual', '手动占空比 (%)');
  o.datatype = 'range(0,100)'; o.rmempty = false; o.retain = true; o.depends('mode', 'manual');
  o.validate = integer;
  o = s.option(form.Value, 'minimum', '自动模式最低占空比 (%)');
  o.datatype = 'range(1,100)'; o.rmempty = false; o.retain = true; o.depends('mode', 'auto');
  o.validate = integer;
  var fields = [ ['stop', '停止温度 (°C)', 0, 100], ['start', '启动温度 (°C)', 1, 110],
   ['full', '全速温度 (°C)', 2, 115], ['critical', '安全强制全速温度 (°C)', 3, 120] ];
  var thresholds = {};
  fields.forEach(function(f) {
   var v = s.option(form.Value, f[0], f[1]);
   thresholds[f[0]] = v;
   v.datatype = 'range(' + f[2] + ',' + f[3] + ')'; v.rmempty = false;
   v.validate = function(section, value) {
    if (!/^(0|[1-9][0-9]*)$/.test(value)) return '请输入整数';
    var values = fields.map(function(k) {
     var input = thresholds[k[0]];
     var current = k[0] === f[0] ? value : input.formvalue(section);
     if (current == null) current = input.cfgvalue(section);
     return Number(current);
    });
    return values[0] < values[1] && values[1] < values[2] && values[2] < values[3]
     ? true : '必须满足：停止 < 启动 < 全速 < 安全温度';
   };
  });
  var box = E('p', {}, '正在读取运行状态…');
  var reasons = { normal: '正常', off: '已关闭', critical: '超温强制全速',
   config_error: '配置错误，强制全速', sensor_error: '温度读取失败，强制全速', pwm_error: 'PWM 写入失败，正在重试' };
  function update() {
   return getStatus().then(function(st) {
    box.textContent = st.running
     ? '温度：' + (st.temperature == null ? '未知' : (st.temperature / 1000).toFixed(1) + ' °C') +
       ' ｜ 目标：' + st.target + '% ｜ PWM 读回：' + (st.actual == null ? '未知' : st.actual + '%') +
       ' ｜ ' + (reasons[st.reason] || st.reason) + (st.pwm_ok ? '' : '（PWM 异常）')
     : '服务未运行或状态超过 10 秒未更新。请检查服务及系统日志。';
   }).catch(function() { box.textContent = '状态接口不可用，请检查 rpcd 服务。'; });
  }
  return m.render().then(function(node) {
   poll.add(update, 2); update();
   return E('div', {}, [E('h3', {}, '实时状态'), box, node]);
  });
 }
});
