importScripts('https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js');
importScripts('https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-rust.min.js');
importScripts('https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-javascript.min.js');

self.onmessage = function(e) {
    const { code, lang } = e.data;
    const grammar = self.Prism.languages[lang] || self.Prism.languages.javascript;
    const html = self.Prism.highlight(code, grammar, lang);
    self.postMessage(html);
};
