require 'csv'
require 'liquid'

class ListGenerator
  #PathNode    = Struct.new(:id, :name, :parent, :children)
  PathNode    = Struct.new(:name, :parent, :children)
  ContentNode = Struct.new(:label, :control, :values, :parent)

  def self.load(data:)
    case data
    when /\.csv$/
      @data = CSV.read(data, headers: :first_line)
    else
      @data = CSV.parse(data, headers: :first_line)
    end

    return @data
  end

  def self.create(dataset:)
    @categories = []
    @content = []

    # Isoloate just the headers
    @path_levels = self.get_headers(dataset: dataset, regular_expression: 'L\d+')

    # Add enough interior arrays for the number of category levels
    @path_levels.count.times do |level|
      @categories.push( [] )
    end

    # For each row of the dataset
    dataset.each do |row|
      # For each level of the headers
      @path_levels.each do |level|
        @this_level_index = @path_levels.index(level)
        @parent_level = @path_levels[@this_level_index - 1]
        @child_level = @path_levels[@this_level_index + 1]

        @name = row[level]
        @children = []

        # Get the children of this node
        @slice = dataset.select do |r|
          r[level] == @name
        end

        # select the children's name
        @slice.each do |r|
          if @child_level != nil
            @child_name = r[@child_level]
            if @child_name != nil
              @children.push(@child_name)
            end
          end
        end

        # Create a node
        @category = PathNode.new(
          row[level],
          row[@parent_level],
          @children.uniq
        )

        # Assuming there is a name for this category item
        if !@category.name.nil? 
          # and there isn't already a copy of this category item present
          if !@categories[@this_level_index].include?(@category)
            # add the new node
            @categories[@this_level_index].push(@category)
          end
        end
      end

      # Create the content nodules
      @content_label = row["Content"]
      @content_control = row["Control"]
      @content_values = row["Values"]
      @content_parent = {
        label: nil,
        level: nil
      }

      @path_levels.each do |level|
        @current_level_content = row[level]
        if @current_level_content != nil
          @content_parent[:label] = @current_level_content
          @content_parent[:level] = @path_levels.find_index(level) + 1
        end
      end

      # Add the content node to the @content array
      @nodule = ContentNode.new( @content_label, 
                                 @content_control, 
                                 @content_values, 
                                 @content_parent)
      @content.push(@nodule)
    end

    return {
      categories: @categories,
      content: @content
    }
  end

  def self.render(model:, template:)
    @formatted = {
      categories: [],
      content: []
    }

    @template = Liquid::Template.parse(
      File.read("views/#{template}.liquid")
    )

    @h_obj = []
    # Add an interior array in each h_obj
    # object for each level of the hierarchy
    model[:categories].each do |hierarchy_level|
      @h_obj.push([])
      hierarchy_level.each do |category|
        @h_obj.last.push(
          {
            'name' => category.name,
            'parent' => category.parent,
            'children' => category.children
          }
        )
      end
    end

    @h_obj.each do |h|
      @formatted[:categories].push(
        @template.render(
          'hierarchy_levels' => @h_obj[@h_obj.index(h)]
        )
      )
    end

    model[:content].each do |item|
      @formatted[:content].push(
        @template.render(
          'parent_name'     => item.parent[:label],
          'parent_level'    => item.parent[:level],
          'control_type'    => item.control,
          'content_label'   => item.label,
          'values'          => item.values
        )
      )
    end

    return {
      path: @formatted[:categories],
      content: @formatted[:content]
    }
  end

  # Private methods. These only need to be used to create users
  class << self
    def get_headers(dataset:, regular_expression:)
      @headers = []

      dataset.headers.each do |header|
        if /#{regular_expression}/.match(header) 
          @headers.push(header)
        end
      end

      return @headers
    end

    def get_parent_index(current_index:)
      current_index > 0 ? current_index - 1 : nil
    end

    def get_child_level(levels_of_hierarchy:, current_index:)
      if current_index < (levels_of_hierarchy.length - 1)
        levels_of_hierarchy[current_index - 1]
      else
        nil
      end
    end
  end
end
