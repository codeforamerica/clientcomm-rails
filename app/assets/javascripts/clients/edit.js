$(document).ready(function() {
  var formState = {
    surveyVisible: false,
  };

  $('#deactivate_client').click(function(e) {
    if (!formState.surveyVisible) {
      e.preventDefault();
      $(this).prop('disabled', true);
      $(this).addClass('button--cta button--disabled');
      $('#survey').show();
      formState.surveyVisible = true;
    }
  });

  $('#survey').click(function() {
    checked = ($(this).find(":checkbox:checked").length > 0);
    $('#deactivate_client').prop('disabled', !checked);
    $('#deactivate_client').toggleClass('button--disabled', !checked);
  });
});
