function replaceEmoji(element) {
  if (!Modernizr.emoji) {
    twemoji.parse(element)
  }
}

$(document).ready(function () {
  var messageList = document.getElementById('message-list')
  if (messageList) { replaceEmoji(messageList) }
})
