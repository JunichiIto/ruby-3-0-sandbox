COUNT = 9

# 1秒未満のsleepを入れてその秒数を返すメソッド
# （時間がかかる何らかの処理をシミュレートする）
def work
  n = rand
  sleep(n)
  n
end

# Ractorを使う場合
# http://www.atdot.net/~ko1/activities/2020_ruby3summit.pdf を参考にして実装
def with_ractor
  rs = (1..COUNT).map do |i|
    Ractor.new(i) do |i|
      [i, work]
    end
  end

  until rs.empty?
    r, (i, result) = Ractor.select(*rs)
    rs.delete r
    puts format_result(i, result)
  end
end

# 単純にループする場合
def without_ractor
  (1..COUNT).map do |i|
    result = work
    puts format_result(i, result)
  end
end

# 実行結果をフォーマットするメソッド
def format_result(i, result)
  "no.%d, sleep: %.2f" % [i, result]
end

# 起動時引数が0ならRactorなし、それ以外はRactorありで実行
if ARGV[0] == '0'
  without_ractor
else
  with_ractor
end
