//= require cable
//= require_self
//= require_tree .

var ScheduledMessages = {
  init: function() {
    this.link = $('#scheduled_messages_link');
    this.clientId = $('#message-list').data('client-id');
  },
  updateLink: function(link_html, count) {
    if (count > 0) {
      this.link.html(link_html);
    } else {
      this.link.remove()
    }
  }
};

$(document).ready(function() {
  ScheduledMessages.init();

  // only subscribe if we're on a message page
  if (!ScheduledMessages.clientId) {
    return;
  }

  App.scheduledMessages = App.cable.subscriptions.create(
    { channel: 'ScheduledMessagesChannel', client_id: ScheduledMessages.clientId },
    {
      received: function(data) {
        console.log(data)
        ScheduledMessages.updateLink(data.link_html, data.count);
      }
    }
  );
});
