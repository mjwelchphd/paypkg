#####################################################
### This extends NilClass to add empty? #############
### It just makes sense that nil is empty, right? ###
#####################################################

class NilClass
  # This adds the empty? method to nil, so that nil.empty? => true
  def empty?
    true
  end
end

