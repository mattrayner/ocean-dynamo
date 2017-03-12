$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ocean-dynamo/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ocean-dynamo"
  s.version     = OceanDynamo::VERSION
  s.authors     = ["Peter Bengtson"]
  s.email       = ["peter@peterbengtson.com"]
  s.homepage    = "https://github.com/OceanDev/ocean-dynamo"
  s.summary     = "OceanDynamo is a massively scalable Amazon DynamoDB near drop-in replacement for 
ActiveRecord."
  s.description = 
"== OceanDynamo

As one important use case for OceanDynamo is to facilitate the conversion of SQL
databases to no-SQL DynamoDB databases, it is important that the syntax and semantics
of OceanDynamo are as close as possible to those of ActiveRecord. This includes
callbacks, exceptions and method chaining semantics. OceanDynamo follows this pattern 
closely and is of course based on ActiveModel.


The attribute and persistence layer of OceanDynamo is modeled on that of ActiveRecord:
there's +save+, +save!+, +create+, +update+, +update!+, +update_attributes+, +find_each+,
+destroy_all+, +delete_all+, +read_attribute+, +write_attribute+ and all the other 
methods you're used to. The design goal is always to implement as much of the ActiveRecord
interface as possible, without compromising scalability. This makes the task of switching 
from SQL to no-SQL much easier.


OceanDynamo uses only primary indices to retrieve related table items and collections, 
which means it will scale without limits.


OceanDynamo is fully usable as an ActiveModel and can be used by Rails
controllers. Thanks to its structural similarity to ActiveRecord, OceanDynamo works 
with FactoryGirl.


See also Ocean, a Rails framework for creating highly scalable SOAs in the cloud, in which
ocean-dynamo is used as a central component: http://wiki.oceanframework.net
"

  s.required_ruby_version = '>= 2.0.0'
  s.license = 'Apache-2.0'

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.rdoc"]

  
  s.add_dependency "aws-sdk", '~> 2' 
  s.add_dependency "activemodel", ">= 4"
  s.add_dependency "activesupport", ">= 4"

  s.add_development_dependency "rails", "~> 5"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "factory_girl_rails", "~> 4"
  s.add_development_dependency "ocean-rails"
end
