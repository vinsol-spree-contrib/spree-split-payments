Spree-split-payments
=========================
This extension lets you provide the feature for the store to allow user to club payment methods to process the payment for the order.

Easily configurable from the admin end where admin can select which payment methods should be allowed for clubbing and their priorities which can be used while creating payments and displaying the options to the user.

Installation
------------

Add spree-split-payments to your Gemfile:

```ruby
gem 'spree-split-payments'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree-split-payments:install
```

Integration
-----------
The extension needs a way to find out the maximum amount that can be made via a payment method. To do so it sends a message to the user object as :

```ruby
#{payment_method.class.name.demodulize.underscore}_for_partial_payments
```

like for PaymentMethod : Spree::PaymentMethod::LoyaltyPoints it calls for
loyalty_points_for_partial_payments on current_user

so you can either 
1)alias an exising method like

```ruby
#models/spree/user_decorator.rb
alias_method :loyalty_points_for_partial_payments, :loyalty_points_equivalent_currency
```
where loyalty_points_equivalent_currency is the method provided by Spree::PaymentMethod::LoyaltyPoints extension.

2)define a method under user class
  for example for Spree::PaymentMethod::LoyaltyPoints

```ruby
#models/spree/user_decorator.rb
Spree::User.class_eval do
....

def loyalty_points_for_partial_payments
  #logic goes here
end

....
```

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree-split-payments/factories'
```

Copyright (c) 2014 [name of extension creator], released under the New BSD License
