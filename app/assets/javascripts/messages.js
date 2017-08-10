$(document).ready(function(){
  $(document).on('submit', '#new_message', function(e) {
    // clear the message body text field
    $('#message_body').val('');
  });

  $('#send_later').click(function(){
    var sendLaterMessage = $('input#message_body.main-message-input').val();
    $('textarea#scheduled_message_body.send-later-input').val(sendLaterMessage);
  });

  $('#edit-message-modal').modal();
  $('#edit-message-modal').on('shown.bs.modal', function () {
    $('textarea#scheduled_message_body.send-later-input.textarea').focus();
  });
  $('#edit-message-modal').on('hidden.bs.modal', function(e) {
    e.preventDefault();
    window.location = $('.close').attr('href');
  });

  $('#new-message-modal').modal();
  $('#new-message-modal').on('shown.bs.modal', function () {
    $('textarea#scheduled_message_body.send-later-input.textarea').focus();
  });
  $('#new-message-modal').on('hidden.bs.modal', function(e) {
    e.preventDefault();
    window.location = $('.close').attr('href');
  });

  $("#edit_message_send_at_date").datepicker();
  $("#edit_message_send_at_date").datepicker("option", "showAnim", "");

  $("#new_message_send_at_date").datepicker();
  $("#new_message_send_at_date").datepicker("option", "showAnim", "");

  // Auto-expand sendbar textarea
  $(document).one('focus.autoExpand', 'textarea.autoExpand', function() {
      var savedValue = this.value;
      this.value = '';
      this.baseScrollHeight = this.scrollHeight;
      this.value = savedValue;
  })
  .on('input.autoExpand', 'textarea.autoExpand', function() {
      var
        minRows = this.getAttribute('data_min_rows') | 0,
        maxRows = this.getAttribute('data_max_rows') | 4,
        additionalRows,
        totalRows;

      this.rows = minRows;
      additionalRows = Math.ceil((this.scrollHeight - this.baseScrollHeight) / 28);
      totalRows = minRows + additionalRows;
      totalRows <= maxRows ? this.rows = totalRows : this.rows = maxRows;
  });
});
