function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : { default: obj };
}

const _path = _interopRequireDefault(require('path'));
const _fs = require('fs');

const openUrlFile = _path.default.join(
  process.env.HOME,
  '.config',
  'Ferdium',
  'config',
  'msteams-open-url',
);
const teamsHosts = new Set([
  'teams.microsoft.com',
  'teams.cloud.microsoft',
  'teams.live.com',
]);
const maxPendingAgeMs = 2 * 60 * 1000;

module.exports = Ferdium => {
  const getMessages = () => {
    let messages = 0;

    const isTeamsV2 =
      window.location.href.includes('/v2/') ||
      window.location.host == 'teams.cloud.microsoft';

    let badges = document.querySelectorAll(
      '.activity-badge.dot-activity-badge .activity-badge',
    );

    if (isTeamsV2) {
      badges = document.querySelectorAll('.fui-Badge');
    }

    if (badges) {
      Array.prototype.forEach.call(badges, badge => {
        messages += Ferdium.safeParseInt(badge.textContent);
      });
    }

    const indirectMessages =
      document.querySelectorAll('.app-bar-mention').length;

    Ferdium.setBadge(messages, indirectMessages);
  };

  window.addEventListener('beforeunload', async () => {
    _fs.unwatchFile(openUrlFile);
    Ferdium.releaseServiceWorkers();
  });

  Ferdium.loop(getMessages);

  Ferdium.injectCSS(_path.default.join(__dirname, 'service.css'));
  Ferdium.injectJSUnsafe(_path.default.join(__dirname, 'webview-unsafe.js'));

  // local addition: url-router drops Teams links here, see ~/.local/bin/url-router
  const openPendingUrl = stat => {
    if (!stat || stat.size === 0 || Date.now() - stat.mtimeMs > maxPendingAgeMs) {
      return;
    }
    let url;
    try {
      url = _fs.readFileSync(openUrlFile, 'utf8').trim();
      _fs.writeFileSync(openUrlFile, '');
    } catch {
      return;
    }
    let parsed;
    try {
      parsed = new URL(url);
    } catch {
      return;
    }
    if (parsed.protocol !== 'https:' || !teamsHosts.has(parsed.hostname)) {
      return;
    }
    window.location.href = url;
  };

  _fs.watchFile(openUrlFile, { interval: 500 }, openPendingUrl);
  try {
    openPendingUrl(_fs.statSync(openUrlFile));
  } catch {
    // nothing pending
  }
};
