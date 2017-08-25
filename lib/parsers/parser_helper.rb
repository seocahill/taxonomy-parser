module ParserHelper

  def snake_case(str)
    return str.downcase if str.match(/\A[A-Z]+\z/)
    str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
    gsub(/([a-z])([A-Z])/, '\1_\2').
    downcase
  end
end