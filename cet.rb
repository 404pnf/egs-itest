# -*- coding: utf-8 -*-

require 'csv'
require 'pp'

DEBUG = true

# stdlib zlib adler32 generate a checksum with numbers only
# Zlib::adler32(str)
# ref: http://www.ruby-doc.org/stdlib-2.0/libdoc/zlib/rdoc/Zlib.html#method-c-adler32
# http://en.wikipedia.org/wiki/Adler-32

input = ARGV[0]
csv = CSV.read(input, :headers => true)
# csv的每一条记录不是array它的class是CSV::Row
# 需要先变为array 开始Hash[*array]总是报奇数项目就是因为这个出错误
# 因为CSV::Row本身就带这headre信息，还带有一个行号信息。正式这个行号信息让元素变为了奇数
hash = csv.map {|e| Hash[*e.to_a.flatten]} # an arry of hashes
pp "题目数： #{hash.size}"
id = rand(hash.size) if DEBUG
pp "随机显示 #{id} :" if DEBUG
pp "orig csv_hash:    #{hash[id]}" if DEBUG

# step 1
# add keys
# 序号；考点；分值；时间限制；填空题输入大小
step_1 = hash.map { |h| 
  %w(egs-序号 egs-考点 egs-分值 egs-时间限制 egs-填空题输入大小).each { |key| h[key] = nil}
  h['egs-序号'] = h['id']
  h['egs-父级题目id'] = h['father_id']
  h['egs-Directions材料题干'] = h['Directions材料题干']
  h}
pp "step 1:"  if DEBUG
pp step_1[id] if DEBUG

# step 2
# add 标题 
# 增加一列：命名规则：试卷类别+”-”+ egs对应标签题型+”-”+基本题型  （英文连字符连接）
step_2 = hash.map { |h| 
  h['egs-标题'] = [ h['试卷类别'], h['Egs对应标签题型'], h['基本题型'] ].join('-'); 
  %w(Egs对应标签题型 题型 基本题型 选项是否随机出现 是否依赖上级父题目 子题目是否可以随机出现 Directions材料题干 资源地址).each {|word| h["egs-#{word}"] = h[word]}

  h}
pp "step 2:"  if DEBUG
pp step_2[id] if DEBUG

# step 3
# 选项与解析
# 父题（既父级题目id为空的）：
# 对应EGS目标列“选项与解析”，但要扫描下csv中的“题干”，如果题干内容在“选项与解析”中有，则直接使用“选项与解析”中的内容。
# 否则为csv文件的“选项与解析”+“题干”

# 子题（既父级题目id不为空的）：
# csv结构中，'选项与解析' ->  选项之间分隔符为”_|_”，正确答案的数组编号（从0开始）与选项之间分隔符为 “||”
# 需要拼成的EGS目标列的规则为：

# 选项状态值+”--”+选项+*[“||”+解析]+”&&”
# 选项状态值：
# 其中“0--” 表示错误答案；“1--” 表示正确答案；
# “&&”为选项分隔符，最后一个选项后面不出现；
# “||”为解析内容与选项之间的分隔符，只有正确答案才跟解析
# 注意：不能改变原有顺序

# step 3
# 更新父级题目id不为空的 '选项与解析' --> 'egs选项与解析'
# 例子 
# "Because she has got an appointment_|_Because she doesn’t want to_|_Because she has to work_|_Because she wants to eat in a new restaurant||2"

# step_2.each {|h| p h["father_id"].class} # 证明father_id即使为空也只是空字符串
# step_2.each {|h| p h["选项与解析"] if h["father_id"] != ''} # 证明father_id即使为空也只是空字符串
step_3 = step_2.map {|h|
  if !h["father_id"].empty?
    answers, correct_id = h['选项与解析'].split('||')
    correct_id = correct_id.to_i
    explanation = h['正确答案解析']
    egs_choices = []
    answers.split('_|_').each_with_index {|choice, idx|
      if idx == correct_id
        if explanation.nil? or  explanation.empty?
          egs_choices << "1--#{choice}"
        else
          egs_choices << "1--#{choice}||#{explanation}"
        end
      else
        egs_choices << "0--#{choice}"
      end
    }
    egs_choices_str = egs_choices.join('&&')
    h['egs-选项与解析'] = egs_choices_str
  end
  if h["father_id"].empty?
    answers, correct_id = h['选项与解析'].split('||')
    correct_id = correct_id.to_i
    explanation = h['正确答案解析']
    tigan = h['题干']
    egs_choices = []
    answers.split('_|_').each_with_index {|choice, idx|
      if idx == correct_id
        if explanation or  explanation.empty?
          egs_choices << "1--#{choice}"
        elsif explanation.include? tigan
          egs_choices <<  "1--#{choice}||#{explanation}"     
        else 
          egs_choices << "1--#{choice}||#{explanation} #{tigan}"
        end
      else
        egs_choices << "0--#{choice}"
      end
    }
    egs_choices_str = egs_choices.join('&&')
    h['egs-选项与解析'] = egs_choices_str
  end
  h
}

#pp step_3[4530] if DEBUG
#pp step_3[1862] if DEBUG
#pp "检查选项与解析"
pp step_3[id] if DEBUG

# final step
# keep egs keys only
final_hash = step_3.each {|h|
  h.keep_if {|k,_| k =~ /egs/}
  h
}
pp final_hash[id] if DEBUG
headers = final_hash[0].keys.join(',')
arr_of_csv = final_hash.map {|h|
  h.values.to_csv(:force_quotes => true)
}
pp arr_of_csv[id] if DEBUG
final_csv_str = ''
final_csv_str << headers << "\n" << arr_of_csv.join # arr_of_csv already has "\n" at the end of each record
File.write('out-cet.csv', final_csv_str)

# ref: http://stackoverflow.com/questions/4420677/storing-csv-data-in-ruby-hash

