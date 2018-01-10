$(document).ready(function() {
  var formState = {
    surveyVisible: false,
  };

  $('#deactivate_client').click(function(e) {
    if (!formState.surveyVisible) {
      e.preventDefault();
      $(this).prop('disabled', true);
      $(this).addClass('button--cta');
      $('#survey').show();
      formState.surveyVisible = true;
    }
  });

  $('#survey').click(function() {
    checked = ($(this).children(":checkbox:checked").length > 0);
    $('#deactivate_client').prop('disabled', !checked);
  });
});
