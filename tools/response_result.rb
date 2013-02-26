# -*- coding: utf-8 -*-
require 'pp'

#変数
mark = "====="
logname = "stdout1.log"

#データ格納
data = {"ptn1" => {},"ptn4" => {},"ptn5" => {}}
data.each_key do |ptn|
  Dir::glob("#{ptn}/*/#{logname}").each do |path|
    no = path.gsub(ptn+"/","").gsub("/" + logname,"")
    data[ptn][no] = {}
    flag = false
    open(path) do |f|
      f.each do |line|
        if flag && line =~ /(\d+):\s(\d+)\.\d+/
          data[ptn][no][$1] = $2.to_i
        end
        if ! flag && line.chop == mark
          flag = true
        elsif flag && line.chop == mark
          flag = false
        end
      end
    end
  end
end

puts "データ"
pp data

#データ集計
max_time=0
result = {"ptn1" => {},"ptn4" => {},"ptn5" => {}}
data.each_pair do |ptn_name,ptn|
  ptn.each_value do |n|
    n.each_value do |time|
      if result[ptn_name][time].nil?
        result[ptn_name][time] = 1
      else
        result[ptn_name][time] += 1
      end
      max_time = time if time > max_time
    end
  end
end

puts "集計結果"
pp result

#CSVデータ作成
csv = []
for time in (0..max_time)
  csv[time] = []
  result.each_pair do |ptn_name,ptn|
    if ptn[time].nil?
      csv[time] << 0
    else
      csv[time] << ptn[time]
    end
  end
end

#CSV印字
puts "CSV出力"
puts "," +  result.keys.join(",")
csv.each_with_index do | row,i |
  puts i.to_s + "," + row.join(",")
end
