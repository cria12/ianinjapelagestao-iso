for prog in v4l2gl v4l2grab
do
   if [ -f contrib/test/$prog ]; then cp -v contrib/test/$prog /usr/bin; fi
done
