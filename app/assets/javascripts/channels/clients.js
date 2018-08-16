var Clients = {
  init: function () {
    this.$clientList = $('#client-list');
  },
  refreshClientList: function () {
    $.ajax({
      type: "GET",
      dataType: "script"
    });
  }
};

$(document).ready(function () {
  Clients.init();

  // only subscribe if we've got a client list (e.g. clients index page)
  if (Clients.$clientList.length === 0) {
    return;
  }

  if ($("meta[name='current-user']").length > 0) {
    App.messages = App.cable.subscriptions.create(
      { channel: 'ClientsChannel' },
      {
        received: function() {
          Clients.refreshClientList();
        }
      }
    );
  }
});
