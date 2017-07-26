$(document).ready(function(){
  $('#scheduled-list-modal').modal();

  $('#scheduled-list-modal').on('hidden.bs.modal', function() {
    window.location = ''
  });
})
