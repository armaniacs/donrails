class Admin::CategoryController < AdminController
  cache_sweeper :article_sweeper, :only => [ :add_category, :delete_category ]

  def manage_category
    if params['id']
      @category = Category.find(params['id'])
      if @category.parent_id
        @parent = Category.find(@category.parent_id)
      end
    end

    @categories_pages, @categories = paginate(:category,:per_page => 30,:order => 'id DESC')

    @roots = Category.find(:all, :conditions => ["parent_id IS NULL"])
    @size = Category.find(:all).size
  end

  def add_category
    c = params["category"]
    if c
      parent = Category.find(:first, :conditions => ["name = ?", c["parent_name"]])
      aris1 = Category.find(:first, :conditions => ["name = ?", c["name"]])
      
      if parent and aris1
        aris1.parent_id = parent.id
        flash[:note] = "Change #{c['name']}'s parent. New parent is #{c["parent_name"]}."
      elsif parent
        aris1 = Category.new("name" => c["name"])
        aris1.save
        parent.add_child(aris1)
        flash[:note] = "Add new category:#{c['name']}. Her parent is #{c["parent_name"]}."
      elsif aris1
      else
        aris1 = Category.new("name" => c["name"])
        flash[:note] = "Add new category:#{c['name']}."
      end
      aris1.description = c["description"]
      aris1.save
    end
    redirect_to :action => "manage_category"
  end

  def delete_category
    c = params["deleteid"].nil? ? [] : params["deleteid"]
    c.each do |k, v|
      if v.to_i == 1
        
        cas = Category.find(:all, :conditions => ["parent_id = ?", k.to_i])
        cas.each do |ca|
          ca.parent_id = nil
          ca.save
        end

        b = Category.find(k.to_i)
        b.destroy
      end
    end
    redirect_to :action => "manage_category"
 end

end
