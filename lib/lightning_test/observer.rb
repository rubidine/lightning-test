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
  class Observer

    attr_reader :passed
    attr_reader :passing_model

    def initialize callback, attributes
      @callback = "after_#{callback}"
      @attributes = attributes
      @passed = false
    end

    def update message, object
      if message.to_s == @callback.to_s
        if @passed = check_object_against_attributes(object)
          @passing_model = object
        end
      end
    end

    def passed?
      @passed
    end

    private
    def check_object_against_attributes(obj)
      return true if @attributes.nil? or @attributes.empty?
      @attributes.keys.all?{|x| @attributes[x] === obj.attributes[x.to_s]}
    end

  end
end
