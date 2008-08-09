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

module LightningTest

  # Create shorthand methods for assertions, etc.
  # responds => assert_response
  # redirects_to => assert_redirected_to
  # contains => outputs
  # outputs_rjs => select_rjs
  module ShorthandAssertions

    def self.included(kls)
      kls.send :alias_method, :responds, :assert_response
      kls.send :alias_method, :redirects_to, :assert_redirected_to
      kls.send :alias_method, :contains, :outputs
      kls.send :alias_method, :outputs_rjs, :assert_select_rjs
    end

    # pass in a Regex to check against the body
    # or use it excactly like assert_select
    def outputs *args, &blk
      if args.first.is_a? Regexp
        assert_match args.first, @response.body
      else
        assert_select *args, &blk
      end
    end

    # make sure key exists in session
    # checks is either a singular value in the case of
    #   stores :user_id, 1
    # or a hash of {:method_to_call_on_stored_object => expected_value}
    #   stores :user, :id => 1, :name => 'tester
    def stores key, checks=nil
      assert session[key]
      value_check(session[key], value)
    end

    # make sure a flash exists
    # without any arguments, will check for any flash
    # with level (like :notice) it will check that key exists (any value)
    # with value (Regexp or string), will compare to actual value
    def flashes level=nil, value=nil
      if level.nil?
        assert !flash.values.compact.empty?
      else
        assert( (flash[level] and !flash.level.empty?) )
        if value
          if value.is_a?(Regexp)
            assert value.match(flash[level])
          else
            assert_equal value, flash[level]
          end
        end
      end
    end

    # make sure the named variable is sent to the template
    # checks is either a singular value in the case of
    #   assigns :user_id, 1
    # or a hash of {:method_to_call_on_assigned_object => expected_value}
    #   assigns :user, :id => 1, :name => 'tester
    def assigns var, checks=nil
      var = @response.template.assigns[var.to_s]
      assert var
      value_check(var, checks)
    end

    private
    def value_check value, checks
      return unless checks
      if checks.is_a?(Hash)
        checks.each{|k,v| assert_equal v, var.send(k)}
      else
        assert_equal checks, var
      end
    end

  end
end
