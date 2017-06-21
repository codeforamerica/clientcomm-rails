$(document).on('submit', '#new_message', function(e) {
  // clear the message body text field
  $('#message_body').val('');
});

// placement icon
var iconSVG =
  "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 {{w}} {{h}}'><defs><symbol id='a' viewBox='0 0 90 66' opacity='0.3'><path d='M85 5v56H5V5h80m5-5H0v66h90V0z'/><circle cx='18' cy='20' r='6'/><path d='M56 14L37 39l-8-6-17 23h67z'/></symbol></defs><use xlink:href='#a' width='20%' x='40%'/></svg>";

$(document).ready(function() {
  $(".attachment-img").each(function() {
    var $this = $(this),
      data = $this.data(), // Get all the data attributes
      $img = $("<img />")
        .attr({
          width: data.width,
          height: data.height,
          // Set src to temporary SVG with proper viewBox
          src: "data:image/svg+xml;charset=utf-8," +
            encodeURIComponent(
              iconSVG.replace(/{{w}}/g, data.width).replace(/{{h}}/g, data.height)
            )
        })
        .appendTo($this)
        // Load image on click
        .load(function() {
          $img.attr({
            src: data.src, // Set the src to the real image
            class: "",
            title: "" // clear out our temporary attributes
          });
        });
  });
  $(document).scrollTop($('#message-list').prop('scrollHeight'));
});
