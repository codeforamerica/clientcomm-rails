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
    })
  });
});
