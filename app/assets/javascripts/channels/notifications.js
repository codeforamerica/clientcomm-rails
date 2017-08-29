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
        if(data.properties && data.properties.client_id) {
          // only update if the client id doesn't match
          // (meaning we're not on that client's messages page)
          if (data.properties.client_id === Notifications.clientId) {
            return;
          }
          // the page we're on contains an element with id client-list
          if ($("#client-list").length) {
            Notifications.refreshClientList();
          }
        }
        Notifications.updateNotification(data.notification_html);
      }
    }
  );
});
