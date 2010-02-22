

class Tle
   @@recordSize = 46
   @@sat_names = {
     7530 => "AO7",
   24278 => "FO29",
   25509 => "SO33",
   27939 => "RS22",
   28650 => "VO52",
   35870 => "SO67",
   36122 => "HO68",
   14781 => "UO11",
   20439 => "AO16",
   20442 => "LO19",
   22825 => "AO27",
   22826 => "IO26",
   25397 => "GO32",
   26931 => "NO44",
   27607 => "SO50",
   27844 => "CO55",
   27848 => "CO57",
   28375 => "AO51",
   28941 => "CO56",
   29655 => "GENST",
   31129 => "CP3",
   32785 => "CO65",
   33493 => "KKS1",
   33496 => "SOHL1",
   16969 => "NOA10",
   19531 => "NOA11",
   21263 => "NOA12",
   21655 => "MET35",
   22782 => "MET21",
   23317 => "OKEN4",
   23455 => "NOA14",
   25338 => "NOA15",
   25394 => "RESRS",
   25730 => "FENGY",
   25860 => "OKEN0",
   26536 => "NOA16",
   27453 => "NOA17",
   28654 => "NOA18",
   33591 => "NOA19",
   20580 => "HUBBL",
   25544 => "ISS",
   28895 => "CO58",
   30776 => "FALCN",
   31126 => "MAST",
   31130 => "CAPE1",
   32787 => "CMPAS",
   32788 => "AAUST",
   32789 => "DO64",
   32791 => "CO66",
   32953 => "RS30",
   35001 => "TAC3",
   35002 => "PHARM",
   35003 => "HAWK1",
   35004 => "CP6",
   35005 => "AERO3",
   35690 => "DRAGN",
   35693 => "POLUX",
   35694 => "CASTR",
   35865 => "METRM",
   35933 => "BEEST",
   35932 => "SWCUB",
   32787 => "COMP",
   35935 => "ITU"
   }
   attr_accessor :YE
   attr_accessor :TE
   attr_accessor :M2
   attr_accessor :IN
   attr_accessor :RA
   attr_accessor :EC
   attr_accessor :WP
   attr_accessor :MA
   attr_accessor :MM
   attr_accessor :RV
   attr_accessor :name
   attr_accessor :modelines
   attr_accessor :id
   def initialize(lineName, lineOne, lineTwo)
     if lineOne[0].chr != '1' || lineTwo[0].chr != '2'
       raise ArgumentError.new("this does not look like TLE input")
     else
       @verbose = false
       @id = lineOne[2..6].to_i
       @YE = lineOne[18..19].to_i + 2000
       @TE = lineOne[20..31].to_f
       @M2 = lineOne[33..42].to_f
       @IN = lineTwo[8..15].to_f
       @RA = lineTwo[17..24].to_f
       @EC = lineTwo[26..32].to_f * 1.0e-7
       @WP = lineTwo[34..41].to_f
       @MA = lineTwo[43..50].to_f
       @MM = lineTwo[52..62].to_f
       @RV = lineTwo[63..67].to_f + 1.0e-6
       if @@sat_names.has_key?(id)
          @name = @@sat_names[id]
          else
       @name = lineName.strip[0..4]
       end
       @modelines = Array.new 
   end
   end
   def Tle.recordSize
     return @@recordSize
   end
   def dumpToBinary
     nameBuffered =  @name + " " * (4 - (@name.length-1))
      incoming = nameBuffered.split(//).push('').push(@YE).push(@TE).push(@M2).push(@IN).push(@RA).push(@EC).push(@WP).push(@MA).push(@MM).push(@RV)
        #puts incoming.inspect
      outgoing = incoming.pack("aaaaaaf*")
      return outgoing
   end
   def dumpToHex
      toHex(dumpToBinary())
   end
   def addModeline(x) 
     @modelines  = @modelines.push(x)
     #remove duplicates
     @modelines.uniq!;
   end
   def dumpModelinesToBinary
     if @modelines.length > 0
     all = String.new
     if @verbose
    # puts @name
     end
     @modelines.each { |modeline|
        if @verbose
     #  puts modeline.modeName
       #puts modeline.inspect
       end
       all << modeline.dumpToBinary()
       }
       return all
     end
     end
   def bytes() 
     return @@recordSize + Modeline.recordSize * @modelines.length
   end
end

class Modeline
   @@recordSize = 28
   @@CW = 0
   @@USB = 1
   @@LSB = 2
   @@FM = 3
   @@FMN = 4
   @@CWN = 5
   @@PKT = 3
   @@NOR = 0
   @@REV = 1
   @verbose = true
   attr_accessor :ulLong
   attr_accessor :dlLong
   attr_accessor :dlMode
   attr_accessor :ulMode
   attr_accessor :polarity
   attr_accessor :ulShift
   attr_accessor :dlShift
   attr_accessor :modeName
   attr_accessor :satAddress
   attr_accessor :satNoradNumber
   #this is the PL tone
   #use 10x the actual value
   attr_accessor :tone 
   def initialize(sqfLine)
     if sqfLine[0].chr == ';'
       raise ArgumentError.new("this is a sqf comment line")
     else
     parts = sqfLine.chomp.split(',')
     puts "parts length: #{parts.length}"
     @satNoradNumber = parts[0].to_i
     @ulLong = parts[1].to_f * 1000#this is wrong order, but it must be wrong in the atmel, too
     @dlLong = parts[2].to_f * 1000
     @dlMode = stringToMode(parts[3])
     @ulMode = stringToMode(parts[4])
     @polarity = stringToPolarity(parts[5])
     @ulShift = parts[6].to_f
     @dlShift = parts[7].to_f
     @modeName = parts[8] || ""
     @tone =     parts[9].to_i || 0
   end
   end
   def Modeline.recordSize() 
     return @@recordSize
   end
   def stringToMode(str)
     case str
     when "CW"
      return @@CW
    when "USB"
      return @@USB
    when "LSB"
      return @@LSB
    when "FM"
      return @@FM
    when "FMN"
      return @@FMN
    when "PKT"
      return @@PKT
    when "CWN"
      return @@CWN
     else
       #throw error here
     end
   end
   
   def stringToPolarity(str)
     case str
     when "NOR"
       return @@NOR
     when "REV"
       return @@REV
     else
       return @@NOR
     end
   end
   
     def dumpToBinary
       modenameOut = @modeName[0..4] + " " * (4 - (@modeName[0..4].length-1))
      incoming = [@satAddress] + modenameOut.split(//).push(@ulLong).push(@dlLong).push(@dlMode).push(@ulMode).push(@polarity).push(@dlShift).push(@ulShift).push(@tone)
      #if @verbose
         puts incoming.inspect
     # end
      return incoming.pack("vaaaaaLLcccffS")
   end
end

def toHex(str)
   0.upto(str.length - 1) do |i|
      ascii_code = str[i]
      dec_str = ascii_code.to_s
      puts "%#04x" % dec_str
   end
end

#some test code
aTle = 'AO-07
1 07530U 74089B   09284.68588776 -.00000027  00000-0  10000-3 0 06037
2 07530 101.4203 305.0610 0012100 040.9512 319.2461 12.53576789597312'
aModeline = 'XW-1,435790,145910,USB,LSB,REV,0,0,CWbcn'
HEADER_SIZE = 4

# t = Tle.new
# lineCounter = 0
# aTle.each_line do |aline|
#    aline.strip
#    #puts aline
#    if aline[0].chr != "1" && aline[0].chr != "2" # new tle
#       t.name = aline[0..4]
#       lineCounter  = 0
#       # puts aline
#    else
#       if lineCounter == 0  && aline[0].chr == "1" # if these are not both true, something's wrong
#          t.YE = aline[18..19].to_i + 2000
#          t.TE = aline[20..31].to_f
#          t.M2 = aline[33..42].to_f
#          lineCounter = 1
#       end
#       if lineCounter == 1 && aline[0].chr == "2"
#          t.IN = aline[8..15].to_f
#          t.RA = aline[17..24].to_f
#          t.EC = aline[26..32].to_f * 1.0e-7
#          t.WP = aline[34..41].to_f
#          t.MA = aline[43..50].to_f
#          t.MM = aline[52..62].to_f
#          t.RV = aline[63..67].to_f + 1.0e-6
#       end
#    end
# end

m = Modeline.new(aModeline)
#print [18,0].pack("vv")
# puts t.inspect
# puts m.inspect
#print t.dumpToBinary





