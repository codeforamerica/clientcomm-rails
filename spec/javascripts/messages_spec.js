//= require jquery3
//= require messages

function setCharacterCountFixtures () {
  jasmine.getFixtures().set(`
    <body>
      <input type='text'></input>
    </body>
  `);
}

describe('Messages', function() {
  describe('#characterCount', function() {
    beforeEach(function() {
      setCharacterCountFixtures();
      jasmine.clock().install();
    });

    afterEach(function() {
      jasmine.clock().uninstall();
    });

    it('shows a warning message for texts over 160 characters', function () {
      var $page = $('body');
      var $element = $("input[type='text']");

      characterCount($element);

      $element.val(`
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt
        ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation
        ullamco laboris nisi ut aliquip ex ea commodo consequat.
      `);

      $element.trigger('keydown');

      jasmine.clock().tick();

      expect($('.character-count').text()).toBe("Because of its length, this message may be sent as 2 texts.");
    });
  });
});
