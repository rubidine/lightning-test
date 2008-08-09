# Copyright (c) 2008 Todd Willey <todd@rubidine.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'test', 'test_helper')

class ErrorForTesting < StandardError ; end

class SampleModel < ActiveRecord::Base
  # dont do any default active record observers from environment / initializers
  observers = []
  def self.observers= *ob
    # nothing
  end

  # hide the table specifics, we don't really want to use a DB
  @columns = [
    ActiveRecord::ConnectionAdapters::Column.new('name', nil)
  ]
end

class LightningTestTest < Test::Unit::TestCase

  # don't filter out lightning test libries from backtrace
  def filter_backtrace backtrace, prefix=nil
    filter_backtrace_without_lightning_test(backtrace, prefix)
  end

  def peers
    SampleModel.instance_variable_get(:@observer_peers)
  end

  def test_model_gets_observer
    orig_count = (peers || []).length
    creates(SampleModel) do

      nc = peers.length
      assert_equal orig_count + 1, nc

      # fake out the passage of the creates(...) call
      o = peers.last
      o.instance_variable_set(:@passed, true)
    end

    # make sure it removes it as well
    assert_equal orig_count, peers.length
  end

  def test_calls_observer
    creates(SampleModel) do
      o = peers.last
      class << o
        def update *args
          raise ErrorForTesting, "Called Update"
        end
      end

      # do what active record does, but we're not really saving to DB
      sm = SampleModel.new
      assert_raise(ErrorForTesting) do
        sm.send :callback, :after_save
      end

      # fake out the passage of the creates(...) call
      o.instance_variable_set(:@passed, true)
    end
  end

  def test_nested_actions
    orig_count = (peers || []).length
    creates(SampleModel) {
    updates(SampleModel) {
      assert_equal orig_count + 2, peers.length

      # pass this implicit test
      peers.each{|x| x.instance_variable_set :@passed, true }
    } }
  end

  def test_uses_correct_message
    creates(SampleModel) do
      sm = SampleModel.new
      sm.send :callback, :after_update
      assert !peers.last.passed?

      sm.send :callback, :after_create
      assert peers.last.passed?
    end
  end

  def test_creates_find_method
    assert !SampleModel.public_instance_methods.include?('after_find')
    finds(SampleModel) do
      assert SampleModel.public_instance_methods.include?('after_find'), SampleModel.public_instance_methods.sort.inspect

      # fake pass this finds(){} test
      peers.last.instance_variable_set(:@passed, true)
    end
  end

  def test_checks_attributes
    creates(SampleModel, :name => 'asdf') do
      sm = SampleModel.new :name => 'fdsa'
      sm.send :callback, :after_create
      assert !peers.last.passed?

      sm = SampleModel.new :name => 'asdf'
      sm.send :callback, :after_create
      assert peers.last.passed?
    end
  end

end
