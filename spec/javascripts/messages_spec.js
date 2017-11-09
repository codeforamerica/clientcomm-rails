//= require jquery3
//= require messages

describe('Messages', function() {
  describe('#characterCount', function() {
    beforeEach(function() {
      jasmine.clock().install();
    });

    afterEach(function() {
      jasmine.clock().uninstall();
    });

    it('creates and modifies the counter', function() {
      $page = $('<body></body>');
      $element = $("<input type='text'></input>");

      $page.append($element);

      characterCount($element);

      $element.val('test');

      $element.trigger('keydown');

      jasmine.clock().tick();

      expect($page.find('.character-count').text()).toBe('4');
    });
  });
});
