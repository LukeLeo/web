/*global jQuery,cyberDojo*/

var cyberDojo = (function(cd, $) {
  "use strict";

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

  return cd;

})(cyberDojo || {}, jQuery);

// Used on the setup pages.
// Major refers to the lhs-column choices, eg languages
// Minor refers to the rhs-column choices, eg test-frameworks