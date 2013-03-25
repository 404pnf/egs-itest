# -*- coding: utf-8 -*-
require 'csv'
require 'pp'


DEBUG = nil
input = ARGV[0]
csv = CSV.read(input, :headers => true)
# csv的每一条记录不是array它的class是CSV::Row
# 需要先变为array 开始Hash[*array]总是报奇数项目就是因为这个出错误
# 因为CSV::Row本身就带这headre信息，还带有一个行号信息。正式这个行号信息让元素变为了奇数
hash = csv.map {|e| Hash[*e.to_a.flatten]} # an arry of hashes
pp "题目数： #{hash.size}" 
id = rand(hash.size) if DEBUG
pp "随机显示 #{id} :  original csv_hash #{hash[id]}" if DEBUG

# step 1
# add keys
# 序号；考点；分值；时间限制；填空题输入大小
step_1 = hash.map { |h| 
  %w(egs-序号 egs-考点 egs-分值 egs-时间限制 egs-填空题输入大小).each { |key| h[key] = nil}
  h}
pp "step 1:  #{step_1[id]}" if DEBUG

# step_2 
# 复制能重复使用的内容到新的keys中
step_2 = step_1.map { |h|
  %w(题型 试卷类别 基本题型 选项与解析 是否依赖上级父题目 子题目是否可以随机出现 选项与解析 Directions材料题干 Egs对应标签题型).each {|word| h["egs-#{word}"] = h["#{word}"]}
  h
}
pp "step 2:  #{step_2[id]}" if DEBUG

# step_3
# 增加key: '标题'
# 增加一列：命名规则：试卷类别+”-”+ egs对应标签题型+”-”+基本题型  （英文连字符连接）
step_3 = step_2.map {|h|
  h['egs-标题'] = "#{h['试卷类别']}-#{h['egs-Egs对应标签题型']}-#{h['基本题型']}"
  h
}
pp "step 3:  #{step_3[id]}" if DEBUG

# step 4
# 处理选项吧
# input "选项与解析"=>"inept_|_inflexible_|_influential_|_adept,3",
# output "egs-选项与解析"=>"0--inept&&0--inflexible&&0--influential&&1--adept",
# 
# csv结构中，选项之间分隔符为”_|_”，正确答案的数组编号（从0开始）与选项之间分隔符为 “||”
# 需要拼成的EGS目标列的规则为：
# egs
# 其中“0--” 表示错误答案；“1--” 表示正确答案；
# “&&”为选项分隔符，最后一个选项后面不出现；
# “||”为解析内容与选项之间的分隔符，只有正确答案才跟解析
# in key: "正确答案解析"
# 注意：不能改变原有顺序
step_4 = step_3.map { |h|
  answers, correct_id = h['egs-选项与解析'].split(/,/)
  #id = correct_id.to_i 这里的id会覆盖最上面random出的id?!
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
  h
}
pp "step 4:   #{step_4[id]}" if DEBUG

# final step
# write out the csv
final_hash = step_4.each {|h| h.keep_if {|k, _| k =~ /egs/}; h.keys.sort }
arr_of_csv = final_hash.map { |h|
  h.values.to_csv(:force_quotes => true)# beautiful!
}
pp "final_csv_arr:  #{arr_of_csv[id]}" if DEBUG
headers = final_hash[0].keys.join(',')
final_csv_str = ''
final_csv_str << headers << "\n" << arr_of_csv.join # arr_of_csv already has "\n" at the end of each record
File.write('out-simple.csv', final_csv_str)
