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

require 'test_help'
require 'lightning_test/observer'

# Lightning Test
module LightningTest

  # Generate all the observer methods from the list of callbacks
  # in ActiveRecord::Callbacks.  Will not generate for validation_*.
  # The method names will be pluralized actions, like finds, creates, updates,
  # ...
  def self.included(kls)

    # 1 - build the AR observer callbacks
    cb = ActiveRecord::Callbacks::CALLBACKS.map do |x|
           x.gsub(/^((before)|(after))_/, '')
         end
    cb.uniq!
    cb.reject!{|x| x =~ /^validation/}

    cb.each do |c|

      # Use *attributes / attributes = attributes.first
      # so that the second argument isn't required
      kls.send(:define_method, c.pluralize) do |model, *attributes, &blk|
        attributes = attributes.first
        rv = with_observer(c, model, attributes, &blk)
        assert rv, meaningful_error_message(c, model, attributes)
      end
    end

    # 2 - remove this file from the backtrace
    unless kls.public_instance_methods.include?(
             'filter_backtrace_without_lightning_test'
           )
      kls.send :alias_method,
               :filter_backtrace_without_lightning_test,
               :filter_backtrace

      kls.send :alias_method,
               :filter_backtrace,
               :filter_backtrace_with_lightning_test
    end

    # 3 - Descriptive process() blocks for controller tests
    kls.send :alias_method,
             :process_without_lightning_test_block,
             :process

    kls.send :alias_method,
             :process,
             :process_with_lightning_test_block

    [:get, :post, :put, :head, :delete].each do |meth|
      kls.send(:define_method, meth) do |action, *other_args, &blk|
        parameters, session, flash = *other_args
        @request.env['REQUEST_METHOD'] = meth.to_s.upcase if @request
        process action, parameters, session, flash, &blk
      end
    end
  end

  # Get the last model hit by the most recent callback wrapper
  #
  # x = nil
  # creates(MyModel) { x = MyModel.create(:name => 'test') }
  # assert_equal x, last_model #=> true
  #
  def last_model
    @last_observer ? @last_observer.passing_model : nil
  end

  private

  # called from the callback-generated methods to put a new
  # observer in the model to report when something has changed.
  # See LightningTest::Observer.
  #
  # Will put the observer in, call the block passed into the method
  # and then check with the observer that an adequete action occured.
  def with_observer callback, model_class, attributes
    observer = LightningTest::Observer.new(callback, attributes)

    # check for find callback, and create the after_find explicitly
    # since active record won't call it otherwise
    if callback.to_s == 'find'
      model_class.send(:define_method, :after_find){}
    end

    model_class.add_observer(observer)
    yield
    model_class.delete_observer(observer)

    @last_observer = observer

    observer.passed?
  end

  # Filter this library out of the backtrace on a failure.
  #
  # preserve original call
  # then call again to remove this directory from the backtrace
  def filter_backtrace_with_lightning_test backtrace, prefix=nil
    rv = filter_backtrace_without_lightning_test(backtrace, prefix)
    rv = filter_backtrace_without_lightning_test(rv, File.dirname(__FILE__))
    rv
  end

  # For process() when testing controllers.
  #
  # Take a block that gets called after the response is returned,
  # so there is a pretty syntax for assertions on responses.
  def process_with_lightning_test_block action, params=nil, sess=nil, flash=nil
    rv = process_without_lightning_test_block(action, params, sess, flash)
    yield if block_given?
    rv
  end

  # Given a callback, model, and attributes
  # will compose a message that you would be proud
  # to see in your test failures, not just the '<false> is not true'
  def meaningful_error_message callback, model, attributes
    rv = "Unable to #{callback} a #{model.name}"
    if attributes and !attributes.empty?
      rv << " with #{attributes.inspect}"
    end
  end
    
end
