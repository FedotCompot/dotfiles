const NATIVE_HOST = 'eu.fedot.url_router';
const status = document.getElementById('status');
const url = location.href.slice(location.href.indexOf('#') + 1);

const leaveTab = async () => {
  const tab = await chrome.tabs.getCurrent();
  if (history.length > 1) {
    chrome.tabs.goBack(tab.id);
  } else {
    chrome.tabs.remove(tab.id);
  }
};

chrome.runtime.sendNativeMessage(NATIVE_HOST, { url }, response => {
  const error = chrome.runtime.lastError?.message;
  if (error || !response?.ok) {
    status.textContent = `Could not hand off to Ferdium (${error ?? 'url-router failed'}). Link: ${url}`;
    return;
  }
  leaveTab();
});
