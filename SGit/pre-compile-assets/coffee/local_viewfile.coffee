requestLocal = (request) ->
  document.location.href = "ios://#{request}"

rawCodes = undefined
lang = undefined
lineNumber = undefined

displayFileContent = () ->
  if lang
    highlighted = hljs.highlight lang, rawCodes, true
    $('.codes code').html highlighted.value
    $('.codes code').addClass highlighted.language
  else
    $('.codes code').html rawCodes
    # highlighted = hljs.highlightAuto rawCodes
  length = lineNumber
  lineNumbersList = (i + '.' for i in [1 .. length])
  lineNumbers = lineNumbersList.join '\n'
  $('.line_numbers').html lineNumbers

window.notifyFileLoaded = () ->
  displayFileContent()

window.setLanguage = (lang) ->
  displayFileContent(lang)

window.setLang = (l) ->
  lang = l

window.setRawCodes = (raw) ->
  rawCodes = raw

window.setLineNumber = (num) ->
  lineNumber = num

window.display = displayFileContent

$(document).ready ()->
  requestLocal('init')
