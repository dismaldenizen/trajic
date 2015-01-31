#!/usr/bin/env ruby

require './common'

check_for_executables!

DATA_ROOT = "/home/aiden/Data/Trajectories/Geolife/Data"
#DATA_ROOT = "/home/aiden/Data/Trajectories/Illinois"

config = {
  :n          => :all,
  :algorithm  => "dp",
}

files = []
Find.find(DATA_ROOT) do |path|
  if FileTest.file? path and path.end_with? ".plt"
    files << path
  end
end

unless config[:n].nil? or config[:n] == :all
  files = files[0...config[:n]]
end

checkpoint = 0.1 * files.length
usize = 0.0
csize = 0.0
n_trajs = 0
compr_time = 0.0
decompr_time = 0.0
max_error_kms = 0.0
files.each_with_index do |path, i|
  if i >= checkpoint
    checkpoint += 0.1 * files.length
    print "."
    $stdout.flush
  end
  
  # Error approx 1 s and 1 m
  #io = IO.popen("./stats #{config[:algorithm]} '#{path}' 1 0.00001")
  io = IO.popen("./stats #{config[:algorithm]} '#{path}' 0 0.00028")
  #io = IO.popen("./stats #{config[:algorithm]} '#{path}'")
  lines = io.readlines
  io.close

  unless lines.empty?
    results = {}
    lines.each do |line|
      key, val = *line.split("=")
      results[key] = val.strip
    end
  
    usize += results["raw_size"].to_i
    csize += results["compr_size"].to_i
    compr_time += results["compr_time"].to_i
    decompr_time += results["decompr_time"].to_i
    
    error_kms = results["max_error_kms"].to_f
    max_error_kms = error_kms if error_kms > max_error_kms
    
    n_trajs += 1
  end
end

puts "."
puts "Max error: #{max_error_kms * 1000} m"
puts "Compression ratio: #{csize / usize}"
puts "Average compression time: #{compr_time / n_trajs / 1000} ms"
puts "Average decompression time: #{decompr_time / n_trajs / 1000} ms"
