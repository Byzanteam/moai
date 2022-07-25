# Core Library

[TOC]

## Number

```haskell
-- 求多个数之和
-- n_sum_a([1, 2, 3]) := 6

-- 空数组返回 0
-- n_sum_a([]) := 0
n_sum_a :: [Number] -> Number
```

```haskell
-- 求多个数之积
-- n_product_a([1, 2, 3]) := 6

-- 空数组返回 1
-- n_product_a([]) := 1
n_product_a :: [Number] -> Number
```

```haskell
-- 返回数字的整数部分
-- n_truncate(1.3) := 1
n_truncate :: Number -> Number
```

```haskell
-- 四舍五入；第二个参数指定保留几位小数
-- n_round(3.1415, 0) := 3
-- n_round(3.1415, 1) := 3.2
-- n_round(3.1415, 2) := 3.14
n_round :: Number -> Number -> Number

-- 向下截断；第二个参数指定保留几位小数
-- n_round(3.1415, 0) := 3
-- n_round(3.1415, 1) := 3.1
-- n_round(3.1415, 2) := 3.14
n_floor :: Number -> Number -> Number

-- 向上截断；第二个参数指定保留几位小数
-- n_round(3.1415, 0) := 4
-- n_round(3.1415, 1) := 3.2
-- n_round(3.1415, 2) := 3.15
n_ceil  :: Number -> Number -> Number
```

```haskell
-- 将字符串转换成数字；
-- 支持所有 moai 数字字面值支持的格式；
-- 输入无法解析的字符串时返回 nil
-- n_parse_string("3") := 3
-- n_parse_string("3.0") := 3
-- n_parse_string("3.14") := 3.14
-- n_parse_string("pi") := nil
n_parse_string :: String -> Number | Nil
```

```haskell
-- 将数字转换成字符串
-- n_to_string(3) := "3"
-- n_to_string(3.0) := "3"
-- n_to_string(3.14) := "3.14"
n_to_string :: Number -> String
```

## String

```haskell
-- 拼接任意数量的字符串
-- strcat("foo", "bar", ";") := "foobar;"
-- strcat("foobar;") := "foobar;"
strcat :: String... -> String
str_concat :: String... -> String

-- 拼接字符串数组
-- strcat_a(["foo", "bar", ";"]) := "foobar;"
-- 空数组拼接成空字符串
-- strcat_a([]) := ""
strcat_a :: [String] -> String
str_concat_a :: [String] -> String
```

```haskell
-- 求字符串长度
-- strlen("foobar;") := 7
-- strlen("") := 0
strlen :: String -> Number
str_length :: String -> Number
```

```haskell
-- 求字符串是否包含子字符串？
-- str_contains?("foobar;", "foo") := true
-- str_contains?("foobar;", "oof") := false
str_contains? :: String -> String -> Bool
```

```haskell
-- 将字符串中的子字符串 a 替换为 b
-- str_replace("foobar;", "foo", "oof") := "oofbar;"

-- 如果字符串不包含子字符串，返回原字符串
-- str_replace("foobar;", "oof", "001") := "foobar;"

-- 如果第二个参数为空，返回原字符串
-- str_replace("foobar;", "", "oof") := "foobar;"

-- 如果子字符串出现多次，只会替换第一次出现
-- str_replace("foofoo;", "foo", "oof") := "ooffoo;"
str_replace :: String -> String -> String -> String

-- 和 str_replace 相同，但如果子字符串出现多次，会替换每一次出现
-- str_replace_g("foofoo;", "foo", "oof") := "oofoof;"
str_replace_g :: String -> String -> String
```

```haskell
-- 根据 token 将字符串分割为多个部分
-- str_split("foo,bar,;", ",") := ["foo", "bar", ";"]
-- str_split("foobar;", ";") := ["foobar", ""]
-- str_split(";", ";") := ["", ""]
-- str_split("", ";") := [""]

-- 如果第二个参数为空
-- str_split("foobar;", "") := ["foobar;"]
str_split :: String -> String -> [String]
```

```haskell
-- 将字符串分割为多个字符
-- str_chars("foobar;") := ["f", "o", "o", "b", "a", "r", ";"]
-- str_chars("") := []
str_chars :: String -> [String]
```

```haskell
-- 根据 token 将多个字符串连接为单个字符串
-- str_join(["foo", "bar", ";"], ",") :: "foo,bar,;"
-- str_join(["foo", "bar", ";"], "") :: "foobar;"
str_join :: [String] -> String -> String
```

```haskell
-- 求字符串切片
-- 第二个参数为切片开始座标（座标从 0 开始计数）
-- 第三个参数为切片长度
-- str_slice("foobar;", 2, 3) := "oba"

-- 若切片长度超出字符串长度，则返回最长的切片
-- str_slice("foobar;", 2, 10) := "obar;"

-- 若切片开始座标小于 0，则返回 nil
-- str_slice("foobar;", -1, 2) := nil
str_slice :: String -> Number -> Number -> String | Nil
```

## DateTime

```haskell
-- moai 不存在专门的日期时间类型
-- 日期时间类型被定义为一个具名的 record 类型
-- 并且不存在单独的日期、时间类型
type DateTime = DateTime
  { year   :: Number
  , month  :: Number
  , day    :: Number
  , hour   :: Number
  , minute :: Number
  , second :: Number
  }
```

```haskell
-- 提取日期时间的分量
dt_year   :: DateTime -> Number
dt_month  :: DateTime -> Number
dt_day    :: DateTime -> Number
dt_hour   :: DateTime -> Number
dt_minute :: DateTime -> Number
dt_second :: DateTime -> Number
```

```haskell
-- 给出当时时间；注意这个函数是在运行时生成值的
now :: DateTime
```

```haskell
-- 将一个日期时间增加 n 秒
-- dt_add_seconds(~d"2020-01-01 00:00:00", 60) := ~d"2020-01-01 00:01:00"
-- dt_add_seconds(~d"2020-01-01 00:00:00", -60) := ~d"2019-12-31 23:59:00"
dt_add_seconds :: DateTime -> Number -> DateTime
```

```haskell
-- 求两个日期时间的相差的秒数
-- dt_diff_seconds(~d"2020-01-01 00:01:00", ~d"2020-01-01 00:00:00") := 60
-- dt_diff_seconds(~d"2020-01-01 00:00:00", ~d"2020-01-01 00:01:00") := -60
-- dt_diff_seconds(~d"2020-01-01 00:00:00", ~d"2020-01-01 00:00:00") := 0
dt_diff_seconds :: DateTime -> DateTime -> Number
```

## Bool

```haskell
-- 求多个 Bool 值相「与」的结果
-- bool_and([true, true, true]) := true
-- bool_and([true, false, true]) := false

-- 空数组返回 true
-- bool_and([]) := true
bool_and :: [Bool] -> Bool
```

```haskell
-- 求多个 Bool 值相「或」的结果
-- bool_or([false, false, false]) := false
-- bool_or([true, false, true]) := true

-- 空数组返回 false
-- bool_or([]) := false
bool_or :: [Bool] -> Bool
```

## Array

```haskell
-- 求数组中位于下标 n 的元素（下标从 0 计数）
-- array_at([1, 2, 3], 1) := 2

-- 下标是负数或者超出数组范围时返回 nil
-- array_at([1, 2, 3], -1) := nil
-- array_at([1, 2, 3], 10) := nil

-- 需要注意该函数返回 nil 时并不总是上面的原因引起的，
-- 因为数组中可能含有 nil
-- array_at([1, nil, 3], 1) := nil

array_at :: Number -> [a] -> a | Nil
```

```haskell
-- 求数组长度
-- array_length([1, 2, 3]) := 3
-- array_length([]) := 0
array_length :: [a] -> Number
```

```haskell
-- 求数组中是否包含元素？
-- array_contains?([1, 2, 3], 1) := true
-- array_contains?([1, 2, 3], 4) := false

-- 注意该函数不被 nil 短路
-- array_contains?([1, nil, 3], nil) := true
-- array_contains?([1, 2, 3], nil) := false
array_contains? :: a -> [a] -> Bool
```

```haskell
-- 求第一个参数是否是第二个参数的子集？
-- array_subset?([1, 2], [1, 2, 3]) := true
-- array_subset?([1, 2, 3], [1, 2, 3]) := true

-- 顺序无关
-- array_subset?([3, 2], [1, 2, 3]) := true

-- 重复元素会被当成只出现过一次
-- array_subset?([1, 1, 1], [1, 2]) := true

-- 因此由「a 是 b 的子集并且 b 是 a 的子集」并不能得出
-- 「a 等于 b」这个结论
-- array_subset?([1, 1, 1], [1, 1]) := true
-- array_subset?([1, 1], [1, 1, 1]) := true

-- 即使附加「数组长度相同」这一条件，仍然无法得出
-- array_subset?([1, nil, nil], [1, 1, nil]) := true
-- array_subset?([1, 1, nil], [1, nil, nil]) := true

-- 空数组是任意数组的子集
-- array_subset?([], [1, 2, 3]) := true
-- array_subset?([], []) := true
array_subset? :: [a] -> [a] -> Bool
```

```haskell
-- 求两数组是否互斥？（不共享任意元素）
-- array_disjoint?([1, 2], [2, 3]) := false
-- array_disjoint?([1, 2], [3, 4]) := true

-- 空数组与任意数组互斥
-- array_disjoint?([], [1, 2]) := true
-- array_disjoint?([], []) := true
array_disjoint? :: [a] -> [a] -> Bool
```

```haskell
-- 拼接两个数组
-- array_concat([1, 2], [3, 4]) := [1, 2, 3, 4]
array_concat :: [a] -> [a] -> [a]
```

```haskell
-- 数组去重
-- array_uniq([1, 2, 3, nil, nil, 3, 2, 4]) := [1, 2, 3, nil, 4]
array_uniq :: [a] -> [a]
```

```haskell
-- 求数组交集；交集中元素的顺序与第一个参数的顺序相同
-- array_intersection([1, 2, 3], [3, 2, 4]) := [2, 3]
-- array_intersection([1, 2], [3, 4]) := []
array_intersection :: [a] -> [a] -> [a]
```

## Miscellaneous

```haskell
-- 求参数是否为 nil？
is_nil? :: a -> Bool
```

```haskell
-- 返回第一个不是 nil 的参数
-- coalesce(nil, 1, 2) := 1
-- coalesce(nil, nil, nil) := nil
coalesce :: a... -> a | Nil
```

## Techniques & Tips

```elixir
if(
  Enum.all?(nums, & &1 > 10),
  do: "good",
  else: "bad"
)
```
可以翻译为
```
if(
  bool_and(for n in nums -> n > 10),
  "good",
  "bad"
)
```
