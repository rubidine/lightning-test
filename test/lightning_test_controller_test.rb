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

class ErrorForTest < StandardError ; end
class LightningTestController < ActionController::Base
  def index
    render :text => 'oh hai', :status => 404
  end
end

class LightningTestControllerTest < ActionController::TestCase

  # don't filter out lightning test libries from backtrace
  def filter_backtrace backtrace, prefix=nil
    filter_backtrace_without_lightning_test(backtrace, prefix)
  end

  def test_process_calls_block
    assert_raise(ErrorForTest) do
      process(:index) do
        raise ErrorForTest, 'called block'
      end
    end
  end

  def test_http_methods_call_block
    [:get, :put, :post, :head, :delete].each do |meth|
      assert_raise(ErrorForTest) do
        send(meth, :index) do
          raise ErrorForTest, 'called block'
        end
      end
    end
  end

  def test_shorthand
    get(:index) do
      responds 404
      outputs /hai/
    end
  end

end
