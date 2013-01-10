require 'helper'

module Thredis
  class TestDatabase < Thredis::TestCase
    attr_reader :db

    def setup
      @db = Thredis::Database.new(THREDIS_CONNECT)
      @db.execute "drop table if exists employees"
      @db.execute "drop table if exists items"
      @db.execute "drop table if exists blobs"
      @db.execute "drop table if exists foo"
    end

    def test_segv
      assert_raises(TypeError) { Thredis::Database.new 1 }
    end

    def test_bignum
      num = 4907021672125087844
      db.execute 'CREATE TABLE "employees" ("token" integer(8), "name" varchar(20) NOT NULL)'
      db.execute "INSERT INTO employees(name, token) VALUES('employee-1', ?)", [num]
      rows = db.execute 'select token from employees'
      assert_equal num, rows.first.first
    end

    def test_blob
      @db.execute("CREATE TABLE blobs ( id INTEGER, hash BLOB(10) )")
      str = "\0foo"
      @db.execute("INSERT INTO blobs VALUES (0, ?)", [str])
      assert_equal [[0, str]], @db.execute("SELECT * FROM blobs")
    end

    def test_get_first_row
      assert_equal [1], @db.get_first_row('SELECT 1')
    end

    def test_get_first_row_with_type_translation_and_hash_results
      @db.results_as_hash = true
      assert_equal({0=>1, "1"=>1}, @db.get_first_row('SELECT 1'))
    end

    def test_execute_with_type_translation_and_hash
      @db.results_as_hash = true
      rows = []
      @db.execute('SELECT 1') { |row| rows << row }

      assert_equal({0=>1, "1"=>1}, rows.first)
    end

    # ZZZ
    # def test_encoding
    #   assert @db.encoding, 'database has encoding'
    # end

    def test_new
      db = Thredis::Database.new(THREDIS_CONNECT)
      assert db
    end

    def test_new_yields_self
      thing = nil
      Thredis::Database.new(THREDIS_CONNECT) do |db|
        thing = db
      end
      assert_instance_of(Thredis::Database, thing)
    end

    # ZZZ
    # def test_new_with_options
    #   # determine if Ruby is running on Big Endian platform
    #   utf16 = ([1].pack("I") == [1].pack("N")) ? "UTF-16BE" : "UTF-16LE"

    #   if RUBY_VERSION >= "1.9"
    #     db = Thredis::Database.new(THREDIS_CONNECT.encode(utf16), :utf16 => true)
    #   else
    #     db = Thredis::Database.new(Iconv.conv(utf16, 'UTF-8', THREDIS_CONNECT),
    #                                :utf16 => true)
    #   end
    #   assert db
    # end

    def test_close
      db = Thredis::Database.new(THREDIS_CONNECT)
      db.close
      assert db.closed?
    end

    def test_block_closes_self
      thing = nil
      Thredis::Database.new(THREDIS_CONNECT) do |db|
        thing = db
        assert !thing.closed?
      end
      assert thing.closed?
    end

    def test_prepare
      db = Thredis::Database.new(THREDIS_CONNECT)
      stmt = db.prepare('select "hello world"')
      assert_instance_of(Thredis::Statement, stmt)
    end

    def test_execute_returns_list_of_hash
      db = Thredis::Database.new(THREDIS_CONNECT, :results_as_hash => true)
      db.execute("create table foo ( a integer primary key, b text )")
      db.execute("insert into foo (b) values ('hello')")
      rows = db.execute("select * from foo")
      assert_equal [{0=>1, "a"=>1, "b"=>"hello", 1=>"hello"}], rows
    end

    def test_execute_yields_hash
      db = Thredis::Database.new(THREDIS_CONNECT, :results_as_hash => true)
      db.execute("create table foo ( a integer primary key, b text )")
      db.execute("insert into foo (b) values ('hello')")
      db.execute("select * from foo") do |row|
        assert_equal({0=>1, "a"=>1, "b"=>"hello", 1=>"hello"}, row)
      end
    end

    def test_table_info
      db = Thredis::Database.new(THREDIS_CONNECT, :results_as_hash => true)
      db.execute("create table foo ( a integer primary key, b text )")
      info = [{
        "name"       => "a",
        "pk"         => 1,
        "notnull"    => 0,
        "type"       => "integer",
        "dflt_value" => nil,
        "cid"        => 0
      },
      {
        "name"       => "b",
        "pk"         => 0,
        "notnull"    => 0,
        "type"       => "text",
        "dflt_value" => nil,
        "cid"        => 1
      }]
      assert_equal info, db.table_info('foo')
    end

    #ZZZ
    # def test_last_insert_row_id_closed
    #   @db.close
    #   assert_raise(Thredis::Exception) do
    #     @db.last_insert_row_id
    #   end
    # end

    # def test_define_function
    #   called_with = nil
    #   @db.define_function("hello") do |value|
    #     called_with = value
    #   end
    #   @db.execute("select hello(10)")
    #   assert_equal 10, called_with
    # end

    # def test_call_func_arg_type
    #   called_with = nil
    #   @db.define_function("hello") do |b, c, d|
    #     called_with = [b, c, d]
    #     nil
    #   end
    #   @db.execute("select hello(2.2, 'foo', NULL)")
    #   assert_equal [2.2, 'foo', nil], called_with
    # end

    # def test_define_varargs
    #   called_with = nil
    #   @db.define_function("hello") do |*args|
    #     called_with = args
    #     nil
    #   end
    #   @db.execute("select hello(2.2, 'foo', NULL)")
    #   assert_equal [2.2, 'foo', nil], called_with
    # end

    # def test_function_return
    #   @db.define_function("hello") { |a| 10 }
    #   assert_equal [10], @db.execute("select hello('world')").first
    # end

    # def test_function_return_types
    #   [10, 2.2, nil, "foo"].each do |thing|
    #     @db.define_function("hello") { |a| thing }
    #     assert_equal [thing], @db.execute("select hello('world')").first
    #   end
    # end

    # def test_define_function_closed
    #   @db.close
    #   assert_raise(Thredis::Exception) do
    #     @db.define_function('foo') {  }
    #   end
    # end

    # def test_inerrupt_closed
    #   @db.close
    #   assert_raise(Thredis::Exception) do
    #     @db.interrupt
    #   end
    # end

    # def test_define_aggregate
    #   @db.execute "create table foo ( a integer primary key, b text )"
    #   @db.execute "insert into foo ( b ) values ( 'foo' )"
    #   @db.execute "insert into foo ( b ) values ( 'bar' )"
    #   @db.execute "insert into foo ( b ) values ( 'baz' )"

    #   acc = Class.new {
    #     attr_reader :sum
    #     alias :finalize :sum
    #     def initialize
    #       @sum = 0
    #     end

    #     def step a
    #       @sum += a
    #     end
    #   }.new

    #   @db.define_aggregator("accumulate", acc)
    #   value = @db.get_first_value( "select accumulate(a) from foo" )
    #   assert_equal 6, value
    # end

    def test_execute_with_empty_bind_params
      assert_equal [['foo']], @db.execute("select 'foo'", [])
    end

  end
end
