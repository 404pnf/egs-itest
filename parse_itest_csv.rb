# -*- coding: utf-8 -*-
require 'csv'
require 'pp'
#require 'smarter_csv'

input = ARGV[0]
csv = CSV.read(input, :headers => true)
# csv的每一条记录不是array它的class是CSV::Row
# 需要先变为array 开始Hash[*array]总是报奇数项目就是因为这个出错误
# 因为CSV::Row本身就带这headre信息，还带有一个行号信息。正式这个行号信息让元素变为了奇数
hash = csv.map {|e| Hash[*e.to_a.flatten]}
p "题目数： #{hash.size}"
id = rand(hash.size)
pp "随机显示 #{id} :   #{hash[id]}"



#csv = CSV.read(input)
#header, body= csv.first, csv.drop(1) # csv.shift will change csv so abandon it
#pp header
#pp csv
#pp body[10]
#somebody = body[0..10]
#hash = body.map {|row| Hash[*row]} # beaufifu! :)
#hash = somebody.map {|row| Hash[*row]} # beaufifu! :)
#arr = body.map {|row| header.zip row}
#hash = arr.map {|e| Hash[*e.flatten]}
#pp hash[1000]
#pp hash.size
=begin
#hash = body.map {|row| Hash[*(header.zip row)]} # beaufifu! :) 
#since we parse the csv with hdear, we don't need to zip the header in
#looks like an ruby 2.0 improvment

# csv to hash
# ref: https://github.com/tilo/smarter_csv
# ref: http://stackoverflow.com/questions/4420677/storing-csv-data-in-ruby-hash
#question_hash = SmarterCSV.process('cet20130321.csv')
#small_hash = question_hash[0..13]
#pp small_hash
# turn csv to hash, my way
# too verbose
csv = CSV.read('cet20130321.csv', :headers => true,)
p "number of questions: #{csv.size}"
t = csv[3]
pp t
tt= t.map {|e| 
  h={}; 
  h[:exam_type], h[:egs_tag], h[:question_type], h[:basic_type], h[:direction], h[:choice_and_help] = e[0..5] ;
  h[:question], h[:correct_answer_and_help], h[:choice_is_random], h[:dependency] = e[6..9] ;
  h[:sub_question_random], h[:resource_uri] = e[10..-1] ;
  h
}
#pp tt
#Hash[*CSV.read(filename, :headers => true).flat_map.with_index{|r,i| ["rec#{i+1}", r.to_hash]}]
#hash = Hash[*t.flat_map.with_index{|r,i| ["rec#{i+1}", r.to_hash]}]
#pp hash
#pp tt
=end
