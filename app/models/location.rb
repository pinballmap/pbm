class Location < ActiveRecord::Base
#  scope :by_name, proc { |name| { :conditions => { :name => name }}}

  validates_presence_of :name, :street, :city, :state, :zip

  def self.search(by_name)
    if by_name
      where('name LIKE ?', "%#{by_name}%")
    else
      scoped
    end
  end
end
