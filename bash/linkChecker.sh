regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
string='https://reach.techstyle.net/'
if [[ $string =~ $regex ]]
then 
    echo "Link valid"
else
    echo "Link not valid"
fi
