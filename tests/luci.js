/* Contract fixture, not a real browser/LuCI integration test. */
const fs = require('fs');
const assert = require('assert');
const options = {};
let callback;
function E(tag, attrs, children) { return {tag, attrs, children, textContent: ''}; }
class Map {
 constructor() {}
 section() { return { option(Type, name) {
  return options[name] = { value() {}, depends() {}, cfgvalue() {
   return { stop: '45', start: '50', full: '70', critical: '80' }[name];
  }, formvalue() {
   return { stop: '45', start: '50', full: '70', critical: '80' }[name];
  }};
 }}; }
 lookupOption(name) { return [options[name]]; }
 render() { return Promise.resolve({}); }
}
let state = {running: true, temperature: 60000, target: 70, actual: 70, reason: 'normal', pwm_ok: true};
const source = fs.readFileSync(__dirname + '/../htdocs/luci-static/resources/view/rpi-fan.js', 'utf8');
const app = new Function('view', 'form', 'rpc', 'poll', 'E', source)(
 {extend: x => x}, {Map, NamedSection: {}, Flag: {}, ListValue: {}, Value: {}},
 {declare: declaration => { assert.equal(declaration.object, 'rpi-fan'); return () => Promise.resolve(state); }},
 {add: fn => callback = fn}, E);
(async () => {
 const node = await app.render();
 assert.equal(options.manual.retain, true, 'mode switches must preserve manual duty');
 assert.equal(options.minimum.retain, true, 'mode switches must preserve auto minimum');
 for (const name of ['manual', 'minimum']) {
  assert.equal(typeof options[name].validate, 'function', 'duty needs integer validation');
  assert.equal(options[name].validate('main', '50'), true);
  assert.notEqual(options[name].validate('main', '50.5'), true);
  assert.notEqual(options[name].validate('main', '050'), true);
 }
 await callback();
 const box = node.children[1];
 assert(box.textContent.includes('60.0') && box.textContent.includes('70%'));
 assert.equal(options.start.validate('main', '50'), true);
 assert.notEqual(options.start.validate('main', '40'), true);
 assert.notEqual(options.start.validate('main', '050'), true);
 // Initial widget validation can precede siblings being mounted in the DOM.
 const readStart = options.start.formvalue;
 options.start.formvalue = () => undefined;
 assert.equal(options.full.validate('main', '70'), true);
 options.start.formvalue = readStart;
 state = {running: false}; await callback();
 assert(box.textContent.includes('未运行'));
 console.log('PASS: LuCI form/status contract and cross-field validation');
})().catch(e => { console.error(e); process.exitCode = 1; });
