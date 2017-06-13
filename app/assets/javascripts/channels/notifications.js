//= require cable
//= require_self
//= require_tree .

const Notifications = {
  init: function(client_id_selector) {
    this.clientId = $(client_id_selector).data('client-id');
    this.userId = $(document.body).data('user-id');
  },
  updateNotification: function(notification_html) {
    // replace or place the notification on the page
    var notificationElement = $("#dismiss-notice");
    if (notificationElement.length) {
        notificationElement.replaceWith(notification_html);
    } else {
        $(document.body).prepend(notification_html);
    }
  },
  refreshClientList: function() {
    // update the client list
    $.ajax({
      type: "GET",
      dataType: "script"
    });
  }
};

$(document).ready(function() {
  Notifications.init('#message-list');

  // only subscribe if we've got a user ID
  if (!Notifications.userId) {
    return;
  }

  App.notifications = App.cable.subscriptions.create(
    { channel: 'NotificationsChannel', user_id: Notifications.userId },
    {
      received: function(data) {
        // only update if the client id doesn't match
        // (meaning we're not on that client's messages page)
        if (data.client_id !== Notifications.clientId) {
          Notifications.updateNotification(data.notification_html);
          // and refresh the client list if it's on the page
          if ($("#client-list").length) {
            Notifications.refreshClientList();
          }
        }
      }
    }
  );
});
