# https://raw.githubusercontent.com/splattael/minitest-around/master/LICENSE
=begin
Copyright (c) 2012 Peter Suschlik

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=end

# https://raw.githubusercontent.com/splattael/minitest-around/master/lib/minitest/around/version.rb
module Minitest
  module Around
    VERSION = '0.2.0'
  end
end

# https://raw.githubusercontent.com/splattael/minitest-around/master/lib/minitest/around/unit.rb
# HACK removed requires
Minitest::Test.class_eval do
  alias_method :run_without_around, :run
  def run(*args)
    if defined?(around)
      around { run_without_around(*args) }
    else
      run_without_around(*args)
    end
    self
  end
end

# https://raw.githubusercontent.com/splattael/minitest-around/master/lib/minitest/around/spec.rb
# HACK removed requires
Minitest::Spec::DSL.class_eval do
  # - resume to call first part
  # - execute test
  # - resume fiber to execute last part
  def around(&block)
    fib = nil
    before do
      fib = Fiber.new do |context, resume|
        begin
          context.instance_exec(resume, &block)
        rescue Object
          fib = :failed
          raise
        end
      end
      fib.resume(self, lambda { Fiber.yield })
    end
    after  { fib.resume unless fib == :failed }
  end

  # Minitest does not support multiple before/after blocks
  def before(type=nil, &block)
    include Module.new { define_method(:setup) { super(); instance_exec(&block) } }
  end

  def after(type=nil, &block)
    include Module.new { define_method(:teardown) { instance_exec(&block); super() } }
  end
end
