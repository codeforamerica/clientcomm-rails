//= require twemoji-init

function setMessageListFixtures () {
  jasmine.getFixtures().set(`
    <div id='message-list'>
      <div>🎉</div>
      <div>🎉</div>
      <div>🎉</div>
      <div>🎉</div>
    </div>
  `)
}

describe('emoji parsing', function () {
  describe('on a browser with emoji support', function () {
    it('should do nothing', function () {
      Modernizr.emoji = true
      setMessageListFixtures()

      var messageList = document.getElementById('message-list')
      var initialHtml = messageList.innerHTML

      replaceEmoji(messageList)

      expect(messageList.innerHTML).toEqual(initialHtml)
    });
  });

  describe('on a browser without emoji support', function () {
    it('should replace any text emoji with images', function () {
      Modernizr.emoji = false
      setMessageListFixtures()

      var messageList = document.getElementById('message-list')
      var initialHtml = messageList.innerHTML

      replaceEmoji(messageList)

      expect(messageList.getElementsByTagName('img').length).toEqual(4)
    });
  });
});
