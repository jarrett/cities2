class Text
  def hide
  end
  
  def initialize(x, y, text, options = {})
    @x = x
    @y = y
    @text = text
    @size = options[:size] || 12
  end
  
  def show
  end
  
  def size=(new_size)
  end
  
  def text=(new_text)
  end
  
  def x=(new_x)
  end
  
  def y=(new_y)
  end
end