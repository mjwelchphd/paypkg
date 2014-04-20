0.1.1
-----
* Added PaypkgResponse, a class that converts a hash equivilent of the json output to an object.
  This will make it more compatible with existing code based on ActiveRecord.
* Added more documentation. See the README.md file.
* Split out all the PayPal functions into individual files so that new functions can be added
  without risking damaging anything. This also makes it easier to add new functions to the gem.
* Added a PaypkgTestController and a paypkg_test views folder that can be used for testing,
  and seeing how to use the package.

0.1.0
-----
* Created initial Pay Package gem and uploaded it to rubygems.org. There is no documentation yet.
