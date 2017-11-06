function parseEmoji(element) {
  if (!Modernizr.emoji) {
    twemoji.parse(element)
  }
}

$(document).ready(function () {
  parseEmoji(document.getElementById('message-list'))
})
