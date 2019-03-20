"use strict";

var MQBroker = MQBroker || {};
MQBroker = (function(NS) {

  NS.subscribers = {};
  
  NS.open = function(url, interval) {
    NS.url = url;
    NS.interval = interval;
    NS.ws = NS.connect(url, interval);
    return NS;
  };

  // Broker sender - it must reconnect if connection lost
  NS.send = function(msg) {
    switch(NS.ws.readyState) {
      case 1: //OPEN
        NS.ws.send(msg);
        break;
      case 0: //CONNECTING - wait for connection
        break;
      case 2: //CLOSING - wait for closing
        window.clearInterval(NS.pingInterval);
        break;
      case 3: //CLOSE - reconnect
        window.clearInterval(NS.pingInterval);
        NS.ws = NS.connect(NS.url, NS.interval);
        break;
    }
  };

  NS.connect = function(url, interval) {
    var ws = new WebSocket(url);

    console.log('connect init');

    ws.onopen = function() {
      Object.keys(NS.subscribers).map(function(key, index) { ws.send('subscribe ' + key) });
      NS.pingInterval = window.setInterval(function () {
        NS.send('ping');
      }, interval);
    };

    ws.onmessage = function(event) {
      var data = JSON.parse(event.data);
      if (typeof(data.event)!=="undefined") {
        if (typeof(NS.subscribers[data.event])==="function") {
          NS.subscribers[data.event+''](data.message);
        }
        else {
          console.log('Subscriber subscribers['+data.event+'] is not a function');
        }
      }
      else {
        console.log('Wrong message format');
      }
    };

    ws.onerror = function(error) {
      console.log(error);
      // stop pings before restore connection
      clearInterval(NS.pingInterval);
    };
    return ws;
  }

  NS.subscribe = function(event, cb) {
    // currently 1 subscriber has 1 callback
    NS.send('subscribe ' + event);
    NS.subscribers[event] = cb;
    return NS;
  };

  NS.unsubscribe = function(event) {
    NS.send('unsubscribe ' + event);
    NS.subscribers[event] = undefined;
    return NS;
  };

  return NS;

} (MQBroker));

var app = app || {};

app = (function (NS) {

  $ = jQuery;

  NS.redirect = function(url) {
    var path = window.location.pathname+window.location.search;
    var newpath = $('<a>').attr('href', url).prop('pathname')+$('<a>').attr('href', url).prop('search');
    $(location).prop('href', url);
    if (path == newpath) {
        window.location.reload(true);
    }
  };

  /*
   * USAGE:
   * app.alert({
   *  title:  "Alert title",
   *  text:   "Text message in alert body"
   * });
   *
   * OR
   *
   * app.alert({
   *  title:  "Alert title",
   *  html:   "<b>HTML</b> message in <i>alert</i> body"
   * });
   *
   */
  NS.alert = function(data) {
    $('#modal-alert').remove();
    var appx = $('<p>');
    if (typeof(data.text)!=="undefined") {
      appx.text(data.text);
    }
    else if (typeof(data.html)!=="underfined") {
      appx.html(data.html);
    }
    $('body').append(
      $('<div>').attr({id:"modal-alert"}).addClass('modal fade').append(
        $('<div>').addClass('modal-dialog').append(
          $('<div>').addClass('modal-content').append(
            $('<div>').addClass('modal-header').append(
              $('<button>').addClass('close').attr({"data-dismiss": "modal"}).append( $('<i>').addClass('fa fa-times') ), // close button in title bar
              $('<h4>').addClass('modal-title').text(data.title)                                                          // alert title
            ),
            $('<div>').addClass('modal-body').append(appx),
            $('<div>').addClass('modal-footer').append(
              $('<button>').addClass('btn btn-default').attr({"data-dismiss": "modal"}).text('Close')                     // close button in the alert bottom
            )
          )
        )
      )
    );
    $('#modal-alert').modal();
  };

  return NS;

} (app || {}));

(function( $ ) {

  $.fn.submit_json = function() {
    var form = $(this);
    // check is form already sent
    if (form.prop('active')) return;
    // protect from multiple submitions
    form.prop('active', true);
    // collect data from form elements on page
    var id = form.attr('id');
    var url = form.attr('action');
    if (typeof(id)!=="undefined" && typeof(url)!=="undefined")
      $.ajax({
        type: "POST",
        url: url,
        dataType: "json",
        data: $('[data-form~="'+id+'"]').form_json(),
        contentType: 'application/json',
        beforeSend: function(xhr, data) {
          $('[data-submit~="'+id+'"]').map(function() {
            $(this).addClass('disabled');
          });
          form.prop('active', false);
          $('.has-error').removeClass('has-error');
        },
        success: function(data, status, xhr) {
          $('[data-submit~="'+id+'"]').map(function() {
            $(this).removeClass('disabled');
          });
          form.prop('active', false);
          if (data.success) {
            if (data.callback) {
              form.trigger('callback', data.callback);
            }
            if (data.redirect) {
              app.redirect(data.redirect);
            }
          }
          else {
            console.log(data);
            if (typeof(data.fields)!=="undefined") {
              data.fields.map(function(el){
                $('[data-form="'+id+'"][name="'+el+'"]').closest('div.form-group').addClass('has-error');
              });
            }
            if (typeof(data.errors)!=="undefined") {
              data = $.extend({title: "Errors found", comment: "Check, correct and resubmit form"}, data);
              var errlist = $('<ul class="text-danger">');
              data.errors.map(function(el) {
                errlist.append($('<li>').text(el));
              });
              app.alert({"title": data.title, "html": $('<div>').append($('<p>').text(data.comment), errlist).html()});
            }
          }
        },
        error: function(xhr, status, error) {
          $('[data-submit~="'+id+'"]').map(function() {
            $(this).removeClass('disabled');
          });
          form.prop('active', false);
          app.alert({"title": "Error", "text": error});
        }
      });
  };

  $.fn.form_json = function() {
    var data = {};
    this.each(function(){
      var el = $(this);
      var name = el.attr('name');
      var value = el.val();
      var type = el.prop('type');
      var checked = el.prop('checked');
      // skip not checked checkboxes and radiobuttons
      if ((type==='radio' || type==='checkbox') && !checked) return;
      if (data[name]) {
        if (typeof(data[name])==='string') {
          data[name]=[ data[name] ];
        }
        data[name].push(value);
      }
      else {
        data[name] = value;
      }
    });
    data = $.extend({}, data);
    return JSON.stringify(data);
  }

  // form submition via button press
  $('button[data-submit]').on('click', function () {
    if (!$(this).hasClass('disabled')) {
      var form = $(this).attr('data-submit');
      $('#'+form).submit_json();
    }
  });

  // process <Enter> press in inputs to submit form
  $('input[data-form]').keypress(function(e) {
    if (e.which==13) {
      var form = $(e.target).attr('data-form');
      $('#'+form).submit_json();
    }
  });

  // init tooltips
  $('[data-toggle="tooltip"]').tooltip();

  // clickable table rows
  $('.clickable-row').click(function() { window.location = $(this).data("href"); });

  // links with confirmation
  $('.js-confirm').on('click', function() {
    var msg = 'Are you sure?';
    if ($(this).attr('data-confirm-text')) {
      msg = $(this).attr('data-confirm-text')
    }
    return confirm(msg);
  })

  // select2 web-components
  $('.js-select2').select2({
		theme: "classic"
	});
  $('.js-select2-with-description').select2({
		theme: "classic",
    templateResult: function (op) {
      if (typeof(op.element)!=="undefined") {
        var el = $(op.element);
        if (el.attr('data-description')) {
          return $(
            '<span>'+op.text+'</span><br>'+
            '<span class="small">'+el.attr('data-description')+'</span>'
          );
        }
      }
      return op.text;
    }
  });
}( jQuery ));
