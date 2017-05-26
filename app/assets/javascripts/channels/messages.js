//= require cable
//= require_self
//= require_tree .

$(document).ready(function() {
  messages = $('#message-list');
  clientId = messages.data('client-id');
  messages_to_bottom = function() {
    return $(document).scrollTop(messages.prop('scrollHeight'));
  };

  App.messages = App.cable.subscriptions.create(
    { channel: 'MessagesChannel', client_id: clientId },
    {
      received: function(data) {
        return this.renderMessage(data.message);
      },

      renderMessage: function(message) {
        $.ajax(`/messages/${message.id}`).done(function(data) {
          $('#message-list').append(data);
          messages_to_bottom();
        });
      }
    }
  );
});
