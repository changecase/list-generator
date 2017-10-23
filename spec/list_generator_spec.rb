require './bin/list_generator.rb'

describe ListGenerator do

  describe ".load_data" do

    context "given no arguments" do
      it "errors if the files/data are not provided" do
        expect{ListGenerator.load}.to raise_error(ArgumentError)
      end
    end

    context "given data" do
      before(:context) do
        @data = "ID,L1,L2,L3,L4,L5,L6,L7,Content,Control,End Point Needed,Path Needed\n" +
                "2.02.03.02.01.01,All Settings,Features,Media,DAB,TBD,,,TBD,,TBD,,TRUE"
      end

      it "returns an array of objects with the right properties" do
        @list = ListGenerator.load(data: @data)

        expect(@list.first["ID"]).to eq "2.02.03.02.01.01"
        expect(@list.first["L1"]).to eq "All Settings"
        expect(@list.first["L2"]).to eq "Features" 
        expect(@list.first["L3"]).to eq "Media"
        expect(@list.first["L4"]).to eq "DAB"
        expect(@list.first["L5"]).to eq "TBD"
        expect(@list.first["L6"]).to eq nil
        expect(@list.first["L7"]).to eq nil
        expect(@list.first["Content"]).to eq "TBD"
        expect(@list.first["Value"]).to eq nil
        expect(@list.first["Control"]).to eq nil
      end
    end
  end

  describe ".get_headers" do
    before(:context) do
      @file = "ID,L1,L2,L3,L4,L5,L6,L7,Content,Control,Values,End Point Needed,Path Needed\n" +
              "2.02.03.02.01.01,All Settings,Features,Media,DAB,TBD,,,TBD,,TBD,,TRUE\n" +
              "2.02.03.01.03,All Settings,Features,Media,AM-FM-HD Radio,,,,Station List Order,,ABC/123,TRUE,TRUE\n" +
              "3.02,Climate Settings,,,,,,,Auto Front Heater,,On/Off,TRUE,TRUE"
      @data = ListGenerator.load(data: @file)
    end
    context "given the loaded data" do
      it "returns the hiearchy level headers" do
        @headers = ListGenerator.get_headers(dataset: @data, regular_expression: 'L\d+')

        expect(@headers).to eq ["L1","L2","L3","L4","L5","L6","L7"]
      end
    end
  end

  describe ".get_parent_index" do
    context "given the current index" do
      it "returns the index of the parent item" do
        @root_level_item  = ListGenerator.get_parent_index(current_index: 0)
        @item_with_parent = ListGenerator.get_parent_index(current_index: 1)

        expect(@root_level_item).to be_nil
        expect(@item_with_parent).to eq 0
      end
    end
  end

  describe ".get_child_level" do
    context "given an array of the hierarchy levels and the current index" do
      it "returns the index of the child items" do
        @levels = ["L1","L2"]
        @something = ListGenerator.get_child_level(levels_of_hierarchy: @levels, current_index: 0)
      end
    end
  end

  describe ".create" do
    before(:context) do
      @file = "ID,L1,L2,L3,L4,L5,L6,L7,Content,Control,Values,End Point Needed,Path Needed\n" +
              "2.02.03.02.01.01,All Settings,Features,Media,DAB,TBD,,,TBD,,TBD,,TRUE\n" +
              "2.02.03.01.03,All Settings,Features,Media,AM-FM-HD Radio,,,,Station List Order,,ABC/123,TRUE,TRUE\n" +
              "3.02,Climate Settings,,,,,,,Auto Front Heater,,On/Off,TRUE,TRUE"
      @data = ListGenerator.load(data: @file)
      @model = ListGenerator.create(dataset: @data)
    end
    context "given parsed data" do
      it "returns an array that has the same number of first level values as the number of path levels" do
        expect(@model[:categories].length).to eq 7
      end

      it "contains the top level hiearchy levels in the first category" do
        @level_1_categories = @model[:categories][0]
        expect(@level_1_categories[0].name).to eq "All Settings"
        expect(@level_1_categories[1].name).to eq "Climate Settings"
      end

      it "contains the second level hierarchy levels in the second category" do
        @level_2_categories = @model[:categories][1]
        expect(@level_2_categories[0].name).to eq "Features"
        expect(@level_2_categories[1]).to      be_nil
      end

      it "contains the third level hierarchy levels in the third category" do
        @level_3_categories = @model[:categories][2]
        expect(@level_3_categories[0].name).to eq "Media"
        expect(@level_3_categories[1]).to      be_nil
      end

      it "contains the fourth level hierarchy levels in the fourth category" do
        @level_4_categories = @model[:categories][3]
        expect(@level_4_categories[0].name).to eq "DAB"
        expect(@level_4_categories[1].name).to eq "AM-FM-HD Radio"
      end

      it "contains the fifth level hierarchy levels in the fifth category" do
        @level_5_categories = @model[:categories][4]
        expect(@level_5_categories[0].name).to eq "TBD"
        expect(@level_5_categories[1]).to      be_nil
      end

      it "contains the sixth level hierarchy levels in the sixth category" do
        @level_6_categories = @model[:categories][5]
        expect(@level_6_categories[0]).to      be_nil
        expect(@level_6_categories[1]).to      be_nil
      end

      it "contains the seventh level hierarchy levels in the seventh category" do
        @level_7_categories = @model[:categories][6]
        expect(@level_7_categories[0]).to      be_nil
        expect(@level_7_categories[1]).to      be_nil
      end

      it "contains nil for the parent of the top level hierarchy" do
        @level_1_categories = @model[:categories][0]
        expect(@level_1_categories[0].parent).to be_nil
        expect(@level_1_categories[1].parent).to be_nil
      end
    end
  end

#  describe ".create" do
#    context "given data and a format to convert to" do
#      before(:context) do
#        @file = "ID,L1,L2,L3,L4,L5,L6,L7,Content,Control,Values,End Point Needed,Path Needed\n" +
#                "2.02.03.02.01.01,All Settings,Features,Media,DAB,TBD,,,TBD,,TBD,,TRUE\n" +
#                "2.02.03.01.03,All Settings,Features,Media,AM-FM-HD Radio,,,,Station List Order,,ABC/123,TRUE,TRUE\n" +
#                "3.02,Climate Settings,,,,,,,Auto Front Heater,,On/Off,TRUE,TRUE"
#        @data = ListGenerator.load(data: @file)
#        @data_model = ListGenerator.create(data: @data)
#      end
#
#      it "creates an array of categories and their relationships" do
#        @level_1_record_1 = { name: "All Settings",     parent: nil,            children: ["Features"] }
#        @level_2_record_1 = { name: "Features",         parent: "All Settings", children: ["Media"] }
#        @level_3_record_1 = { name: "Media",            parent: "Features",     children: ["DAB", "AM-FM-HD Radio"] }
#        @level_4_record_1 = { name: "DAB",              parent: "Media",        children: ["TBD"] }
#        @level_5_record_1 = { name: "TBD",              parent: "DAB",          children: [] }
#        #@level_1_record_2 = { name: "All Settings",     parent: nil,            children: ["Features"] }
#        #@level_2_record_2 = { name: "Features",         parent: "All Settings", children: ["Media"] }
#        #@level_3_record_2 = { name: "Media",            parent: "Features",     children: ["DAB", "AM-FM-HD Radio"] }
#        @level_4_record_2 = { name: "AM-FM-HD Radio",   parent: "Media",        children: [] }
#        @level_1_record_3 = { name: "Climate Settings", parent: nil,            children: [] }
#
#        expect(@data_model[:categories][0][0].name).to eq @level_1_record_1[:name]
#        expect(@data_model[:categories][1][0].name).to eq @level_2_record_1[:name]
#        expect(@data_model[:categories][2][0].name).to eq @level_3_record_1[:name]
#        expect(@data_model[:categories][3][0].name).to eq @level_4_record_1[:name]
#        expect(@data_model[:categories][4][0].name).to eq @level_5_record_1[:name]
#        #expect(@data_model[:categories][0][1].name).to eq @level_1_record_2[:name]
#        #expect(@data_model[:categories][1][1].name).to eq @level_2_record_2[:name]
#        #expect(@data_model[:categories][2][1].name).to eq @level_3_record_2[:name]
#        #expect(@data_model[:categories][3][1].name).to eq @level_4_record_2[:name]
#
#        expect(@data_model[:categories][0][0].parent).to eq @level_1_record_1[:parent]
#        expect(@data_model[:categories][1][0].parent).to eq @level_2_record_1[:parent]
#        expect(@data_model[:categories][2][0].parent).to eq @level_3_record_1[:parent]
#        expect(@data_model[:categories][3][0].parent).to eq @level_4_record_1[:parent]
#        expect(@data_model[:categories][4][0].parent).to eq @level_5_record_1[:parent]
#        #expect(@data_model[:categories][0][1].parent).to eq @level_1_record_2[:parent]
#        #expect(@data_model[:categories][1][1].parent).to eq @level_2_record_2[:parent]
#        #expect(@data_model[:categories][2][1].parent).to eq @level_3_record_2[:parent]
#        #expect(@data_model[:categories][3][1].parent).to eq @level_4_record_2[:parent]
#
#        expect(@data_model[:categories][0][0].children).to eq @level_1_record_1[:children]
#        expect(@data_model[:categories][1][0].children).to eq @level_2_record_1[:children]
#        expect(@data_model[:categories][2][0].children).to eq @level_3_record_1[:children]
#        expect(@data_model[:categories][3][0].children).to eq @level_4_record_1[:children]
#        expect(@data_model[:categories][4][0].children).to eq @level_5_record_1[:children]
#        #expect(@data_model[:categories][0][1].children).to eq @level_1_record_2[:children]
#        #expect(@data_model[:categories][1][1].children).to eq @level_2_record_2[:children]
#        #expect(@data_model[:categories][2][1].children).to eq @level_3_record_2[:children]
#        #expect(@data_model[:categories][3][1].children).to eq @level_4_record_2[:children]
#      end
#
#      it "creates an array of content items with the names of their parents, the type of content, and its value(s)" do
#        @content_1 = { 
#          label: "TBD",                 control: nil, values: "TBD", 
#          parent: {
#            label: "TBD", level: 5 }}
#        @content_2 = { 
#          label: "Station List Order",  control: nil, values: "ABC/123",
#          parent: {
#            label: "AM-FM-HD Radio", level: 4 }}
#        @content_3 = { 
#          label: "Auto Front Heater",   control: nil, values: "On/Off", 
#          parent: {
#            label: "Climate Settings", level: 1 }}
#
#        expect(@data_model[:content][0].label).to eq @content_1[:label]
#        expect(@data_model[:content][1].label).to eq @content_2[:label]
#        expect(@data_model[:content][2].label).to eq @content_3[:label]
#
#        expect(@data_model[:content][0].control).to eq @content_1[:control]
#        expect(@data_model[:content][1].control).to eq @content_2[:control]
#        expect(@data_model[:content][2].control).to eq @content_3[:control]
#
#        expect(@data_model[:content][0].parent[:label]).to eq @content_1[:parent][:label]
#        expect(@data_model[:content][1].parent[:label]).to eq @content_2[:parent][:label]
#        expect(@data_model[:content][2].parent[:label]).to eq @content_3[:parent][:label]
#
#        expect(@data_model[:content][0].parent[:level]).to eq @content_1[:parent][:level]
#        expect(@data_model[:content][1].parent[:level]).to eq @content_2[:parent][:level]
#        expect(@data_model[:content][2].parent[:level]).to eq @content_3[:parent][:level]
#
#        expect(@data_model[:content][0].values).to eq @content_1[:values]
#        expect(@data_model[:content][1].values).to eq @content_2[:values]
#        expect(@data_model[:content][2].values).to eq @content_3[:values]
#      end
#    end
#  end

#  describe ".render" do
#    context "given a hash model of the data" do
#      before(:context) do
#        @file = 
#          "ID,L1,L2,L3,L4,L5,L6,L7,Content,Control,Values,End Point Needed,Path Needed\n" +
#          "2.02.03.02.01.01,All Settings,Features,Media,DAB,TBD,,,TBD,,TBD,,TRUE\n" +
#          "2.02.03.01.03,All Settings,Features,Media,AM-FM-HD Radio,,,,Station List Order,,ABC/123,TRUE,TRUE\n" +
#          "3.02,Climate Settings,,,,,,,Auto Front Heater,,On/Off,TRUE,TRUE"
#        @data = ListGenerator.load(data: @file)
#        @list_model = ListGenerator.create(data: @data)
#        @rendered_model = ListGenerator.render(model: @list_model, template: 'settings_list_model')
#      end
#
#      it "renders a list model for the root" do
#        @target = {
#          list: {
#            L1: [], L2: [], L3: [], L4: [], L5: []
#          }, 
#          content: []
#        }
#
#        @target[:list][:L1] = "import QtQuick 2.0\n" +
#                              "\n" +
#                              "ListModel{\n" +
#                              "  ListElement{\n" +
#                              "    label: \"All Settings\"\n" +
#                              "    parentLabel: \"\"\n" +
#                              "    childLabels: [\n" +
#                              "      ListElement{childLabel: \"Features\"}\n" +
#                              "    ]\n" +
#                              "  }\n" +
#                              "  ListElement{\n" +
#                              "    label: \"Climate Settings\"\n" +
#                              "    parentLabel: \"\"\n" +
#                              "    childLabels: [\n" +
#                              "    ]\n" +
#                              "  }\n" +
#                              "}" 
#
#        puts @rendered_model[:path][0]
#
#        expect(@rendered_model[:path][0]).to eq @target[:list][:L1]
##        @target["list"]["L2"] = "import QtQuick 2.0\n" +
##                                "\n" +
##                                "ListModel{\n" +
##                                "  ListElement{\n" +
##                                "    label: \"Features\"\n" +
##                                "    parentLabel: \"All Settings\"\n" +
##                                "    childLabels: [\n" +
##                                "      ListElement{childLabel: \"Media\"}\n" +
##                                "    ]\n" +
##                                "  }\n" +
##                                "}" 
##        @target["list"]["L3"] = "import QtQuick 2.0\n" +
##                                "\n" +
##                                "ListModel{\n" +
##                                "  ListElement{\n" +
##                                "    label: \"Media\"\n" +
##                                "    parentLabel: \"Features\"\n" +
##                                "    childLabels: [\n" +
##                                "      ListElement{childLabel: \"DAB\"},\n" +
##                                "      ListElement{childLabel: \"AM-FM-HD Radio\"}\n" +
##                                "    ]\n" +
##                                "  }\n" +
##                                "}" 
##        @target["list"]["L4"] = "import QtQuick 2.0\n" +
##                                "\n" +
##                                "ListModel{\n" +
##                                "  ListElement{\n" +
##                                "    label: \"DAB\"\n" +
##                                "    parentLabel: \"Media\"\n" +
##                                "    childLabels: [\n" +
##                                "      ListElement{childLabel: \"TBD\"}\n" +
##                                "    ]\n" +
##                                "  }\n" +
##                                "  ListElement{\n" +
##                                "    label: \"AM-FM-HD Radio\"\n" +
##                                "    parentLabel: \"Media\"\n" +
##                                "  }\n" +
##                                "}" 
##        @target["list"]["L5"] = "import QtQuick 2.0\n" +
##                                "\n" +
##                                "ListModel{\n" +
##                                "  ListElement{\n" +
##                                "    label: \"TBD\"\n" +
##                                "    parentLabel: \"DAB\"\n" +
##                                "    childLabels: [\n" +
##                                "    ]\n" +
##                                "  }\n" +
##                                "}" 
##        @target["content"][0] = "import QtQuick 2.0\n" +
##                                "\n" +
##                                "ListModel{\n" +
##                                "  ListElement{\n" +
##                                "    label: \"TBD\"\n" +
##                                "    parentLabel: \"TBD\"\n" +
##                                "    parentLevel: XXXX\n" +
##                                "    interactionComponent: \"XXXX\"\n" +
##                                "    values: [\n" +
##                                "      ListElement{value: \"XXXX\"}\n" +
##                                "    ]\n" +
##                                "  }\n" +
##                                "}" 
##        @target["content"][1] = "import QtQuick 2.0\n" +
##                                "\n" +
##                                "ListModel{\n" +
##                                "  ListElement{\n" +
##                                "    label: \"XXXXX\"\n" +
##                                "    parentLabel: \"XXXX\"\n" +
##                                "    parentLevel: XXXX\n" +
##                                "    interactionComponent: \"XXXX\"\n" +
##                                "    values: [\n" +
##                                "      ListElement{value: \"XXXX\"}\n" +
##                                "    ]\n" +
##                                "  }\n" +
##                                "}" 
##        @target["content"][2] = "import QtQuick 2.0\n" +
##                                "\n" +
##                                "ListModel{\n" +
##                                "  ListElement{\n" +
##                                "    label: \"XXXXX\"\n" +
##                                "    parentLabel: \"XXXX\"\n" +
##                                "    parentLevel: XXXX\n" +
##                                "    interactionComponent: \"XXXX\"\n" +
##                                "    values: [\n" +
##                                "      ListElement{value: \"XXXX\"}\n" +
##                                "    ]\n" +
##                                "  }\n" +
##                                "}" 
#
#      end
#    end
#  end
end
