String.prototype.rtrim = () ->
  return this.replace /\s+$/,''

requestLocal = (request, json) ->
  if json is undefined
    document.location.href = "ios://#{request}"
  else
    document.location.href = "ios://#{json}/#{request}"

rawCodes = undefined
lang = undefined
editor = undefined

displayFileContent = () ->
  $('#editor').text rawCodes
  editorElm = document.getElementById "editor"
  editorOption =
    lineNumbers: true
    mode: lang
    matchBrackets: true
    lineWrapping: true
    readOnly: true
  editor = CodeMirror.fromTextArea editorElm, editorOption

window.notifyFileLoaded = () ->
  displayFileContent()

window.setLanguage = (lang) ->
  displayFileContent(lang)

window.setLang = (l) ->
  lang = l
  if editor
    editor.setOption 'mode', lang

window.setRawCodes = (raw) ->
  rawCodes = raw

window.display = displayFileContent

window.setEditable= () ->
  editor.setOption "readOnly", false

window.save = () ->
  editor.setOption "readOnly", true
  value = editor.getValue().rtrim()
  return value

$(document).ready ()->
  requestLocal 'init'
