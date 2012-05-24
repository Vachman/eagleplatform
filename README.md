Eagleplatform
=============

Eagleplatform public API library

Installation:
-  gem install eagleplatform
  
Use:
-  require 'eagleplatform'
-  Eagleplatform.setup('YOUR_ACCOUNT','YOUR_TOKEN')  

-  Eagleplatform::Translation.list.each { |t| puts t.starts._at }  

-  Eagleplatform::Record.update(id: 12, name: 'Hello World')  

-  Eagleplatform::Record.delete(12)   

-  r = Eagleplatform::Record.find(1234)  
-  r.description = 'Foo'
-  r.update