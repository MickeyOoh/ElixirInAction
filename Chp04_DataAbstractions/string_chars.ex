defimpl String.Chars, for: Integer do
  def to_string(term) do
    Integer.to_string(term)
  end

end
