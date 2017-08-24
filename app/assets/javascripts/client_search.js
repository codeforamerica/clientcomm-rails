$(document).ready(function(){
  var clientSearchOptions = {
    valueNames: [
      { attr: 'data-fullname', name: 'fullname' },
      { attr: 'data-lastname', name: 'lastname' },
      { attr: 'data-timestamp', name: 'timestamp' }
    ]
  };

  var clientList = new List('client-list', clientSearchOptions);

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
