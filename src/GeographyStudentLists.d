import std.algorithm;
import std.algorithm: canFind;
import std.array;
import std.conv;
/*import std.datetime.systime;*/
import std.datetime;
import std.file;
import std.math;
import std.path;
import std.stdio;
import std.string;

void main() {
  // Issue a greeting to the user
  writeln("********************************************");
  writeln("* Welcome to Geography Enrollment Analysis *");
  writeln("*                                          *");
  writeln("* For support contact Prof. John Lindsay   *");
  writeln("* email: jlindsay@uoguelph.ca              *");
  writeln("* version 1.2, released February 2018      *");
  writeln("********************************************");
  writeln("");

  // get the directory of the class list data
  string dataDirectory;
  write("Enter the name of the directory containing the class list data: ");
  readf(" %s\n", &dataDirectory);
  if (dataDirectory.indexOf(dirSeparator) == -1) {
    dataDirectory = thisExePath().dirName() ~ dirSeparator ~ dataDirectory;
  }
  if (!dataDirectory.exists()) {
    writeln("The directory '", dataDirectory, "' does not exist.");
    writeln("Hint: Place the subdirectory containing the class lists in the same folder as this program.");
    return;
  }

  // find the class list files
  string[] files = listdir(dataDirectory);

  if (files.length == 0) {
    writeln("The specified directory does not appear to contain any class list files.");
    return;
  }

  // find the semester value based on the file names
  string semester = "";
  foreach(file; files) {
    size_t a = file.indexOf("_");
    if (a > 0 && (startsWith(file.toLower(), "f") || startsWith(file.toLower(), "w"))) {
      semester = file[0..a];
      break;
    }
  }
  if (semester.length == 0) {
    writeln("The file names of the class list data do not appear to be formated correctly (e.g. W17_GEOG3480.txt)");
    writeln("Without this standard formatting, it is not possible to determine the semester correctly");
    return;
  } else {
    writeln("Reading class list data for semester %s".format(semester));
  }

  // read each class list file and mine it for data.
  const string[] listOfHomePrograms = ["BAH.EGOV", "BAH.GEOG", "BAG.GEOG", "BSCH.EGG", "BSES.ERM", "MA.GEOG", "MSC.GEOG", "PHD.GEOG"];
  int numStudents = 0;
  int numMajors = 0;
  int numNonMajors = 0;
  int revision = 99999;
  int[string] overallPrograms;
  int[string] geogMinors;
  int[int] levels;
  int[string] degrees;
  int[Student] geogStudentList;
  int[string] ourMajorHisto;
  int[Student] nongeogStudentList;
  int[Student] geogMinorStudentList;
  int[Student] gisMinorStudentList;

  // optionally output summary data for each class
  writeln();
  string response;
  write("Would you like to print summary information for each class? (Y or N) ");
  readf(" %s\n", &response);
  bool printClassSummaries = response.toLower().indexOf("y") >= 0;

  foreach(file; files) {
    if (file.indexOf("GEOG") >= 0) {
      auto stream = File(dataDirectory ~ dirSeparator ~ file,"r+");
      string className = file.replace(semester ~ "_", "").replace(".txt", "");
      int numStudentsInClass = 0;
      int numMajorsInClass = 0;
      int numNonMajorsInClass = 0;
      int[string] programs;
      foreach(line; stream.byLine()) {
        if (line.indexOf("Student ID,Last Name,First Name,Section,Course,Term,Program,Level,E-mail,Rev") == -1) {

          auto line_array = line.split(",");
          string prgm = to!string(line_array[6]).strip();
          const int studentID = to!int(line_array[0].strip());
          const string lastName = to!string(line_array[1]).strip();
          const string firstName = to!string(line_array[2]).strip();
          const string emailAddress = to!string(line_array[8]).strip();
          const string studentSemester = to!string(line_array[7]);
          const int rev = to!int(line_array[9].strip());
          if (rev < revision) { revision = rev; }

          Student stud = Student(firstName, lastName, studentID, emailAddress, prgm, studentSemester);

          // strip the minor from the programs
          if (prgm.indexOf("-") > -1) {
            if (prgm.indexOf("-GEOG") > -1 || prgm.indexOf("-GIS") > -1) {
              if ((prgm in geogMinors) !is null) {
                geogMinors[prgm] += 1;
              } else {
                geogMinors[prgm] = 1;
              }
              if (prgm.indexOf("-GEOG") > -1) {
                geogMinorStudentList[stud] = 1;
              } else {
                gisMinorStudentList[stud] = 1;
              }
            }
            auto sub = prgm[0..prgm.indexOf("-")];
            prgm = (to!string(sub)).strip;
          }
          if (prgm.indexOf("+") > -1) {
            auto sub = prgm[0..prgm.indexOf("+")];
            prgm = to!string(sub);
          }
          if (prgm.indexOf(":") > -1) {
            auto sub = prgm[0..prgm.indexOf(":")];
            prgm = to!string(sub);
          }

          // see if programs contains this prgm already
          if ((prgm in programs) !is null) {
            programs[prgm] += 1;
          } else {
            programs[prgm] = 1;
          }

          if ((prgm in overallPrograms) !is null) {
            overallPrograms[prgm] += 1;
          } else {
            overallPrograms[prgm] = 1;
          }

          numStudentsInClass++;
          bool isMajor = false;
          foreach (homeProgram; listOfHomePrograms) {
            if (prgm.indexOf(homeProgram) > -1) {
              numMajorsInClass++;
              geogStudentList[stud] = 1;
              isMajor = true;
            }
          }
          if (!isMajor) {
              nongeogStudentList[stud] = 1;
          }

          string k = to!string((line.split(","))[7]).strip;
          if (k !is null && k.length > 0 && k != "") {
              const double d = to!double(k);
              int lev = to!int(d);
              if ((lev in levels) !is null) {
                levels[lev] += 1;
              } else {
                levels[lev] = 1;
              }
          }

          string deg = prgm;
          if (deg.indexOf(".") > -1) {
            auto sub = deg[0..deg.indexOf(".")];
            deg = to!string(sub);
          }
          // see if degrees contains this deg already
          if ((deg in degrees) !is null) {
            degrees[deg] += 1;
          } else {
            degrees[deg] = 1;
          }
        }
      }

      numNonMajorsInClass = numStudentsInClass - numMajorsInClass;
      numMajors += numMajorsInClass;
      numNonMajors += numNonMajorsInClass;
      if (printClassSummaries) {
        writefln("\n%s: total=%s, majors=%s (%2.2f%%), non-majors=%s (%2.2f%%), num. programs=%s", className,
        numStudentsInClass, numMajorsInClass, 100.0*numMajorsInClass/numStudentsInClass, numNonMajorsInClass,
        100.0*numNonMajorsInClass/numStudentsInClass, programs.length);
      }
      numStudents += numStudentsInClass;

      if (printClassSummaries) {
        foreach (prgm; programs.keys.sort()) {
          bool isHomeProgram = false;
          foreach (homeProgram; listOfHomePrograms) {
            if (prgm.indexOf(homeProgram) > -1) {
              isHomeProgram = true;
            }
          }
          if (isHomeProgram) {
            writefln("%4s (%2.2f%%)\t%s", programs[prgm], 100.0*programs[prgm]/numStudentsInClass, prgm);
          }
        }
        foreach (prgm; programs.keys.sort()) {
          bool isHomeProgram = false;
          foreach (homeProgram; listOfHomePrograms) {
            if (prgm.indexOf(homeProgram) > -1) {
              isHomeProgram = true;
            }
          }
          if (!isHomeProgram) {
            writefln("%4s (%2.2f%%)\t%s", programs[prgm], 100.0*programs[prgm]/numStudentsInClass, prgm);
          }
        }
      }
    }
  }

  // Output a summary of our majors for the semester
  writeln();
  write("Would you like to print summary information for the majors? (Y or N) ");
  readf(" %s\n", &response);
  bool printMajorSummary = response.toLower().indexOf("y") >= 0;

  if (printMajorSummary) {
    writeln("\nOverall Statistics:");
    writefln("Number of classes: %s", files.length);
    writefln("Total num. students taught (bums in seats): %s", numStudents);
    writefln("Total num. non-majors taught (bums in seats): %s (%s%%)", numNonMajors, (100.0*numNonMajors/numStudents));
    writefln("Total num. majors taught (bums in seats): %s (%s%%)", numMajors, (100.0*numMajors/numStudents));
    writefln("Num. Programs: %s (excluding Geography's 8 programs)", to!int(overallPrograms.length) - 8);

    // writeln("Number of students in each major...");
    foreach (stud; geogStudentList.keys.sort()) {
      auto prgm = stud.program;
      if (prgm.indexOf("MA") == -1 && prgm.indexOf("PHD") == -1 && prgm.indexOf("MSC") == -1) {
        if (prgm.indexOf("-") > -1) {
          auto sub = prgm[0..prgm.indexOf("-")];
          prgm = (to!string(sub)).strip;
        }
        if (prgm.indexOf("+") > -1) {
          auto sub = prgm[0..prgm.indexOf("+")];
          prgm = to!string(sub);
        }
        if (prgm.indexOf(":") > -1) {
          auto sub = prgm[0..prgm.indexOf(":")];
          prgm = to!string(sub);
        }
        prgm ~= "-total";
        // const auto yr = to!int(stud.semester) % 2 + 1;
        // prgm ~= "-" ~ to!string(yr); //stud.semester;
        // prgm ~= to!string(yr);
        if ((prgm in ourMajorHisto) !is null) {
          ourMajorHisto[prgm] += 1;
        } else {
          ourMajorHisto[prgm] = 1;
        }
      }
    }
    // foreach (maj; ourMajorHisto.keys.sort) {
    //   writefln("%s\t%s", maj, ourMajorHisto[maj]);
    // }

    writeln("\n\nMajors by year:");
    foreach (stud; geogStudentList.keys.sort()) {
      auto prgm = stud.program;
      if (prgm.indexOf("MSC") == -1 && prgm.indexOf("MA") == -1 && prgm.indexOf("PHD") == -1) {
        if (prgm.indexOf("-") > -1) {
          auto sub = prgm[0..prgm.indexOf("-")];
          prgm = (to!string(sub)).strip;
        }
        if (prgm.indexOf("+") > -1) {
          auto sub = prgm[0..prgm.indexOf("+")];
          prgm = to!string(sub);
        }
        if (prgm.indexOf(":") > -1) {
          auto sub = prgm[0..prgm.indexOf(":")];
          prgm = to!string(sub);
        }
        const auto yr = to!int(floor(to!float(stud.semester) / 2.0)) + 1;
        prgm ~= "-" ~ to!string(yr);
        // prgm ~= stud.semester;
        if ((prgm in ourMajorHisto) !is null) {
          ourMajorHisto[prgm] += 1;
        } else {
          ourMajorHisto[prgm] = 1;
        }
      }
    }
    foreach (maj; ourMajorHisto.keys.sort()) {
      writefln("%s\t%s", maj, ourMajorHisto[maj]);
    }


    writeln("\n\nMinors breakdown:");
    int minorGeog = 0;
    int minorGIS = 0;
    foreach (prgm; geogMinors.keys.sort()) {
      if (prgm.indexOf("-GEOG") > -1) {
        minorGeog += geogMinors[prgm];
      }
    }
    foreach (prgm; geogMinors.keys.sort()) {
      if (prgm.indexOf("-GIS") > -1) {
        minorGIS += geogMinors[prgm];
      }
    }
    writeln("Geography minor: ", minorGeog);
    writeln("GIS and environmental analysis minor: ", minorGIS);
    writeln("");
    foreach (prgm; geogMinors.keys.sort()) {
      if (prgm.indexOf("-GEOG") > -1) {
        writefln("%3s\t%s", geogMinors[prgm], prgm);
      }
    }
    foreach (prgm; geogMinors.keys.sort()) {
      if (prgm.indexOf("-GIS") > -1) {
        writefln("%3s\t%s", geogMinors[prgm], prgm);
      }
    }
  }

  // Output the email lists for each major
  writeln();
  write("Would you like to create email lists for the majors? (Y or N) ");
  readf(" %s\n", &response);
  bool printEmailLists = response.toLower().indexOf("y") >= 0;

  if (printEmailLists) {
    foreach (program; listOfHomePrograms) {
      // don't print lists for the graduate students. The grad lists would be inaccurate because they don't take classes thoughout.
      if (program.indexOf("MSC") == -1 && program.indexOf("MA") == -1 && program.indexOf("PHD") == -1) {
        string out_file = thisExePath().dirName() ~ dirSeparator ~ "%s_%s.csv".format(semester, program.replace(".", "_"));
        writeln("Creating %s".format(out_file));
        auto f = File(out_file, "w");
        f.writeln("Program:,", program);
        f.writeln("Semester:,", semester);
        DateTime dateTime = cast(DateTime)Clock.currTime();
        f.writeln("Data compiled on %s based on class lists revision %s,".format(dateTime, revision));
        f.writeln(",");
        f.writeln("Program,Last Name,First Name,Student Number,Email,Class Level");
        foreach (stud; geogStudentList.keys.sort()) {
          if (stud.program.indexOf(program) >= 0) {
            f.writeln("%s,%s,%s,%s,%s,%s".format(stud.program, stud.lastName, stud.firstName, stud.number, stud.email, stud.semester));
          }
        }
        f.close();
      }
    }
    // Geography minor
    string out_file = thisExePath().dirName() ~ dirSeparator ~ "%s_%s.csv".format(semester, "GeogMinor");
    writeln("Creating %s".format(out_file));
    auto f = File(out_file, "w");
    f.writeln("Program:,", "Geography Minor");
    f.writeln("Semester:,", semester);
    DateTime dateTime = cast(DateTime)Clock.currTime();
    f.writeln("Data compiled on %s based on class lists revision %s,".format(dateTime, revision));
    f.writeln(",");
    f.writeln("Program,Last Name,First Name,Student Number,Email,Class Level");
    foreach (stud; geogMinorStudentList.keys.sort()) {
      if (stud.program.indexOf("-GEOG") >= 0) {
        f.writeln("%s,%s,%s,%s,%s,%s".format(stud.program, stud.lastName, stud.firstName, stud.number, stud.email, stud.semester));
      }
    }
    f.close();

    // GIS minor
    out_file = thisExePath().dirName() ~ dirSeparator ~ "%s_%s.csv".format(semester, "GISMinor");
    writeln("Creating %s".format(out_file));
    f = File(out_file, "w");
    f.writeln("Program:,", "GIS Minor");
    f.writeln("Semester:,", semester);
    dateTime = cast(DateTime)Clock.currTime();
    f.writeln("Data compiled on %s based on class lists revision %s,".format(dateTime, revision));
    f.writeln(",");
    f.writeln("Program,Last Name,First Name,Student Number,Email,Class Level");
    foreach (stud; gisMinorStudentList.keys.sort()) {
      if (stud.program.indexOf("-GIS") >= 0) {
        f.writeln("%s,%s,%s,%s,%s,%s".format(stud.program, stud.lastName, stud.firstName, stud.number, stud.email, stud.semester));
      }
    }
    f.close();
  }

  writeln("\nAnalysis complete! Goodbye for now.");
}

private string[] listdir(string pathname) {
    return std.file.dirEntries(pathname, SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => std.path.baseName(a.name))
        .array;
}

/// Student struct
public struct Student {
  /// Student first name
  string firstName = "";
  /// Student last name
  string lastName = "";
  /// Student number
  int number = 0;
  /// Student email
  string email = "";
  /// Student program
  string program;
  /// Student semester
  string semester;

  /// constructor
  this(string firstName, string lastName, int number, string email, string program, string semester) {
    this.firstName = firstName;
    this.lastName = lastName;
    this.number = number;
    this.email = email;
    this.program = program;
    this.semester = semester;
  }

  int opCmp(ref const Student o) const {
    if (this.lastName < o.lastName) {
      return -1;
    } else if (this.lastName > o.lastName) {
      return 1;
    }
    return 0;
  }
}
