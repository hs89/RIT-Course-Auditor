require 'mechanize'
require 'highline'

agent = Mechanize.new
agent.user_agent_alias = 'Windows Mozilla'
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

def mine_data(discipline_number, course_list_page)
  course_table_rows = course_list_page.parser.xpath("//table[@class='stripeMe courseList menuBox']/tbody/tr")
  course_table_rows.collect do |row|
    if(row.at("td[7]") == nil)
      #this row is an addition of the previous row
      #it may be a different location for the same class
      #TODO: Handle this case.. needs to look up to the previous row and pull some of that data to populate this
      puts "TODO"
    
    else
      course_num = discipline_number.to_s + "-" + row.at("td[1]").text.strip
      course_title = row.at("td[2]").text.strip
      course_instructor = row.at("td[3]").text.strip
      course_days = row.at("td[7]").text.strip
      course_from = row.at("td[8]").text.strip
      course_to = row.at("td[9]").text.strip
      course_location = row.at("td[10]").text.strip
      puts course_num + "  " + course_title + "  " + course_instructor + "  " + course_days + "  " + course_from + "  " + course_to + "  " + course_location
    end
  end
end

discipline_selection_page = agent.get "https://sis.rit.edu/info/info.do?init=openCourses"
discipline_form = discipline_selection_page.form_with(:action => "getOpenCourseList.do?init=openCourses")
discipline_dropdown = discipline_form.field_with(:name => "discipline")

discipline_dropdown.options.each do |opt|
  discipline_dropdown.value = opt
  discipline_course_page = discipline_form.submit
  mine_data(opt, discipline_course_page)  
end