function checkMessageLength(textField) {
  var length = $(textField).val().length;
  isBlank = (length == 0);
  var tooLongToSend = length >= 1600;
  var cantSend = tooLongToSend || isBlank;
  $('#send_message').prop('disabled', cantSend);
  $('#send_message').toggleClass('button--disabled', cantSend);
}

$(document).ready(function(){
  element = $('.main-message-input');
  if (element.length != 0) {
    element.on('keydown keyup focus paste input', function(e){
      setTimeout(function(){
        checkMessageLength(element);
      });
    });
  }
});
