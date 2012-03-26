Overview
--------

Padrino Cookies is a plugin for the [Padrino](https://github.com/padrino/padrino-framework) web framework which adds support for [Rails](https://github.com/rails/rails) like cookie manipulation.

Setup & Installation
--------------------

Include it in your project's `Gemfile`:

``` ruby
gem 'padrino-cookies'
```

Modify your `app/app.rb` file to register the plugin:

``` ruby
class ExampleApplication < Padrino::Application
  register Padrino::Cookies
end
```

Dependencies
------------

* [Padrino-Core](https://github.com/padrino/padrino-framework)
* [Ruby](http://www.ruby-lang.org/en) >= 1.9.2

TODO
-----

* Additional documentation

Copyright
---------

Copyright &copy; 2012 Benjamin Bloch (Cirex). See LICENSE for details.