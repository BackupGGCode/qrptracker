require 'burnTleNums'
require 'open-uri'
require 'tempfile'

class TleCollection
  
  attr_accessor :modelines
  attr_accessor :tles
  attr_accessor :byteCount
  attr_accessor :numberForBytes
  attr_accessor :bad_tles
  attr_accessor :modelineCount
  #parse the SQF file
  def initialize
    @verbose = true
    @HEADER_SIZE = 15
    @modelines = Array.new
    @tles = Array.new
    @byteCount = 0
    @numberForBytes = 0
  end
  def loadFromWeb(sqf_file, verbose)
    @modelines = Array.new
    @tles = Array.new
    @byteCount = 0
    @numberForBytes = 0
    f = File.open(sqf_file, mode="r")
    f.readlines.each do |line|
       begin
          m = Modeline.new(line)
          @modelines.push(m)
       rescue
       puts "ERROR: modeline rejected in #{sqf_file}: #{line}"
       end
    end
    #parse the TLE file
    lineCounter = 0
    firstLine = secondLine = ""
    f = Tempfile.new("celes")
    tlesites = ["http://www.celestrak.com/NORAD/elements/amateur.txt","http://www.celestrak.com/NORAD/elements/cubesat.txt", "http://www.celestrak.com/NORAD/elements/noaa.txt"]
    tlesites.each do |tlesite| 
      freshTles = open(tlesite, 'User-Agent' => 'Ruby-Wget').read
      #if @verbose
       puts("generated new TLE file: #{f.path()}");
      #  Wx::log_message(freshTles) 
      #end
      f.puts(freshTles)
    end
    f.close
    f.open
    f.readlines.each do |line|
      if line[0].chr == '2' && lineCounter == 2
         t = Tle.new(firstLine,secondLine,line)
         if @verbose
            Wx::log_message(t.inspect)
         end
         @tles.delete_if {#get rid of previously installed tle if it has the same id
           |tle|
           tle.id == t.id
         }
         @tles.push(t)
         lineCounter = 0
      elsif lineCounter == 0
         firstLine = line
         lineCounter = lineCounter + 1
      elsif lineCounter == 1
         secondLine = line
         lineCounter = lineCounter + 1
      end
    end
    @tles.each_index{|x|
      #if @verbose
        Wx::log_message( "satellite #{x} is #{@tles[x].name}")
       #end
       @modelines.each{|modeline|
          if modeline.satNoradNumber == @tles[x].id
             if @verbose
               puts "modeline #{modeline.modeName} goes with #{@tles[x].name}"
                puts "whose address is #{@HEADER_SIZE +(x * Tle.recordSize)}"
                puts Tle.recordSize
                puts x
              end
             modeline.satAddress = @HEADER_SIZE + x * Tle.recordSize
             
             @tles[x].addModeline(modeline)
          end
       }
       if @verbose
          puts @tles[x].name
          puts @tles[x].bytes
       end
    }
    #store those that have no modeline so that we can warn about them later
    @bad_tles = @tles.select{|tle| tle.modelines.length == 0}
    #omit those tles that have no modeline
    @tles = @tles.reject {|tle| tle.modelines.length == 0}

        #associate all the tles with their modelines
   alignModelines
  end

  def alignModelines 
     @tles.each_index{|x|
      if @verbose
        puts "satellite #{x} is #{@tles[x].name}"
      end
       @tles[x].modelines.each{|modeline|
             modeline.satAddress = 15 + x * Tle.recordSize

       }
    }
    end
  
  def toSize(bytes)
    #make a collection of tles and their modelines that goes up to but not
    #beyond the bytes assigned on the command line
    modelineCount = byteCount = 0
    i = -1
    while (i+1) < @tles.length && (byteCount + @tles[i+1].bytes) < (bytes - HEADER_SIZE)
       i = i +1
       byteCount = byteCount + @tles[i].bytes
       modelineCount = modelineCount + @tles[i].modelines.length
    end
    @numberForBytes = i
    @byteCount = byteCount
    @modelineCount = modelineCount
  end
  def orderTles(ordering)
    #do something with this input array of ids to order the tles
  end

  def binaryDump()
    #otherwise start creating the binary file
    binaryData = String.new
      #first put in two-byte number indicating number of tles
    puts("numberfor bytes: #{@numberForBytes +1}");
    binaryData << [@numberForBytes+1].pack("v");
       #next, put in two-byte number indicating number of modelines
    puts("modelinecount: #{@modelineCount}");
    binaryData << [@modelineCount].pack("v")
  
 
    #now, put in all the tles
    @tles[0..@numberForBytes].each {|tle|
       binaryData  << tle.dumpToBinary
    }
    if @verbose
    
      puts "dumping modelines"
    end
    #now add all the modelines
    @tles[0..@numberForBytes].each {|tle|
       if @verbose 
        puts "dump modelines for #{tle.name}"
       end
       binaryModelines = tle.dumpModelinesToBinary
       unless binaryModelines == nil
          binaryData  << binaryModelines #tle.dumpModelinesToBinary
       end
    }
    return binaryData
  end
  def print() 
    tles[0..tles.length].each_index {|x|
         puts "#{x+1}: #{tles[x].name}"
       @tles[x].modelines.each {|modeline|
          puts "\t#{modeline.modeName} #{modeline.ulLong} / #{modeline.dlLong}"
       }
    }
  end
end
