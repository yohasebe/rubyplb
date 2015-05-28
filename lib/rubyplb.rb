## lib/rubyplb.rb -- Patten Lattice Builder written in Ruby
## Design::    Kow Kuroda (mailto: kuroda@nict.go.jp)   
## Program::   Yoichiro Hasebe (mailto: yohasebe@gmail.com)
## Copyright:: Copyright 2009 Kow Kuroda and Yoichiro Hasebe
## License::   GNU GPL version 3

# -*- coding: utf-8 -*-

require 'ruby_graphviz'

## load ary_with_combination if not Ruby 1.9.x
unless Array.instance_methods.index(:combination)
  require 'ary_with_combination'
end

def showerror(sentence, severity)
  if severity == 0
    puts "Warning: #{sentence} The output may not be meaningful."
  elsif severity == 1
    puts "Error: #{sentence} No output generated."
    exit
  end
end

class Array
  def subset
    (0..self.length).inject([]) do |ret, n|
      ret.push(*self.combination(n))
    end
  end
end

class Node
  attr_accessor :data, :children, :parents, :leaf, :level, :num_instances
  def initialize(data)
    @data = data
    @level = data.select{|b| b != "_"}.size
    if @level == 0 
      @leaf = true
    else
      @leaf = false
    end
    @children = []
    @parents = []
    @num_instances = 1
  end
  
  def children_instances
    @children.inject(0) { |sum, child| sum += child.num_instances }
  end
end  

class PatLattice
  attr_accessor :levels, :root_level, :root, :leaves, :nodes
  
  def initialize(opts)
    @opts = opts
    @levels = []
    @root_level = 0
    @root = nil
    @leaves = []
    @nodes = {}
    @level_data = {}
    @coloring = {}
  end
  
  def ary_compact(ary, target = nil)
    prev = nil
    result = []
    ary.each do |n|
      next if (prev == n and n == target)
      prev = n
      result << n
    end
    return result      
  end
  
  def create_patterns(sentence, compact)
    words = sentence.split(/\s+/)
    if /\((\d+)\)/ =~ words[-1]
      words.pop 
      times = $1.to_i
    else
      times = 1
    end
    
    if /\[(.+)\]/ =~ words[-1]
      words.pop
      color = $1
    end
    
    words.each do |w|
      if /\[\]\(\)/ =~ w
        raise "Data contains an invalid string."
      end
    end
    
    words.reverse! if /\ARL\z/i =~ @opts[:direction]
    
    idx = (0...words.size).to_a
    words_with_idx = words.zip(idx).collect{|a| a.join("-")}
    masks = words_with_idx.subset
    ptns = []
    masks.each do |mask|
      ptn1 = []
      words_with_idx.each do |t|
        if mask.index(t)
          /\A(.*?)\-\d+\z/ =~ t
          ptn1 << $1
        else
          ptn1 << "_"
        end
      end
      if compact
        ptns << ary_compact(ptn1, "_") 
      else
        ptns << ptn1
      end
    end

    color = color ? color : "gray60"

    if @coloring[color]
      @coloring[color] += ptns
    else
      @coloring[color] = ptns
    end
    
    
    return ptns * times
  end
  
  def search(pattern)
    node = nodes[pattern.join("+").intern]
  end
  
  def insert(sentence, compact)
    ptns = create_patterns(sentence, compact)    
    new_nodes = []    
    ptns.each do |ptn|
      if existing = search(ptn)
        existing.num_instances += 1
      else
        node = Node.new(ptn)
        nodes[node.data.join("+").intern] = node
        new_nodes << node
      end
    end
        
    new_nodes.each do |node|
      level = node.level
      if levels[level]
        levels[level] << node
      else
        levels[level] = [node]
      end
      

      uplevel   = levels[level - 1]
      if level != 0 and uplevel
        uplevel.each do |sup_node|
          rgx = Regexp.new("\\A" + sup_node.data.join(" ").gsub(/(\b_)+/, ".+?") + "\\z")
          if rgx.match(node.data.join(" "))
            sup_node.children << node
            node.parents << sup_node
          end
        end
      end

      downlevel = levels[level + 1]
      if downlevel
        break unless downlevel
        downlevel.each do |sub_node|
          rgx = Regexp.new("\\A" + node.data.join(" ").gsub(/\_/, ".*") + "\\z")
          if rgx.match(sub_node.data.join(" "))
            node.children << sub_node
            sub_node.parents << node  
          end
        end
      end
      @leaves << node if node.leaf
    end

    @root_level = levels.size - 1
    @root = levels[root_level].first
  end
  
  def traverse(&block)
    levels.each do |level|
      level.each do |node|
        yield node
      end
    end
  end
  
  def setup_data
    levels.each_with_index do |level, l_index|
      num_nodes_non_terminal = 0
      sum_node_non_terminal = 0
      avg_num_children = 0
      valid_elements = []
      level.each do |node|
        next if node.children_instances == 0
        valid_elements << node
        num_nodes_non_terminal += 1 
        sum_node_non_terminal += node.children_instances
      end
      if valid_elements.size > 0
        avg_num_children = sum_node_non_terminal.to_f / num_nodes_non_terminal
        x = valid_elements.inject(0){|sum, node| (node.children_instances - avg_num_children) ** 2 + sum}
        std_dev = Math.sqrt( x / num_nodes_non_terminal)
        @level_data[l_index] = {:num_nodes_non_terminal => num_nodes_non_terminal, 
                                :avg_num_children => avg_num_children, 
                                :std_dev_num_children => std_dev
                                }
      else
        @level_data[l_index] = {:num_nodes_non_terminal => 0, 
                                :avg_num_children => 0, 
                                :std_dev_num_children => 0.0
                                }
      end
    end
  end
  
  def create_nodelabel(node)
    if (@opts[:coloring] != 0 || !@opts[:simple])
      if node.level != 0 and node.children_instances > 0
        ldata = @level_data[node.level]
        dev = node.children_instances - ldata[:avg_num_children]
        zscore = dev / ldata[:std_dev_num_children]
        zscore = zscore.nan? ? 0.0 : zscore
      else
        zscore = 0.0
      end
    end

    if @opts[:coloring] == 0
        color = "#ffffff"
    else
      if zscore.nan? or zscore == 0.0
        color = "#ffffff"
      elsif zscore >= 3.0
        color = @opts[:coloring] == 1 ? "2" : "6"
      elsif zscore >= 1.5
        color = @opts[:coloring] == 1 ? "3" : "5"
      elsif zscore >= 1.0
        color = @opts[:coloring] == 1 ? "4" : "4"
      elsif zscore >= 0.5
        color = @opts[:coloring] == 1 ? "5" : "3"
      elsif zscore > 0.0
        color = @opts[:coloring] == 1 ? "6" : "2"
      elsif zscore >= -0.5
        color = @opts[:coloring] == 1 ? "7" : "1"
      elsif zscore >= -1.0
        color = @opts[:coloring] == 1 ? "8" : "1"
      elsif zscore >= -1.5
        color = @opts[:coloring] == 1 ? "9" : "1"
      elsif zscore >= -3.5
        color = @opts[:coloring] == 1 ? "10" : "1"
      else
        color = @opts[:coloring] == 1 ? "11" : "1"
      end
    end
    border = "0"
    pat_str = node.data.collect{|td|"<td color='black'>#{td}</td>"}.join
    pat_str = "&nbsp;" * 5 if pat_str == ""        
    label = "<<table bgcolor='#{color}' border='#{border}' cellborder='1' cellspacing='0' cellpadding='5'>" +
            "<tr>#{pat_str}</tr>"
    if !@opts[:simple]
      zscore = ((zscore * 100).round / 100.0).to_s   
      label += "<tr><td color='black' colspan='#{node.data.size.to_s}'> "
      if node.level != 0 and node.children_instances > 0
        label += node.children_instances.to_s + " (" + zscore.to_s + ")"
      end
      label += "</td></tr>"
    end        
    label += "</table>>"
    return label
  end
  
  def create_node(graph, node_id, node_label)
    case @opts[:coloring] 
    when 1
      colorscheme = "rdylbu11"
    when 2
      colorscheme = "greys9"
    else
      colorscheme = ""
    end
    
    graph.node(node_id, :label => node_label, :shape => "plaintext", 
                        :height => "0.0", :width => "0.0",
                        :margin => "0.0", :colorscheme => colorscheme, :URL => node_id)
  end
  
  def generate_dot
   setup_data if (@opts[:coloring] != 0 || !@opts[:simple])
   nodes_drawn = []
   rankdir = @opts[:vertical] ? "" : "LR" 
   nodesep = @opts[:nodesep] ? @opts[:nodesep].to_s : "0.8"
   ranksep = @opts[:ranksep] ? @opts[:ranksep].to_s : "0.8"
   plb = RubyGraphviz.new("plb", :rankdir => rankdir, :nodesep => nodesep, :ranksep => ranksep)
   levels.each do |level|
     level.each do |node|
       node_id = node.object_id     
       unless nodes_drawn.index node_id
         node_label = create_nodelabel(node)
         create_node(plb, node_id, node_label) 
         nodes_drawn << node_id
       end
       node.children.each do |cnode|
         cnode_id = cnode.object_id
         unless nodes_drawn.index cnode_id
           cnode_label = create_nodelabel(cnode)
           create_node(plb, cnode_id, cnode_label) 
           nodes_drawn << node_id
         end
         if @opts[:coloring] != 0
           colors = []
           @coloring.each do |color, val|
             if val.index(node.data) and val.index(cnode.data)
               colors << color
             end
           end
         else
           colors = ["gray60"]
         end
         plb.edge(node_id, cnode_id, :color => colors.join(":"))
       end
     end
   end
   result = plb.to_dot.gsub(/\"\</m, "<").gsub(/\>\"/m, ">")
   return result
  end
  
  def generate_img(outfile, image_type, straight_line = false)
    dot = generate_dot
    isthere_dot = `dot -V 2>&1`
    if isthere_dot !~ /dot.*version/i
      showerror("Graphviz's dot program cannot be found.", 1)
    else
      if straight_line
        cmd = "dot | neato -n -T#{image_type} -o#{outfile} 2>rubyplb.log"
      else
        cmd = "dot -T#{image_type} -o#{outfile} 2>rubyplb.log"
      end
      IO.popen(cmd, 'r+') do |io|
        io.puts dot
      end
    end
  end  
  
end
