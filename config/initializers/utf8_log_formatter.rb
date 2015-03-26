#
# This formatter replaces invalid UTF-8 byte sequences with "?".
#
class Utf8LogFormatter < Logger::Formatter
  def call(severity, time, progname, msg)
    msg = msg.to_s.encode('utf-8', invalid: :replace, undef: :replace, replace: '?')
    super(severity, time, progname, msg)
  end
end
