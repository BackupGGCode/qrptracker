#Todo:
#Make logging window, so that we can get rid of puts statements


require 'wx'
require 'open-uri'
require 'TleCollection'
require 'serialport'

VERSION_NUMBER = 0
DIALOGS_TLE_FILE_OPEN = 10
DIALOGS_DOPPLER_FILE_OPEN = 11
DIALOGS_TONES_FILE_OPEN = 12
DIALOGS_MODELINES_FILE_OPEN = 14
DIALOGS_SAVE = 1
DIALOGS_SET_EEPROM_SIZE = 5
DIALOGS_SET_LAT = 6
DIALOGS_SET_LONGITUDE = 7
DIALOGS_ERASE_ALL = 15
DIALOGS_BURN = 16
DIALOGS_SET_COMPORT = 17
DIALOGS_SET_ALTITUDE = 18
DIALOGS_BURN_TIME = 19
DIALOGS_LOAD_TLES = 20
class DragListBox < Wx::ListCtrl
    def initialize(parent)

        super(parent, -1, Wx::DEFAULT_POSITION, Wx::DEFAULT_SIZE, 
                Wx::LC_REPORT | Wx::LC_SINGLE_SEL)
                
       # insert_column(0, 'Available Sats')
        
        evt_list_begin_drag(get_id)  do | e | 
          on_drag(e) 
	    puts "dragging"
          end
          evt_list_begin_rdrag(id) { | event |  
            puts "rdragging" 
	    }
     
    end

    def append(text)
        row = get_item_count
        insert_item(row, text)
        set_item_text(row, text)
    end

    def get_selected_row
	return get_next_item(-1, Wx::LIST_NEXT_ALL, Wx::LIST_STATE_SELECTED)
    end

    def on_drag(event)
        selected_row = get_selected_row
        if(selected_row < 0)
            puts("nothing to drag")
            return
	end
        data = Wx::TextDataObject.new(get_item_text(selected_row))
        dragSource = Wx::DropSource.new(self);
        dragSource.set_data(data);
        result = dragSource.do_drag_drop()
        case result
            when Wx::DRAG_NONE:
                puts("Drop was rejected")
            when Wx::DRAG_CANCEL:
                puts("Drag canceled by user")
            when Wx::DRAG_COPY:
                puts("Copied")
            when Wx::DRAG_MOVE:
                puts("Moved")
                delete_item(selected_row)
            else
                puts("ERROR or Unknown result!")
        end
    end
end

class MyDropTarget < Wx::TextDropTarget
    def initialize(owner)
        super()
        @owner = owner
        @owner.set_drop_target(self)
        
    end

    def on_drop_text(x, y, text)
      #  puts("Accepting drop of #{text} at #{x}, #{y}")
        @owner.handle_drop(x, y, text)
        return true
    end
end

class DragAndDropListBox < DragListBox
     attr_accessor :bytes
     attr_accessor :myCollection
  def initialize(parent, collection, bytes)
      	@collection = collection
      	@bytes = bytes
      	
    super(parent)
    target = MyDropTarget.new(self)
    evt_list_item_activated(get_id) { | event |  on_activate(event) }
  end
      def on_activate(event)
       selected_row = get_selected_row
      # puts "I'm going to delete #{selected_row}"
       delete_item(selected_row)
       checkBinaryFileSize
      end
      def eraseAll
	  for k in 1..get_item_count
	      delete_item(0)
	      checkBinaryFileSize
	  end
      end
    def handle_drop(x, y, text)	
        self.each do |i|
         # puts "item: #{i}; text: #{get_item_text(i)}"
          begin
            if get_item_text(i) == text
             delete_item(i)
             break
            end
	rescue
	    puts "Item #{i} caused problems"
        end
         end
        p = Wx::Point.new(x,y)
        ar =  hit_test(p)
        if ar[1] == Wx::LIST_HITTEST_ONITEMLABEL && ar[0] > -1
           puts "Hit item #{ar[0]}"
           insert_item(ar[0], text)
           set_item_text(ar[0], text)
        else  
         append(text)
         #here check if we have too many keps.
        
        end
           checkBinaryFileSize 
    end
    def checkBinaryFileSize
	@myCollection = TleCollection.new
	self.each do |i|
	    puts "testing #{get_item_text(i)}"
	    @collection.tles.each_index do |x|
		if @collection.tles[x].name == get_item_text(i)
		   puts "adding #{@collection.tles[x].name}"
		    @myCollection.tles.push(@collection.tles[x].clone)
		    @myCollection.print
		    #puts thisTles.inspect
		    puts "array is now #{@myCollection.tles.length} long"
		    break
		end
	    end
	    @myCollection.alignModelines
	end
	#puts "array is now #{@myCollection.tles.length} long"
	#@myCollection.print
	@myCollection.toSize(@bytes)
	#@myCollection.print
	#puts "number for bytes: #{@myCollection.numberForBytes}"
	self.each do |i|
	    if i > @myCollection.numberForBytes
		set_item_background_colour(i, Wx::RED)
	    else
		set_item_background_colour(i, Wx::WHITE)
	    end
	end
    end
    def append(text)
        row = get_item_count
        insert_item(row, text)
        set_item_text(row, text)
    end
end



class MyFrame < Wx::Frame
	attr_reader :list2
        attr_reader :list1
  def initialize(title, tleCollection, bytes)
    super(nil, -1, title)
    @list1 = DragListBox.new(self)
    list1.insert_column(0, 'Available')    
    @list2 = DragAndDropListBox.new(self, tleCollection, bytes)
    @list2.insert_column(0, 'Chosen')
    lists = Wx::BoxSizer.new(Wx::HORIZONTAL)
    lists.add(list1, 1, Wx::EXPAND)
    lists.add(list2, 1, Wx::EXPAND)
    
    instructions = Wx::StaticText.new(self, -1, 
        "Drag satellite names from the left list to the right.\n" +
        "You may rearrange the items in the right list or delete them\n" +
         " by double-clicking. The order of the left list sets priority")
    @textctrl = Wx::TextCtrl.new( self, 
                                 # :text => 'I should be logger', 
                                  :style => Wx::TE_MULTILINE|Wx::SUNKEN_BORDER)
    # set our text control as the log target
    logWindow = Wx::LogTextCtrl.new(@textctrl)
    Wx::Log::active_target = logWindow

    main_sizer = Wx::BoxSizer.new(Wx::VERTICAL)
    main_sizer.add(instructions, 0, Wx::EXPAND)
    main_sizer.add(lists, 1, Wx::EXPAND)
    main_sizer.add(@textctrl, 0, Wx::EXPAND)
    set_sizer(main_sizer)
    
  end
end



class DragDropApp < Wx::App
  def on_init
	@tle_file = @doppler_file = @modeline_file = @tones_file = ""
	@eeprom_size = 1024
	@longitude = 0
	@lat = 0
	@altitude = 0
	@commport = ""
	@last_time_sync = 0
	@kep_uri = 'http://www.amsat.org/amsat/ftp/keps/current/nasabare.txt_bad'
	get_config()
	@collection = TleCollection.new
    @collection.loadFromWeb(@modeline_file, true)
    puts @collection.inspect
    @frame = MyFrame.new("Satpack Burner", @collection,@eeprom_size)
        file_menu = Wx::Menu.new
        settings_menu = Wx::Menu.new
        edit_menu = Wx::Menu.new
    menu_bar = Wx::MenuBar.new
    menu_bar.append(file_menu, "&File")
    menu_bar.append(edit_menu, "&Edit")
    menu_bar.append(settings_menu, "&Settings")
    @frame.set_menu_bar(menu_bar)
   # file_menu.append(DIALOGS_TLE_FILE_OPEN,  "&Set TLE file\tCtrl-O")
    file_menu.append(DIALOGS_DOPPLER_FILE_OPEN,  "&Set SQF file\tCtrl-O")
    file_menu.append(DIALOGS_LOAD_TLES, "Load Tles From Web");
    file_menu.append(DIALOGS_BURN, "&Burn TLES and Modelines\tCtr-B")
    file_menu.append(DIALOGS_BURN_TIME, "Burn Date and Time")
    file_menu.append(DIALOGS_SAVE, "&Save\tCtr-S")
    file_menu.append(Wx::ID_EXIT, "Quit", "really quit")
    settings_menu.append(DIALOGS_SET_EEPROM_SIZE, "Set EEPROM Size")
    settings_menu.append(DIALOGS_SET_LAT, "Set Latitude")
    settings_menu.append(DIALOGS_SET_LONGITUDE, "Set Longitude")
    settings_menu.append(DIALOGS_SET_ALTITUDE, "Set Altitude")
    settings_menu.append(DIALOGS_SET_COMPORT, "Set Com Port")
    edit_menu.append(DIALOGS_ERASE_ALL, "Erase All")
    evt_menu(DIALOGS_LOAD_TLES) {|event| 
        on_load_tles
        }
    evt_menu(DIALOGS_SET_EEPROM_SIZE) {|event| on_set_eeprom_size()}
    evt_menu(DIALOGS_SET_LAT) {|event| on_set_lat()}
     evt_menu(DIALOGS_SET_LONGITUDE) {|event| on_set_longitude()}
	     evt_menu( Wx::ID_EXIT, :on_quit )
    evt_menu(DIALOGS_SAVE) {|event| on_save()}
    evt_menu(DIALOGS_ERASE_ALL) {|event| on_erase_all}
    evt_menu(DIALOGS_TLE_FILE_OPEN) {|event| 
      guess = File.join(File.expand_path("~"),"Application Data", "SatPC32", "Kepler")
      on_file_open(event, @tle_file, "TLE", "TLE files (*.tle;*.txt)|*.tle;*.txt", guess) 
}
    evt_menu(DIALOGS_DOPPLER_FILE_OPEN) {|event| on_file_open(event) }
    evt_menu(DIALOGS_TONES_FILE_OPEN) {|event| on_tle_open(event) }
    evt_menu(DIALOGS_MODELINES_FILE_OPEN) {|event| on_file_open(event) }
    evt_menu(DIALOGS_BURN) {|event|
	burn_tles}
    evt_menu(DIALOGS_SET_COMPORT) {|event|
     on_set_commport
     }
     evt_menu(DIALOGS_SET_ALTITUDE) {|event|
       on_set_altitude
       }
       evt_menu(DIALOGS_BURN_TIME) {|event|
         on_burn_time
         }
    @collection.tles.each { |tle|
         @frame.list1.append(tle.name)
     }
     loadConfigurationSatellites
	@frame.show
	#_tles
	#test_for_avrdude
    end
    def on_load_tles
      @collection.loadFromWeb(@modeline_file, true)
      end
  def on_quit
	  on_save
    @frame.close
  end
  
  def on_burn_time
    #send 14-char time to serial port
    data_bits = 8
    stop_bits = 1
    parity = SerialPort::NONE
    if test_commport(@commport) == false
      return
    end
   # dlg = Wx::MessageDialog.new(@frame, "Storing the current date and time to satpack", "Notification", @frame, Wx::PD_AUTO_HIDE)
	#      dlg.show_modal()
    sp = SerialPort.new(@commport, 115200, data_bits, stop_bits, parity)
    sp.flow_control = SerialPort::NONE
    sp.read_timeout = 0
    sp.write_timeout = 0
    #If this really is a qrpTracker, we expect the string 'QRPT'
    #TODO timeout this
    stringIn = ""
    while (stringIn[-4,4] != "QRPT")
       c = sp.getc
       puts c
       #Windows sends nils when it feels grumpy. So we'll just ignore them
       if c != nil
          stringIn << c
          puts stringIn
       end
    end

    #if we get something other than the magic word, we'd better get lost
    unless stringIn[-4,4] == "QRPT"
       puts "Error: didn't get proper response from chip.\nExpected 'QRPT', got #{stringIn}"
       Process.exit
    end

    #tell the qrpTracker to 'Receive' the TLEs and modelines
    puts "writing R"
    sp.write('R')


    puts "writing time"
    #sp.write("FOO BAR THE BAR BAZ BOO")
    timeString = Time.now.getgm.strftime("%y%m%d0%w%H%M%S")
    if timeString.length != 14 
      puts "WARNING: timestring is wrong length!!!"
    end
    sp.write(timeString)
    puts "finished writing time"
    while (c != 84 && c != 70 ) #T and F
       c = sp.getc
       puts c
    end
    if c == 70
      puts "Error: time handshake was not good"
      Process.exit
    end
    puts "Time Handshake good. Closing comm port"
    sp.close
    
  end
  
  def burn_tles
       unless test_commport(@commport)
	   return
       end
       unless test_for_avrdude
	   return
       end
     #  f = Tempfile.new("tle_binary")
       #@frame.list2.myCollection.print
      #Wx::log_message( "binary file is: #{f.inspect}")
     #  f.print(@frame.list2.myCollection.binaryDump)
       foo = File.open("burner.bin", "wb")
       #the first thing on the file is the version number
       
       foo.print([VERSION_NUMBER].pack("c"));
       #then we put the latitude and longitude
       foo.print([@lat,@longitude,@altitude].pack("ffS"));
       #then we put the keps and modelines
       foo.print(@frame.list2.myCollection.binaryDump)
       
       foo.close
       commandLine = "avrdude -c arduino -b 57600 -p m328p -P #{@commport} -U eeprom:w:burner.bin:r"
       #Wx::log_message("\n\nRunning the following command:\n" + commandLine)
       `#{commandLine}`.each {|line|
	  # Wx::log_message(line)
	   }
       #unless system(commandLine)
	#   dlg = Wx::MessageDialog.new(@frame, "Unable to burn the eeprom using #{commandLine} Please double-check comm port and chip type", "Notification", Wx::OK | Wx::ICON_INFORMATION)
        #dlg.show_modal()
	  #end
  end
  def test_for_avrdude
	  unless system("avrdude")#should return true, but quite verbose
	      dlg = Wx::MessageDialog.new(@frame, "Unable to access avrdude. Please install Arduino environment.", "Notification", Wx::OK | Wx::ICON_INFORMATION)
	      dlg.show_modal()
	      return false
	  end
	  return true
  end
  
  def get_fresh_tles
      begin
    puts open(@kep_uri,
         'User-Agent' => 'Ruby-Wget').read
      end
  rescue OpenURI::HTTPError
    
        dlg = Wx::MessageDialog.new(@frame, "Unable to download keplerian elements from '#{@kep_uri}'", "Notification", Wx::OK | Wx::ICON_INFORMATION)
        dlg.show_modal()

       end
  def get_config() 
     if File.exists?('text.cfg') 
	  @configuration = Hash.new
	  open('text.cfg') {|f| @configuration = YAML.load(f) }
	  #puts @configuration.inspect

	  @tle_file = @configuration["tle_file"]
	  @doppler_file = @configuration["doppler_file"]
	  @modeline_file = @configuration["modeline_file"]
	  @tones_file = @configuration["tones_file"]
	  @eeprom_size = @configuration["eeprom_size"]
	  @lat = @configuration["lat"]
	  @longitude = @configuration["longitude"]
	  @commport = @configuration["commport"]
	  @altitude = @configuration["altitude"]
	  @last_time_sync = @configuration["last_time_sync"]
	  @collection =  @configuration["collection"]
	  end
  end
  def loadConfigurationSatellites
      	@configuration["satellites"].each do |name| 
	    @frame.list2.append(name)
      	end
      	@frame.list2.checkBinaryFileSize
  end
  def on_save()
	
	satellites = Array.new
	@frame.list2.each do |i|
          satellites.push(@frame.list2.get_item_text(i))
  end
         @configuration = {'collection' => @collection, 'satellites' => satellites,  'doppler_file' => @doppler_file, 'modeline_file' => @modeline_file, 'eeprom_size'=> @eeprom_size, 'longitude' => @longitude, 'lat' => @lat, 'altitude' => @altitude, 'commport' => @commport}
	
	open('text.cfg', 'w') { |f| YAML.dump(@configuration, f) }

  end
  def on_set_eeprom_size
      dlg = Wx::SingleChoiceDialog.new(@frame, "Test Single Choice", "Select EEPROM Size In Bytes", 
                                            %w(1024 2048))
                                            #Wx::CHOICEDLG_STYLE)
        if dlg.show_modal() == Wx::ID_OK
            @eeprom_size = dlg.get_string_selection().to_i
        end
        dlg.destroy()
        return nil
  end
  def on_set_lat
       dlg = Wx::TextEntryDialog.new(@frame, "Observer Decimal Latitude N", "", @lat.to_s)
        dlg.set_value(@lat.to_s)
        if dlg.show_modal() == Wx::ID_OK
            @lat = dlg.get_value().to_f
        end     
        return nil
  end
    def on_set_commport
       dlg = Wx::TextEntryDialog.new(@frame, "Comm Port", "", @commport)
        unless @commport.nil?
	    dlg.set_value(@commport)
	end
        if dlg.show_modal() == Wx::ID_OK
            @commport = dlg.get_value()
        end
        test_commport(@commport)
        return nil
    end
    def test_commport commport
	begin
	  sp = SerialPort.new commport, 57600
	  sp.close()
       rescue
	  dlg = Wx::MessageDialog.new(@frame, "Unable to access serial port #{commport}", "Notification", Wx::OK | Wx::ICON_INFORMATION)
	    dlg.show_modal()
	    return false
	end
	return true
    end
    def on_set_longitude
       dlg = Wx::TextEntryDialog.new(@frame, "Observer Decimal Longitude East (Neg for West)", "", @longitude.to_s)
        dlg.set_value(@longitude.to_s)
        if dlg.show_modal() == Wx::ID_OK
            @longitude = dlg.get_value().to_f
        end     
        return nil
    end
    def on_set_altitude
      dlg = Wx::TextEntryDialog.new(@frame, "Observer Altitude (in meters)", "", @longitude.to_s)
        dlg.set_value(@altitude.to_s)
        if dlg.show_modal() == Wx::ID_OK
            @altitude = dlg.get_value().to_i
        end     
        return nil
      end
    def on_erase_all
	@frame.list2.eraseAll
    end
  def on_file_open(event, variableName, title, wildcards, guess)

    dialog = Wx::FileDialog.new(
                             @frame,
                             variableName,
                             title,
                             "",
                             "",
                             wildcards
                           )
if !@tle_file.nil? && File.exists?(@tle_file) 
	dialog.set_filename(@tle_file)
	else

 if File.exists?(guess)
	     puts guess
    dialog.set_directory(guess)
end
end
    if dialog.show_modal() == Wx::ID_OK
      info = sprintf("Full file name: %s\n" +
                                             "Path: %s\n" +
                                             "Name: %s",
                     dialog.get_path(),
                     dialog.get_directory(),
                     dialog.get_filename())
	puts info 
	@tle_file = dialog.get_path
    end
  end
end


a = DragDropApp.new
exit if Object.const_defined?(:Ocra)
a.main_loop()

