unless ARGV.size == 3
  puts "Usage: #{$0} <path to logdir> <trials> <ptn1, ptn4 or ptn5>"
  puts "Sample: #{$0} /opt/result/2013-02-22-150000 12 ptn5"
  puts ""
  exit 1
end

def catlog(i, j, basedir, logdir, logfile) 
  print "#{logdir}/#{i}/#{j+1}/#{logfile} : "
  system("cat #{basedir}/logs/#{logdir}/#{i}/#{j+1}/#{logfile} |grep \" 200 \" |wc -l ") 
end

basedir = ARGV[0]
trials = ARGV[1]
ptn = ARGV[2]

logdir = "ptn1/apache"
logfile = "access_log"

if ptn == "ptn1"
  logdir = "ptn1/apache"
  logfile = "access_log"
elsif ptn == "ptn4"
  logdir = "ptn4/nginx"
  logfile = "access.log"
elsif ptn == "ptn5"
  logdir = "ptn5/nginx"
  logfile = "access.log"
end

## main
100.step(300 + 1,100) do |i|
  1..trials.to_i.times do |j|
    catlog(i, j, basedir, logdir, logfile)
  end 
end


