#! /usr/bin/env ruby


def readAnnotRastFile(infile)
  famInfo = Hash.new
  in_fh = File.open(infile, 'r')
  in_fh.each_line do |line|
    line.chomp!
    #OG0000000	Afifella_pfennigii_DSM_17143|Q331_RS0101915	ABC transporter ATP-binding protein	Carbohydrates	Sugar alcohols	Glycerol_and_Glycerol-3-phosphate_Uptake_and_Utilization	cl28181	ATPases associated with a variety of cellular activities. Members of this family are ATP-binding cassette (ABC) proteins by homology, but belong to energy coupling factor (ECF) transport systems. The architecture in general is two ATPase subunits (or a double-length fusion protein), a T component, and a substrate capture (S) component that is highly variable, and may be interchangeable in genomes with only one T component. This model identifies many but not examples of the downstream member of the pair of ECF ATPases in Firmicutes and Mollicutes. [Transport and binding proteins, Unknown substrate]
    line_arr = line.split("\t")
    fam = line_arr[0]
    famInfo[fam] = FAM.new
    famInfo[fam].func_abbr = line_arr[2]
    famInfo[fam].func = line_arr.values_at(1,3,4,5,6,7).join("\t")
  end
  in_fh.close
  return(famInfo)
end


