$(document).ready(function() {
  var formState = {
    surveyVisible: false,
    surveyResponses: []
  }

  $('#deactivate_client').click(function() {
    $('#survey').show()

    $(this).addClass('button--cta')
  })

  $('#survey').click(function() {

  })
})
