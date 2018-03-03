$(document).ready(function() {
  $('.template--mass-messages').find('tbody :checkbox').each(function(index, checkbox) {
    $(checkbox).change(function(event) {
      $(checkbox).closest('tr').toggleClass('row--warning');

      if (!this.checked) {
        $('#select_all')[0].checked = false;
      }
    });
  });

  characterCount($('.template--mass-messages #mass_message_message'));

  $('.template--mass-messages #select_all').change(function () {
    var selected = this.checked;

    $('#new_mass_message').find('tbody :checkbox').each(function () {
      if (this.checked !== selected) {
        this.click();
      }
    });
  });

  var formState = {
    scheduleFormVisible: false,
  };

  $('#send_later').click(function(e) {
    if (!formState.scheduleFormVisible) {
      e.preventDefault();
      $(this).prop('disabled', true);
      $(this).addClass('button--cta button--disabled');
      $('#schedule-later-form').show();
      formState.scheduleFormVisible = true;
    }
  });

  $('#schedule-later-form').click(function() {
    checked = ($(this).find(":checkbox:checked").length > 0);
    $('#send_later').prop('disabled', !checked);
    $('#send_later').toggleClass('button--disabled', !checked);
  });
});
