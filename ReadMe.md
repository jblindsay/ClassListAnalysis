Summary
=======

This is a simple D program for reading in class list files and performing summary analyses on the data, including an output listing of Majors and Minors. I can't imagine that this is going to have wide appeal beyond use in the Guelph Geography department but I've placed it in this repository for archiving. Also note, the code is a mess!

Build with:

```
ldmd2 GeographyStudentLists.d -w -de -release -inline -O -boundscheck=off
```

The program assumes that the class list data is stored in a sub-directory of the executable, e.g. 'W18'.
