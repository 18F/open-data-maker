class CategoryDrop < Liquid::Drop
  def initialize(category)
    @category = category
  end

  def id
    @category.id
  end

  def name
    @category.name
  end

  def description
    @category.description
  end

  def fields
    @category.fields
  end
end