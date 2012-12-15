class Array
  @@combi_indices_hash = {}

  def combi_indices(s,n)
    ret = @@combi_indices_hash[s] ||= []
    if ret.empty?
      s.times{|i|
        ret.dup.each{|a|
          ret.push(a+[i])
        }
        ret.push([i])
      }
    end
    ret.select{|a|a.size==n}
  end

  def combination(n)
    # combination of Ruby 1.9.x returns array with a blank array as its top
    combi_indices(self.size,n).collect{|a| self.values_at(*a)}.unshift([])
  end

  def subsets
    (0..length).inject([]) do |ret, n|
      ret.push(*combination(n))
    end.uniq
  end

  def true_subsets
    (1..length).inject([]) do |ret, n|
      ret.push(*combination(n))
    end.uniq
  end
end
