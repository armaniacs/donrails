class Enrollment < ActiveRecord::Base
  has_many :articles, :order => "id DESC", :dependent => :destroy

  def self.search(query)
    if !query.to_s.strip.empty?
      tokens = query.split.collect {|c| "%#{c.downcase}%"}
      find_by_sql(["SELECT enrollments.* from enrollments,articles WHERE #{ (["LOWER(articles.body) like ?"] * tokens.size).join(" AND ") } AND (enrollments.hidden IS NULL or enrollments.hidden = 0) AND (enrollments.id = articles.enrollment_id) ORDER by enrollments.id DESC", *tokens])
    else
      []
    end
  end

end
