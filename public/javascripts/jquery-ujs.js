/*
 * Padrino Javascript Jquery Adapter
 * Created for use with Padrino Ruby Web Framework (http://www.padrinorb.com)
**/

/* Remote Form Support
 * form_for @user, '/user', :remote => true
**/

$(function(){
    $('form').on('submit', function(e) {
      var element = $(this), message = element.data('confirm');
      if (message && !confirm(message)) { return false; }
      if (element.data('remote') == true) {
        e.preventDefault(); e.stopped = true;
        JSAdapter.sendRequest(element, {
          verb: element.data('method') || element.attr('method') || 'post',
          url: element.attr('action'),
          dataType: element.data('type') || ($.ajaxSettings && $.ajaxSettings.dataType) || 'script',
          params: element.serializeArray()
        });
      }
    });

    /* Confirmation Support
     * link_to 'sign out', '/logout', :confirm => 'Log out?'
    **/

    $(document).on('click', 'a[data-confirm]', function(e) {
      var message = $(this).data('confirm');
      if (!confirm(message)) { e.preventDefault(); e.stopped = true; }
    });

    /*
     * Link Remote Support
     * link_to 'add item', '/create', :remote => true
    **/

    $(document).on('click', 'a[data-remote=true]', function(e) {
      var element = $(this);
      if (e.stopped) return;
      e.preventDefault(); e.stopped = true;
      JSAdapter.sendRequest(element, {
        verb: element.data('method') || 'get',
        url: element.attr('href')
      });
    });

    /*
     * Link Method Support
     * link_to 'delete item', '/destroy', :method => :delete
    **/

    $(document).on('click', 'a[data-method]:not([data-remote])', function(e) {
      if (e.stopped) return;
      JSAdapter.sendMethod($(this));
      e.preventDefault(); e.stopped = true;
    });

    /* JSAdapter */
    var JSAdapter = {
      // Sends an xhr request to the specified url with given verb and params
      // JSAdapter.sendRequest(element, { verb: 'put', url : '...', params: {} });
      sendRequest: function(element, options) {
        var verb = options.verb, url = options.url, params = options.params, dataType = options.dataType;
        var event = element.trigger('ajax:before');
        if (event.stopped) return false;
        $.ajax({
          url: url,
          type: verb.toUpperCase() || 'POST',
          data: params || [],
          dataType: dataType,

          beforeSend: function(request) { element.trigger('ajax:loading',  [ request ]); },
          complete:   function(request) { element.trigger('ajax:complete', [ request ]); },
          success:    function(request) { element.trigger('ajax:success',  [ request ]); },
          error:      function(request) { element.trigger('ajax:failure',  [ request ]); }
        });
        element.trigger('ajax:after');
      },
      // Triggers a particular method verb to be triggered in a form posting to the url
      // JSAdapter.sendMethod(element);
      sendMethod: function(element) {
        var verb = element.data('method');
        var url = element.attr('href');
        var form = $('<form method="post" action="'+url+'"></form>');
        var csrf_token = $('meta[name=csrf-token]').attr('content');
        var csrf_param = $('meta[name=csrf-param]').attr('content');
        form.hide().appendTo('body');
        if (verb !== 'post') {
          var field = '<input type="hidden" name="_method" value="' + verb + '" />';
          form.append(field);
        }
        if (csrf_param !== undefined && csrf_token !== undefined) {
          var field = '<input type="hidden" name="' + csrf_param + '" value="' + csrf_token + '" />';
          form.append(field);
        }
        form.submit();
      }
    };

    // Every xhr request is sent along with the CSRF token.
    $.ajaxPrefilter(function(options, originalOptions, xhr) {
      if (options.verb !== 'GET') {
        var token = $('meta[name="csrf-token"]').attr('content');
        if (token) xhr.setRequestHeader('X-CSRF-Token', token);
      }
    });
});
