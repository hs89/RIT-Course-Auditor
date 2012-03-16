require 'mechanize'
require 'highline'
require 'redis'

@database_server = "96.8.118.7"
@database_port = 1234
@database_password ="audit"

class Course
  def init(course_num, course_title, course_instructor, course_days, course_from, course_to, course_location)
    @course_num = course_num
    @course_title = course_title
    @course_instructor = course_instructor

    if (@course_instructor =~ /TBA/)
      @course_instructor.gsub!("T TBA", "")
      @course_instructor.gsub!("TBA","")
      if(@course_instructor == nil ||
         @course_instructor == "")
        return false
      end
    end
    matches = @course_instructor.scan(/(\S\s\S+)/)
    if(matches.length > 1)
      @course_instructor = "#{matches[0, matches.length].join(', ')}"
    else
    end
    @course_instructor.strip!
    @course_days = course_days
    @course_from = course_from
    @course_to = course_to
    @course_location = course_location
  end
  
  def print
    puts @course_num + "  " + @course_title + "  " + @course_instructor + "  " + @course_days + "  " + @course_from + "  " + @course_to + "  " + @course_location
  end
  
  def write
    if(@course_location == "TBA" ||
       @course_days == "TBA" ||
       @course_from == "TBA" ||
       @course_to == "TBA" ||
       @course_instructor == "")
      #Don't want to write this data to the database
      return
    else
      #Write Data to appropriate databases
      print
    end    
  end
end


def create_database(discipline_number, course_list_page)
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
    if(temp_course != false)
      temp_course.write    
    end
  end
end

def scrape_SIS
  agent = Mechanize.new
  agent.user_agent_alias = 'Windows Mozilla'
  agent.verify_mode = OpenSSL::SSL::VERIFY_NONE

  discipline_selection_page = agent.get "https://sis.rit.edu/info/info.do?init=openCourses"
  discipline_form = discipline_selection_page.form_with(:action => "getOpenCourseList.do?init=openCourses")
  discipline_dropdown = discipline_form.field_with(:name => "discipline")
  
  discipline_dropdown.options.each do |opt|
    discipline_dropdown.value = opt
    discipline_course_page = discipline_form.submit
    create_database(opt, discipline_course_page)  
  end
end

def connect_database
  @redis = Redis.new(:host => @database_server,
                     :port => @database_port)
  connected = @redis.auth(@database_password)
  
  if (connected == "OK")
    then return true
  else
    return false
  end
end


if(connect_database)
  scrape_SIS
else
  puts "Failed to connect to the database"
  exit
end