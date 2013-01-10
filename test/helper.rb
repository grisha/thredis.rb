require 'thredis'
require 'test/unit'

unless RUBY_VERSION >= "1.9"
  require 'iconv'
end

module Thredis
  THREDIS_CONNECT = {:url => 'redis://localhost:6379/0'}
  class TestCase < Test::Unit::TestCase
    unless RUBY_VERSION >= '1.9'
      undef :default_test
    end
  end
end
