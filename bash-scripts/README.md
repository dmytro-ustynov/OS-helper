# BASH scripts

## 1. Conditional Statements
In Bash, conditional statements allow you to execute commands based on certain conditions.

Example:
```bash
#!/bin/bash

read -p "Enter a number: " num

if (( num > 10 )); then
  echo "Number is greater than 10"
elif (( num == 10 )); then
  echo "Number is equal to 10"
else
  echo "Number is less than 10"
fi
```
if statement checks a condition.
elif is an "else if" to check additional conditions.
else handles the remaining cases.

#### File Existence Check:

```bash
#!/bin/bash

file="myfile.txt"

if [[ -f "$file" ]]; then
  echo "File exists."
else
  echo "File does not exist."
fi
```
`-f` checks if the file exists and is a regular file.

## 2. For and While Loops
Loops allow you to repeat tasks.

For Loop Example:

```bash
#!/bin/bash

for i in {1..5}; do
  echo "Loop iteration $i"
done
```

While Loop Example:
```bash
#!/bin/bash

count=1

while [[ $count -le 5 ]]; do
  echo "Count: $count"
  ((count++))
done
```

For Loop with Array:
```bash
#!/bin/bash

arr=("apple" "banana" "cherry")

for fruit in "${arr[@]}"; do
  echo "Fruit: $fruit"
done
```

## 3. Reading Files and Getting File Contents
You can read files line by line or get the whole file’s contents.

Reading a File Line by Line:

```bash
#!/bin/bash

filename="myfile.txt"

while IFS= read -r line; do
  echo "Line: $line"
done < "$filename"
```

Reading File Contents into a Variable:

```bash
#!/bin/bash

content=$(<myfile.txt)
echo "File Content: $content"
```

## 4. Reading Directories and Iterating File Structure
Bash can easily work with directories and files within them.

Listing Files in a Directory:

```bash
#!/bin/bash

directory="mydir"

for file in "$directory"/*; do
  if [[ -f $file ]]; then
    echo "File: $file"
  fi
done
```

### Recursive Directory Traversal:

```bash
#!/bin/bash

directory="mydir"

find "$directory" -type f | while read -r file; do
  echo "Found file: $file"
done
```

## 5. String Operations, Substitutions, Slices, and Regex
Bash provides various methods for handling strings, including pattern matching and slicing.

Substring Extraction:
```bash
#!/bin/bash

string="Hello, World!"
echo "First 5 chars: ${string:0:5}"      # Outputs "Hello"
echo "Substring: ${string:7:5}"          # Outputs "World"
```

#### String Replacement:
```bash
#!/bin/bash

str="I love apples"
echo "${str/apples/oranges}"             # Replace first occurrence
echo "${str//apples/oranges}"            # Replace all occurrences
```

#### Pattern Matching with Regex:
```bash
#!/bin/bash

string="Hello123"

if [[ $string =~ ^Hello[0-9]+$ ]]; then
  echo "The string starts with 'Hello' and ends with numbers."
else
  echo "The string doesn't match the pattern."
fi
```

#### Extracting a Substring Using Pattern Matching:

```bash
#!/bin/bash

filename="file.tar.gz"

# Remove the longest match of *. from the beginning
echo "${filename##*.}"  # Outputs "gz"

# Remove the shortest match of *. from the end
echo "${filename%.*}"   # Outputs "file.tar"
```

These examples should give you a good starting point for using Bash scripting to automate tasks and work with files, strings, and more!