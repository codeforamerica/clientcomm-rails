/**
 * Jquery Inview 2
 * Version: 0.1
 * Author: Matthew Frey (mmmeff)
 *    - forked from http://github.com/protonet/jquery.inview/
 */
(function ($) {
  var inviewObjects = {},
      d = document,
      w = window,
      documentElement = d.documentElement,
      expando = $.expando,
      timer,
      // pixel count margins to wrap viewport (negative gives extra time for dom to render)
      yMargin = -300,
      xMargin = 0;

  $.event.special.inview = {
    add: function(data) {
      inviewObjects[data.guid + "-" + this[expando]] = { data: data, $element: $(this) };

      // Use setInterval in order to also make sure this captures elements within
      // "overflow:scroll" elements or elements that appeared in the dom tree due to
      // dom manipulation and reflow
      // old: $(window).scroll(checkInView);
      //
      // By the way, iOS (iPad, iPhone, ...) seems to not execute, or at least delays
      // intervals while the user scrolls. Therefore the inview event might fire a bit late there
      // 
      // Don't waste cycles with an interval until we get at least one element that
      // has bound to the inview event.  
      if (!timer && !$.isEmptyObject(inviewObjects)) {
         timer = setInterval(checkInView, 333);
      }
    },

    remove: function(data) {
      try { delete inviewObjects[data.guid + "-" + this[expando]]; } catch(e) {}

      // Clear interval when we no longer have any elements listening
      if ($.isEmptyObject(inviewObjects)) {
         clearInterval(timer);
         timer = null;
      }
    }
  };

  function checkInView() {
    // Fuck IE and its quirks, we're doing this the right way.
    var $elements = $();

    $.each(inviewObjects, function(i, inviewObject) {
      var selector  = inviewObject.data.selector,
          $element  = inviewObject.$element;

      $elements = $elements.add(selector ? $element.find(selector) : $element);
    });

    if ($elements.length) {
      for (var i = 0; i < $elements.length; i++) {
        if (!$elements[i]) {
          continue;
        } else if (!$.contains(documentElement, $elements[i])) {
          delete $elements[i];
          continue;
        }

        var $el = $($elements[i]),
            inView = $el.data('inview'),
            rect = $el[0].getBoundingClientRect(),
            height = $el.height(),
            width = $el.width();
        
        if (rect.top >= (0 - height + yMargin) &&
            rect.left >= (0 - width + xMargin) &&
            rect.bottom <= ((w.innerHeight || documentElement.clientHeight) + height - yMargin) &&
            rect.right <= ((w.innerWidth || documentElement.clientWidth) + width - xMargin)) {
          if (!inView) {
            // object has entered viewport
            $el.data('inview', true).trigger('inview', [true]);
          }
        } else if (inView) {
          // object has left viewport
          $el.data('inview', false).trigger('inview', [false]);
        }
      }
    }
  }
})(jQuery);