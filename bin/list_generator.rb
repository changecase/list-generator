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
    @path_levels = []
    @categories = []
    @content = []

    # Isoloate just the headers
    data.headers.each do |h|
      if /L\d+/.match(h) then @path_levels.push(h) end
    end

    # Add enough interior arrays for the number of category levels
    @path_levels.count.times do |level|
      @categories.push( [] )
    end


    #######################################################################
    # Build the nodules for the list module
    #######################################################################
    
    # For each line of the dataset
    data.each do |row|
      @path = []
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


        # Get the index of the parent item (it is nil if the current item is a root level item)...
        if @this_index > 0 
          @parent_index = @this_index - 1
        else
          @parent_index = nil 
        end
        
        # ... and the index of the child items
        if @this_index < @path_levels.length - 1
          @child_index = @this_index + 1
        else
          @child_index = nil
        end

        if @child_index != nil
          @child_level = @path_levels[@child_index]
        else
          @child_level = nil
        end

        # Get the name of the parent item (it is an empth string if the current item is root level)
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
        @nodules_already_in_this_level_of_category_array = @categories[@this_index].find{ |r| r.name }
        #@nodules_with_this_name = @categories[@this_index].find{ |r| r.name }
        @nodule_exists_already = defined?(@nodules_with_this_name.name) ? TRUE : FALSE
        pry

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

    model[:categories].each do |level|
      puts "#{level}\n\n"
      level.each do |category|
        @formatted[:categories].push(
          @template.render(
            'hierarchy_levels'=> category,
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
end