//= require cable
//= require_self
//= require_tree .

var ScheduledMessages = {
  updateLink: function(link_html, count) {
    $('.scheduled-messages-bar').remove()
  }
};

$(document).ready(function() {
  const clientId = $('#message-list').data('client-id');

  // only subscribe if we're on a message page
  if (!clientId) {
    return;
  }

  App.scheduledMessages = App.cable.subscriptions.create(
    { channel: 'ScheduledMessagesChannel', client_id: clientId },
    {
      received: function(data) {
        ScheduledMessages.updateLink(data.link_html, data.count);
      }
    }
  );
});
