$(document).ready(function(){
  var clientSeachOptions = {
    valueNames: [ 'full-name', 'last-contact' ]
  };

  var clientList = new List('client-list', clientSeachOptions);

  clientList.on('updated', function(list){
    if(list.matchingItems.length === 0){
      $('#no-search-results').show();
    } else {
      $('#no-search-results').hide();
    }
  });

  $('#clear_search').click(function(){
    $('.search').val('');
    clientList.search();
  });
});
