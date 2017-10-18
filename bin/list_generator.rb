require 'csv'
require 'liquid'

class ListGenerator
  PathNode    = Struct.new(:id, :name, :parent, :children)
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

  def self.create(data:)
    @categories = []
    @content = []

    # Isoloate just the headers
    @path_levels = get_headers(dataset: data, regular_expression: 'L\d+')

    # Add enough interior arrays for the number of category levels
    @path_levels.count.times do |level|
      @categories.push( [] )
    end


    #######################################################################
    # Build the nodules for the list module
    #######################################################################
    
    # For each line of the dataset
    data.each do |row|
      # Take a look at the path for the content
      @path_levels.each do |path_level|
        @this_category = row[path_level]
        @this_index = @path_levels.find_index(path_level)
        @parent = ''
        @children = []

        # Get the id of this node
        @identifier = row["ID"]

        # Get the name of this node
        @name = row[path_level]


        # Get the index of the parent item (it is nil if the current item 
        # is a root level item)...
        @parent_index = get_parent_index(current_index: @this_index)
        
        # ... and the index of the child items
        @child_level = get_child_level(
          levels_of_hierarchy: @path_levels,
          current_index: @this_index
        )

        # Get the name of the parent item (it is an empth string if the 
        # current item is root level)
        if !@parent_index.nil? 
          @parent = row[@path_levels[@parent_index]]
        else
          @parent = nil
        end

        # Get the children of this node
        @slice = data.select do |r|
          r[path_level] == @name 
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

        # Test to see if the node is already in the array at this hierarchy level
        @nodule_exists_at_this_level = @categories[@this_index].find{ |r| r.name }

        # Add the path node to the @categories array
        @nodule = PathNode.new( @identifier, @name, @parent, @children.uniq )

        if @name != nil 
          @categories[@this_index].push(
            @nodule
          )
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
      @nodule = ContentNode.new( @content_label, @content_control, @content_values, @content_parent)
      @content.push(@nodule)
    end

    return {
      categories: @categories.uniq,
      content: @content.uniq
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

    model[:categories].each do |hierarchy_level|
      hierarchy_level.each do |category|
        @formatted[:categories].push(
          @template.render(
            'hierarchy_levels'=> hierarchy_level,
            'category_name'   => category.name,
            'parent_category' => category.parent,
            'children'        => category.children
          )
        )
      end
    end

    model[:content].each do |item|
      @formatted[:content].push(
        @template.render(
          'parent_name'     => item.parent[:label],
          'parent_level'    => item.parent[:level],
          'control_type'    => item.control,
          'values'          => item.values
        )
      )
    end

    return {
      path: @formatted[:categories].uniq,
      content: @formatted[:content]
    }
  end

  # Private methods. These only need to be used to create users
  class << self
    private def get_headers(dataset:, regular_expression:)
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
