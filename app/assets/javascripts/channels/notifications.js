var Notifications = {
  init: function(client_id_selector) {
    this.clientId = $(client_id_selector).data('client-id');
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


  App.notifications = App.cable.subscriptions.create(
    { channel: 'NotificationsChannel' },
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
          if ($(".unread-warning").length) {
            clientId = $('#reporting_relationship_client_id').attr('value');
            if (data.properties.client_id == clientId) {
              $('.unread-warning').removeClass('hidden')
            }
          }
        }
        Notifications.updateNotification(data.notification_html);
      }
    }
  );
});
