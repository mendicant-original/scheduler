
## Usage:
##
# class Foo
#   extend Loadable
#
#   load_lines_of_format :csv do |foo, input_row, opts|
#    foo.append_row(input_row)
#    foo
#   end
#   
#   load_files_of_format :yaml do |input, opts|
#    yaml = YAML.load(input)
#    new(yaml, opts)
#   end
#   
# end
#
# foo = Foo.load(myfile, :yaml)
# foo2 = Foo.load_lines(myfile, :csv)

module Loadable

  def load_from(file, input_type, opts = {})
    delim = opts[:delim] || $/
    if IO === file
      @_parser[input_type].call(io, opts) if @_parser[input_type]
    else
      File.open(file, 'r') do |io| 
        @_parser[input_type].call(io, opts) if @_parser[input_type]
      end
    end
  end
  alias_method :load, :load_from
  
  def load_lines_from(file, input_type, opts = {})
    delim = opts[:delim] || $/
    instance = new
    parser = lambda {|io|
                io.each_line(delim) do |line|
                  @_parser[input_type].call(instance, line, opts) if @_parser[input_type]
                end
             }
    if IO === file
      parser.call(file)
    else
      File.open(file, 'r') {|io| parser.call(io)}
    end
  end
  alias_method :load_lines, :load_lines_from

  def load_files_of_format(input_type, &blk)
    @_parser ||= {}
    @_parser[input_type] = blk
  end

  def load_lines_of_format(input_type, &blk)
    load_files_of_format(input_type, &blk)
  end
  
end
