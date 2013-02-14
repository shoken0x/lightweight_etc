# encoding:UTF-8
require 'win32ole'

def to_absolute_path(filename)
	fso = WIN32OLE.new('Scripting.FileSystemObject')
	fso.GetAbsolutePathName(filename)
end

def create_workbook(filename)
	begin
		excel = WIN32OLE.new('Excel.Application')
		WIN32OLE.const_load(excel, ExcelConstants)
		book = excel.workbooks.add
		yield(excel, book)
	ensure
		book.saveAs(to_absolute_path(filename))
		book.close
		excel.quit
	end
end

def c(column)
	_1 = column / 26
	_2 = column % 26
	
	return (64 + _2).chr if _1 <= 0
	return (64 + _1).chr + (64 + _2).chr
end

class ExcelConstants; end

class NetstatRecord
	attr_reader :datetime, :protocal, :send_q, :recieve_q, :from_ip, :to_ip, :status, :process_id

	def initialize(datetime, tokens)
		@datetime   = datetime
		@protocal   = tokens[0]
		@send_q     = tokens[1]
		@recieve_q  = tokens[2]
		@from_ip    = tokens[3]
		@to_ip      = tokens[4]
		@status     = tokens[5]
		@process_id = tokens[6]
	end
	
	def key
		[@process_id, @status]
	end
end

class NetstatSummary
	def initialize
		@counter = {}
	end
	
	def increment(record)
		return if record.key[0] == "-"
		
		@counter[record.key] = 0 unless @counter.include?(record.key)
		@counter[record.key] += 1
	end
	
	def each
		@counter.each { |key, count|
			yield(key, count)
		}
	end
	
	def [](key)
		@counter[key] || 0
	end

end





### Excel出力
create_workbook('NETSTATグラフ.xlsx') { |excel, book|
	1.upto(ARGV.length) { |index|

		### 行読み取り
		datetime, records = nil, []
		File.readlines(ARGV[index - 1]).each { |line|
			if line =~ /^-----  (.+)/
				datetime = $1.to_s
				next
			end
			
			records << NetstatRecord.new(datetime, line.split(' '))
		}
		
		### 集計
		summaries = {}
		records.each { |record|
			summaries[record.datetime] = NetstatSummary.new unless summaries.include?(record.datetime)
			
			summaries[record.datetime].increment(record)
		}
		
		### header行
		header = []
		summaries.each { |datetime, summary|
			summary.each { |key, count|
				header << key
			}
		}
		header.uniq!
    
		### Excel出力
		sheet = book.sheets.add(:After =>  book.sheets(book.sheets.count))
		sheet.name = "netstat%02d" % index
		
		### header
		sheet.range("B1:#{c(header.length + 1)}1").value =
			header.sort { |a, b| a[0].split(/\//)[1] + a[1] <=> b[0].split(/\//)[1] + b[1] }.map { |key| key[0] + " " + key[1] }
		
		### body
		row_index = 2
		summaries.each { |datetime, summary|
			sheet.cells(row_index, 1).value = datetime
			header.each_with_index { |key, i|
				sheet.cells(row_index, i + 2).value = summary[key]
			}
			
			row_index += 1
		}
		
		### 整形
		# header
		sheet.rows("1:1").HorizontalAlignment = ExcelConstants::XlCenter
		sheet.rows("1:1").VerticalAlignment   = ExcelConstants::XlCenter
		sheet.rows("1:1").Orientation         = 90
		
		# cell幅
		sheet.columns("A:A").EntireColumn.AutoFit
		sheet.cells.EntireColumn.AutoFit
		
		### グラフ
		# チャート作成
		sheet.Shapes.AddChart
		chart = sheet.ChartObjects(1).Chart
		chart.ChartType = ExcelConstants::XlXYScatterLines
		sheet.ChartObjects(1).Width, sheet.ChartObjects(1).Height = 720, 400
		chart.PlotArea.Top, chart.PlotArea.Left, chart.PlotArea.Width, chart.PlotArea.Height = 50, 10, 590, 300
		
		# タイトル
		chart.HasTitle = true
		chart.ChartTitle.Text = "Netstat"
		
		# 凡例
		
		# Y1軸
		chart.Axes(ExcelConstants::XlValue).HasTitle = true
		chart.Axes(ExcelConstants::XlValue).AxisTitle.Text = "コネクション数"
		chart.Axes(ExcelConstants::XlValue).TickLabels.NumberFormatLocal = "#,##0"
		
		# X軸
		chart.Axes(ExcelConstants::XlCategory).MajorUnit = 1.0 / 24.0
	}
}

