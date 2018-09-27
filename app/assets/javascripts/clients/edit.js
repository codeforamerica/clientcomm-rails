$(document).ready(function() {
  var formState = {
    surveyResponsesVisible: false,
  };

  $('#deactivate_client').click(function(e) {
    if (!formState.surveyResponsesVisible) {
      e.preventDefault();
      $(this).prop('disabled', true);
      $(this).addClass('button--cta button--disabled');
      $('#survey').show();
      formState.surveyResponsesVisible = true;
    }
  });

  $('#survey').click(function() {
    checked = ($(this).find(":checkbox:checked").length > 0);
    $('#deactivate_client').prop('disabled', !checked);
    $('#deactivate_client').toggleClass('button--disabled', !checked);
  });


  function uncheckMergeRadioButtons() {
    $('#new_merge_reporting_relationship input:radio').each(function() { $(this).prop('checked', false); })
  }

  $('#merge_reporting_relationship_selected_client_id').change(function() {
    var selected_client_id = $('#merge_reporting_relationship_selected_client_id option:selected').val();
    var selected_client_name = $('#merge_reporting_relationship_selected_client_id option:selected').text();
    var selected_client_phone_number = $('#merge_reporting_relationship_selected_client_id option:selected').data('phone-number');

    $('#merge_full_names label:nth-child(2) input').val(selected_client_id)
    $('#merge_full_names label:nth-child(2) span').text(selected_client_name)

    $('#merge_phone_numbers label:nth-child(2) input').val(selected_client_id)
    $('#merge_phone_numbers label:nth-child(2) span').text(selected_client_phone_number)

    uncheckMergeRadioButtons();

    // TODO: deactivate the merge submit button

    $('#merge').show();
  });

  // TODO: when a radio button choice is made, if a radio button has been chosen in
  //       both categories, enable the merge submit button.

});
