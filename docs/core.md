# Core Libraries

[TOC]

## Number

```haskell
-- 求多个数之和
-- sum_a([1, 2, 3]) := 6

-- 空数组返回 0
-- sum_a([]) := 0

-- 性质
-- sum_a(xs) + sum_a(ys) == sum_a(Array.concat(xs, ys))
sum_a :: [Number] -> Number
```

```haskell
-- 求多个数之积
-- product_a([1, 2, 3]) := 6

-- 空数组返回 1
-- product_a([]) := 1

-- 性质
-- product_a(xs) * product_a(ys) == product_a(Array.concat(xs, ys))
product_a :: [Number] -> Number
```

```haskell
-- 返回数字的整数部分
-- truncate(1.3) := 1
-- truncate(-1.3) := -1
truncate :: Number -> Number
```

```haskell
-- 四舍五入；第二个参数指定保留几位小数
-- round(3.1415, 0) := 3
-- round(3.1415, 1) := 3.1
-- round(3.1415, 3) := 3.142
-- round(3.1415, -3) := nil
-- round(3.1415, 3.1) := nil
round :: Number -> Number -> Number

-- 向下截断；第二个参数指定保留几位小数
-- floor(3.1415, 0) := 3
-- floor(3.1415, 1) := 3.1
-- floor(3.1415, 2) := 3.14
-- floor(-3.1415, 3) := -3.142
-- floor(3.1415, 3.1) := nil
-- floor(3.1415, -3) := nil
floor :: Number -> Number -> Number

-- 向上截断；第二个参数指定保留几位小数
-- ceil(3.1415, 0) := 4
-- ceil(3.1415, 1) := 3.2
-- ceil(3.1415, 2) := 3.15
-- ceil(-3.1415, -3) := 3.141
-- ceil(3.1415, 3.1) := nil
-- ceil(3.1415, -3) := nil
ceil  :: Number -> Number -> Number
```

```haskell
-- 将字符串转换成数字；
-- 支持所有 moai 数字字面值支持的格式；
-- 输入无法解析的字符串时返回 nil
-- parse_string("3") := 3
-- parse_string("3.0") := 3.0
-- parse_string("3.14") := 3.14
-- parse_string("pi") := nil
parse_string :: String -> Number
```

```haskell
-- 将数字转换成字符串
-- to_string(3) := "3"
-- to_string(3.0) := "3"
-- to_string(3.14) := "3.14"
to_string :: Number -> String
```

## String

```haskell
-- 拼接两个字符串
-- strcat("foo", "bar") := "foobar"
strcat :: String -> String -> String

-- 拼接字符串数组
-- strcat_a(["foo", "bar", ";"]) := "foobar;"
-- 空数组拼接成空字符串
-- strcat_a([]) := ""
-- strcat_a(["foo", "bar", nil]) := nil
strcat_a :: [String] -> String
```

```haskell
-- 求字符串长度
-- length("foobar;") := 7
-- length("魁拔😀") := 3
-- length("") := 0
length :: String -> Number
```

```haskell
-- 求字符串是否包含子字符串？
-- contains?("foobar;", "foo") := true
-- contains?("foobar;", "oof") := false
-- contains?("foobar;", "") := true
contains? :: String -> String -> Bool
```

```haskell
-- 将字符串中的子字符串 a 替换为 b
-- replace("foobar;", "foo", "oof") := "oofbar;"

-- 如果字符串不包含子字符串，返回原字符串
-- replace("foobar;", "oof", "001") := "foobar;"

-- 如果第二个参数为空，返回原字符串
-- replace("foobar;", "", "oof") := "foobar;"

-- 如果子字符串出现多次，只会替换第一次出现
-- replace("foofoo;", "foo", "oof") := "ooffoo;"
replace :: String -> String -> String -> String

-- 和 replace 相同，但如果子字符串出现多次，会替换每一次出现
-- replace_g("foofoo;", "foo", "oof") := "oofoof;"
replace_g :: String -> String -> String
```

```haskell
-- 根据 token 将字符串分割为多个部分
-- split("foo,bar,;", ",") := ["foo", "bar", ";"]
-- split("foobar;", ";") := ["foobar", ""]
-- split(";", ";") := ["", ""]
-- split("", ";") := [""]
-- split("foo", "") := ["", "f", "o", "o", ""]
split :: String -> String -> [String]
```

```haskell
-- 将字符串分割为多个字符
-- chars("foobar;") := ["f", "o", "o", "b", "a", "r", ";"]
-- chars("魁拔😀") := ["魁", "拔", "😀"]
-- chars("") := []
chars :: String -> [String]
```

```haskell
-- 根据 token 将多个字符串连接为单个字符串
-- join(["foo", "bar", ";"], ",") :: "foo,bar,;"
-- join(["foo", "bar", ";"], "") :: "foobar;"
-- join([], ",") :: ""
-- join(["foo", "bar", nil], ",") :: nil
join :: [String] -> String -> String
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

-- 若切片长度小于 0，则返回 nil
-- str_slice("foobar;", 1, -2) := nil
str_slice :: String -> Number -> Number -> String
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
year   :: DateTime -> Number
month  :: DateTime -> Number
day    :: DateTime -> Number
hour   :: DateTime -> Number
minute :: DateTime -> Number
second :: DateTime -> Number
```

```haskell
-- 将一个日期时间增加 n 秒
-- add_seconds(~d"2020-01-01 00:00:00", 60) := ~d"2020-01-01 00:01:00"
-- add_seconds(~d"2020-01-01 00:00:00", -60) := ~d"2019-12-31 23:59:00"
-- add_seconds(~d"2020-01-01 00:00:00", 13.2) := nil
add_seconds :: DateTime -> Number -> DateTime
```

```haskell
-- 求两个日期时间的相差的秒数
-- diff_seconds(~d"2020-01-01 00:01:00", ~d"2020-01-01 00:00:00") := 60
-- diff_seconds(~d"2020-01-01 00:00:00", ~d"2020-01-01 00:01:00") := -60
-- diff_seconds(~d"2020-01-01 00:00:00", ~d"2020-01-01 00:00:00") := 0
diff_seconds :: DateTime -> DateTime -> Number
```

## Bool

```haskell
-- 求多个 Bool 值相「与」的结果
-- and_a([true, true, true]) := true
-- and_a([true, false, true]) := false

-- 空数组返回 true
-- and_a([]) := true

-- 短路
-- and_a([false, nil]) := false
-- and_a([nil, false]) := nil

-- 性质
-- and_a(xs) and and_a(ys) == and_a(Array.concat(xs, ys))
and_a :: [Bool] -> Bool
```

```haskell
-- 求多个 Bool 值相「或」的结果
-- or_a([false, false, false]) := false
-- or_a([true, false, true]) := true

-- 空数组返回 false
-- or_a([]) := false

-- 短路
-- or_a([true, nil]) := true
-- or_a([nil, true]) := nil

-- 性质
-- or_a(xs) or or_a(ys) == or_a(Array.concat(xs, ys))
or_a :: [Bool] -> Bool
```

## Array

```haskell
-- 求数组中位于下标 n 的元素（下标从 0 计数）
-- at([1, 2, 3], 1) := 2

-- 下标为负数时，从数组尾数起（-1 代表最后一个元素）
-- at([1, 2, 3], -1) := 3

-- 下标超出数组范围时返回 nil
-- at([1, 2, 3], 10) := nil

-- 需要注意该函数返回 nil 时并不总是上面的原因引起的，
-- 因为数组中可能含有 nil
-- at([1, nil, 3], 1) := nil

at :: [a] -> Number -> a
```

```haskell
-- 求数组长度
-- length([1, 2, 3]) := 3
-- length([]) := 0
length :: [a] -> Number
```

```haskell
-- 求数组中是否包含元素？
-- contains?([1, 2, 3], 1) := true
-- contains?([1, 2, 3], 4) := false

-- 注意该函数不被 nil 短路
-- contains?([1, nil, 3], nil) := true
-- contains?([1, 2, 3], nil) := false
contains? :: [a] -> a -> Bool
```

```haskell
-- 求第一个参数是否是第二个参数的子集？
-- subset?([1, 2], [1, 2, 3]) := true
-- subset?([1, 2, 3], [1, 2, 3]) := true

-- 顺序无关
-- subset?([3, 2], [1, 2, 3]) := true

-- 重复元素会被当成只出现过一次
-- subset?([1, 1, 1], [1, 2]) := true

-- 空数组是任意数组的子集
-- subset?([], [1, 2, 3]) := true
-- subset?([], []) := true
subset? :: [a] -> [a] -> Bool
```

```haskell
-- 求两数组是否互斥？（不共享任意元素）
-- disjoint?([1, 2], [2, 3]) := false
-- disjoint?([1, 2], [3, 4]) := true

-- 空数组与任意数组互斥
-- disjoint?([], [1, 2]) := true
-- disjoint?([], []) := true
disjoint? :: [a] -> [a] -> Bool
```

```haskell
-- 拼接两个数组
-- concat([1, 2], [3, 4]) := [1, 2, 3, 4]
concat :: [a] -> [a] -> [a]
```

```haskell
-- 数组去重；重复的元素仅保留第一次出现
-- uniq([1, 2, 3, nil, nil, 3, 2, 4]) := [1, 2, 3, nil, 4]
uniq :: [a] -> [a]
```

```haskell
-- 求数组交集；交集中元素的顺序与第一个参数的顺序相同
-- intersection([1, 2, 3], [3, 2, 4]) := [2, 3]
-- intersection([1, 2], [3, 4]) := []
intersection :: [a] -> [a] -> [a]
```

```haskell
-- 返回数组的反向版本
-- reverse([1, 2, 3]) := [3, 2, 1]
-- reverse([]) := []
reverse :: [a] -> [a]
```

```haskell
-- 求数组的切片；下标从 0 开始
-- 开始坐标是整数；数量是非负整数
-- slice([1, 2, 3, 4], 1, 2) := [2, 3]
-- slice([1, 2, 3, 4], -4, 2) := [1, 2]
-- slice([1, 2, 3, 4], 2, 0) := []
slice :: [a] -> Number -> Number -> [a]
```

## Miscellaneous

```haskell
-- 求参数是否为 nil？
is_nil? :: a -> Bool
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
