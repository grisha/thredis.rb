require 'thredis/errors'
require 'thredis/resultset'

class String
  def to_blob
    Thredis::Blob.new( self )
  end
end

module Thredis
  # A statement represents a prepared-but-unexecuted SQL query. It will rarely
  # (if ever) be instantiated directly by a client, and is most often obtained
  # via the Database#prepare method.
  class Statement
    include Enumerable

    def initialize(connection, sql, prepare_only=true)
      raise ArgumentError, "Connection closed" if connection.closed?
      raise TypeError, "SQL is nil" if sql.nil?
      @connection = connection
      @sql = sql
      @params = []
      @done = nil
      @prepare_only = prepare_only
      query_thredis(prepare_only)
    end

    def step
      query_thredis(false) if @rows.nil? || @prepare_only
      @done = true if @rows && @rows.empty?
      @rows.shift if @rows
    end

    def close
      raise Thredis::Exception, "Statement already closed" if closed? 
      @rows = nil
    end

    def bind_param(index, var)
      @params[index-1] = var.nil? ? ":NULL" : ( var =~ /^:/ ? ':'+var : var )
    end

    # Binds the given variables to the corresponding placeholders in the SQL
    # text.
    #
    # See Database#execute for a description of the valid placeholder
    # syntaxes.
    #
    # Example:
    #
    #   stmt = db.prepare( "select * from table where a=? and b=?" )
    #   stmt.bind_params( 15, "hello" )
    #
    # See also #execute, #bind_param, Statement#bind_param, and
    # Statement#bind_params.
    def bind_params( *bind_vars )
      index = 1
      bind_vars.flatten.each do |var|
        if Hash === var
          var.each { |key, val| bind_param key, val }
        else
          bind_param index, var
          index += 1
        end
      end
    end

    # Execute the statement. This creates a new ResultSet object for the
    # statement's virtual machine. If a block was given, the new ResultSet will
    # be yielded to it; otherwise, the ResultSet will be returned.
    #
    # Any parameters will be bound to the statement using #bind_params.
    #
    # Example:
    #
    #   stmt = db.prepare( "select * from table" )
    #   stmt.execute do |result|
    #     ...
    #   end
    #
    # See also #bind_params, #execute!.
    def execute( *bind_vars )
      reset! if active? || done?

      bind_params(*bind_vars) unless bind_vars.empty?
      @results = ResultSet.new(@connection, self)

      step if 0 == column_count

      yield @results if block_given?
      @results
    end

    # Execute the statement. If no block was given, this returns an array of
    # rows returned by executing the statement. Otherwise, each row will be
    # yielded to the block.
    #
    # Any parameters will be bound to the statement using #bind_params.
    #
    # Example:
    #
    #   stmt = db.prepare( "select * from table" )
    #   stmt.execute! do |row|
    #     ...
    #   end
    #
    # See also #bind_params, #execute.
    def execute!( *bind_vars, &block )
      execute(*bind_vars)
      block_given? ? each(&block) : to_a
    end

    def done?
      !!@done
    end

    def closed?
      !@rows
    end

    # Returns true if the statement is currently active, meaning it has an
    # open result set.
    def active?
      @rows && !@rows.empty?
    end

    def column_count
      @columns.size
    end

    def column_name(i)
      @columns && @columns[i] && @columns[i].first
    end

    def reset!
      @rows = @done = nil
    end

    def each
      loop do
        val = step
        break self if val.nil?
        yield val
      end
    end

    def clear_bindings!
      @params = []
    end

    # Return an array of the column names for this statement. Note that this
    # may execute the statement in order to obtain the metadata; this makes it
    # a (potentially) expensive operation.
    def columns
      must_be_open!
      return @columns.map(&:first)
    end

    # Return an array of the data types for each column in this statement. Note
    # that this may execute the statement in order to obtain the metadata; this
    # makes it a (potentially) expensive operation.
    def types
      must_be_open!
      @columns.map(&:last)
    end

    # Performs a sanity check to ensure that the statement is not
    # closed. If it is, an exception is raised.
    def must_be_open! # :nodoc:
      if closed?
        raise Thredis::Exception, "cannot use a closed statement"
      end
    end

    private
    #ZZZ
    # def convert_type(rows, columns)
    #   rows.each do |row|
    #     for i in 0...row.size
    #       row[i] = Integer(row[i]) if columns[i].last == 'int'
    #     end
    #   end
    #   rows
    # end

    def query_thredis(prepare_only)
      if prepare_only
        @rows = @connection.redis.sqlprepare(@sql)
      else
        @rows = @connection.redis.sql(@sql, *@params)
        @prepare_only = false
      end
      if @rows == 'OK'
        @rows, @columns = [], []
      else
        @columns = @rows.shift
##        @rows = convert_type(@rows, @columns)
      end
    end
  end
end
