0.1.2
-----
* Exposed the json data (input) string as request, i.e.:
    pp = Paypkg.new status
    pp.some_call(...)
  r = pp.request # <-- this is the json string that was passed to PayPal.
  NOTE: it only has the request AFTER you call call_paypkg because
  paypkg puts the string into it when it's called so you can see what
  your input looked like after it was prepared to send to PayPal.
  Like json and hash, request is an array.
* Added retrieve_payment_resource(payment_id) for looking up payments.
* Updated paypkg_test.rb to test the new method above.
* Added a README.html because a text file just doesn't cut it.

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
