def catlog(i, j, logdir, logfile) 
  print "#{logdir}/#{i}/#{j+1}/#{logfile} : "
  system("cat logs/#{logdir}/#{i}/#{j+1}/#{logfile} |grep \" 200 \" |wc -l ") 
end

ptn = ARGV[1]
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
100.step(500 + 1,100) do |i|
  1..ARGV[0].to_i.times do |j|
    catlog(i, j, logdir, logfile)
  end 
end


