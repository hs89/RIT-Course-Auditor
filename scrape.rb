require 'mechanize'
require 'highline'

agent = Mechanize.new
agent.user_agent_alias = 'Windows Mozilla'
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

class Course
  def init(course_num, course_title, course_instructor, course_days, course_from, course_to, course_location)
    @course_num = course_num
    @course_title = course_title
    @course_instructor = course_instructor

    #TODO: Fix this regex.. it will properly create the list of professors teaching the course but if they have a trailing Jr. in their name it doesnt work    
    matches = @course_instructor.scan(/(\S{1}\s\S{1+})/)
    if(matches.length > 1)
      @course_instructor = "#{matches[0, matches.length].join(', ')}"
      puts @course_instructor
    else
    end
    @course_days = course_days
    @course_from = course_from
    @course_to = course_to
    @course_location = course_location
  end
  def print
    puts @course_num + "  " + @course_title + "  " + @course_instructor + "  " + @course_days + "  " + @course_from + "  " + @course_to + "  " + @course_location
  end
end


def mine_data(discipline_number, course_list_page)
  course_table_rows = course_list_page.parser.xpath("//table[@class='stripeMe courseList menuBox']/tbody/tr")
  course_table_rows.collect do |row|
    temp_course = Course.new
    if(row.at("td[7]") == nil)
      #this row is an addition of the previous row
      #it may be a different location for the same class
      #Handle this case.. needs to look up to the previous row and pull some of that data to populate this
      @course_num = @course_num
      @course_title = @course_title
      @course_instructor = @course_instructor
      @course_days = row.at("td[2]").text.strip
      @course_from = row.at("td[3]").text.strip
      @course_to = row.at("td[4]").text.strip
      @course_location = row.at("td[5]").text.strip     
      temp_course.init(@course_num, @course_title, @course_instructor, @course_days, @course_from, @course_to, @course_location)
      #temp_course.print    
    else
      @course_num = discipline_number.to_s + "-" + row.at("td[1]").text.strip
      @course_title = row.at("td[2]").text.strip
      @course_instructor = row.at("td[3]").text.strip
      @course_days = row.at("td[7]").text.strip
      @course_from = row.at("td[8]").text.strip
      @course_to = row.at("td[9]").text.strip
      @course_location = row.at("td[10]").text.strip
      temp_course.init(@course_num, @course_title, @course_instructor, @course_days, @course_from, @course_to, @course_location)      
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