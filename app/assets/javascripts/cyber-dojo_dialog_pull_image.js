/*global jQuery,cyberDojo*/

var cyberDojo = (function(cd, $) {
  "use strict";

  var makePullFailedDialog = function() {
    var html = '' +
      'Sorry... pulling the docker image to the server failed.<br/>' +
      'Please check the logs<br/>';
    return $('<div>')
      .html(html)
      .dialog({
        title: cd.dialogTitle('setup a new practice session'),
        closeOnEscape: true,
        close: function() { $(this).remove(); },
        autoOpen: false,
        buttons: {
          'close': function() {
            $(this).remove();
          }
        },
        width: 550,
        height: 210,
        modal: true,
      });
  };

  cd.dialog_pullImageThen = function(route, params, fn) {
    var pullDialog = makePullDialog();
    var pullOverlay = $('<div id="pull-overlay"></div>');
    var pullSpinner = $('#pull-spinner');
    pullDialog.dialog('open');
    pullOverlay.insertAfter($('body'));
    pullSpinner.show();
    $.getJSON(route, params, function(pull) {
      pullSpinner.hide();
      pullOverlay.remove();
      pullDialog.dialog('close');
      if (pull.succeeded) {
        fn();
      } else {
        makePullFailedDialog().dialog('open');
      }
    });
  };

  cd.chosenMajorMinor = function() {
    return {
      major: cd.chosenMajor(),
      minor: cd.chosenMinor()
    };
  };

  cd.chosenMajor = function() {
    return $('[id^=major_][class~=selected]').data('major');
  };

  cd.chosenMinor = function() {
    return $('[id^=minor_][class~=selected]').data('minor');
  };

  var makePullDialog = function() {
    var html = '' +
      'The appropriate runtime environment is being set.<br/>' +
      'It may take a minute or two.<br/>' +
      'Please wait...';
    return $('<div>')
      .html(html)
      .dialog({
        title: cd.dialogTitle('setup a new practice session'),
        closeOnEscape: true,
        close: function() { $(this).remove(); },
        autoOpen: false,
        width: 550,
        height: 185,
        modal: true,
      });
  };

  return cd;
})(cyberDojo || {}, jQuery);
