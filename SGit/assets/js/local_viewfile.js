// Generated by CoffeeScript 1.6.3
(function() {
  var displayFileContent, lang, lineNumber, rawCodes, requestLocal;

  requestLocal = function(request) {
    return document.location.href = "ios://" + request;
  };

  rawCodes = void 0;

  lang = void 0;

  lineNumber = void 0;

  displayFileContent = function() {
    var highlighted, i, length, lineNumbers, lineNumbersList;
    if (lang) {
      highlighted = hljs.highlight(lang, rawCodes, true);
      $('.codes code').html(highlighted.value);
      $('.codes code').addClass(highlighted.language);
    } else {
      $('.codes code').html(rawCodes);
    }
    length = lineNumber;
    lineNumbersList = (function() {
      var _i, _results;
      _results = [];
      for (i = _i = 1; 1 <= length ? _i <= length : _i >= length; i = 1 <= length ? ++_i : --_i) {
        _results.push(i + '.');
      }
      return _results;
    })();
    lineNumbers = lineNumbersList.join('\n');
    return $('.line_numbers').html(lineNumbers);
  };

  window.notifyFileLoaded = function() {
    return displayFileContent();
  };

  window.setLanguage = function(lang) {
    return displayFileContent(lang);
  };

  window.setLang = function(l) {
    return lang = l;
  };

  window.setRawCodes = function(raw) {
    return rawCodes = raw;
  };

  window.setLineNumber = function(num) {
    return lineNumber = num;
  };

  window.display = displayFileContent;

  $(document).ready(function() {
    return requestLocal('init');
  });

}).call(this);
