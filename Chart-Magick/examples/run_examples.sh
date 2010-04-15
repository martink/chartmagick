for file in ./*.pl
do
    echo "processing ${file}"
    perl ${file}
done
