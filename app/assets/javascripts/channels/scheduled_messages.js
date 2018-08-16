var ScheduledMessages = {
  updateLink: function(link_html, count) {
    var linkElement = $('.scheduled-messages-bar');
    if (count > 0) {
      linkElement.replaceWith(link_html);
    } else {
      linkElement.remove();
    }
  }
};

$(document).ready(function() {
  var clientId = $('#message-list').data('client-id');

  // only subscribe if we're on a message page
  if (!clientId) {
    return;
  }

  if ($("meta[name='current-user']").length > 0) {
    App.scheduledMessages = App.cable.subscriptions.create(
      { channel: 'ScheduledMessagesChannel', client_id: clientId },
      {
        received: function(data) {
          ScheduledMessages.updateLink(data.link_html, data.count);
        }
      }
    );
  }
});
