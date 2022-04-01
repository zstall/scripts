# use nullglob in case there are no matching files
shopt -s nullglob

# create an array with all the filer/dir inside ~/myDir
arr=(/Users/zstall/Documents/scripts/bash/testing/*)

echo "${arr}"
# iterate through array using a counter
for ((i=0; i<${#arr[@]}; i++)); do
    #do something to each element of array
    basename "${arr[$i]}"

done
echo "Get the 5th newest file: "
basename "${arr[4]}"