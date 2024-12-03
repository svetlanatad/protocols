MODULE TestModule;

IMPORT Args, SPARTAN, NEX, strTypes, Out, dynamicarray;

VAR 
command: ARRAY 64 OF CHAR;

PROCEDURE ConnectSpartan*;
VAR
s: SPARTAN.Client;
answer: strTypes.pstring;
a: dynamicarray.dynamicarray;
BEGIN 
  Out.String("trying to connect"); Out.Ln;
  s := SPARTAN.Create("spartan.mozz.us", "300", "/specification.gmi");
  Out.String("created connection"); Out.Ln;
  answer := s.Get(s);
  Out.String("response"); Out.String(answer^);
  a := s.Save(s, "SPECIFICTEST.txt");

END ConnectSpartan;

PROCEDURE ConnectNex*;
VAR 
s: NEX.Client;
answer: strTypes.pstring;
a: dynamicarray.dynamicarray;

BEGIN 
Out.String("running nex"); Out.Ln;
s := NEX.Create("mozz.us", "1900", "/nex-protocol-notes.txt");
answer := s.Get(s);
a := s.Save(s, "NEXTEST.txt");

END ConnectNex;

PROCEDURE Main*;
BEGIN
  IF Args.argc > 1 THEN
    Args.Get(1, command);
    IF command = "spartan" THEN
      ConnectSpartan;
    ELSIF command = "nex" THEN
      ConnectNex;
    ELSE
      Out.String("Unknown command: "); Out.String(command); Out.Ln;
    END;
  ELSE
    Out.String("Usage: connect <spartan|nex>"); Out.Ln;
  END;
END Main;

BEGIN 

Main;

END TestModule.
