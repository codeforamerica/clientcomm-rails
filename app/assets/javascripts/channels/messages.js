//= require cable
//= require_self
//= require_tree .

$(document).ready(function() {
  var messages, messages_to_bottom;
  messages = $('#message-list');
  clientId = messages.data('client-id');
  messages_to_bottom = function() {
    return $(document).scrollTop(messages.prop('scrollHeight'));
  };

  App.messages = App.cable.subscriptions.create(
    { channel: 'MessagesChannel', client_id: clientId },
    {
      received: function(data) {
        messages.append(data.message_html);
        return messages_to_bottom();
      }
    }
  );
});
