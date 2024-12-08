MODULE uget;

IMPORT Args, SPARTAN, NEX, strTypes, Out, dynamicarray, GEMINI, Strings;


TYPE
  ARG = RECORD 
    protocol: ARRAY 64 OF CHAR;
    host: ARRAY 64 OF CHAR;
    path: ARRAY 246 OF CHAR;
    port: ARRAY 5 OF CHAR;
    prothost: strTypes.pstring;
END;

VAR 
  cmd: strTypes.pstring;
  arg: ARG;

PROCEDURE getFilename(): strTypes.pstring;

VAR 
  i,j: INTEGER;
  filen: strTypes.pstring;
BEGIN 
  i := 0; j := 1;
  NEW(filen, LEN(arg.path));
  REPEAT 
    filen^[i] := arg.path[j];
    INC(i); INC(j);
  UNTIL i = LEN(arg.path) - 1; 
 
  filen^[LEN(arg.path)-1] := 0X;
  RETURN filen
END getFilename;

PROCEDURE ConnectSpartan;
VAR 
  s: SPARTAN.Client;
  name, answer: strTypes.pstring;
  a: dynamicarray.dynamicarray;
BEGIN 
  s := SPARTAN.Create(arg.prothost^, arg.port, arg.path);
  answer := s.Get(s);
  name := getFilename();
  a := s.Save(s, name^);
  
END ConnectSpartan;



PROCEDURE ConnectNex;
 
VAR 
  s: NEX.Client;
  answer: strTypes.pstring;
  a: dynamicarray.dynamicarray;
  file: strTypes.pstring;

BEGIN 

  s := NEX.Create(arg.host, arg.port, arg.path);
  answer := s.Get(s);
  file := getFilename();
  a := s.Save(s, file^); 

END ConnectNex;

PROCEDURE getInputLength(str: ARRAY OF CHAR): INTEGER;
(*is corrupted, dont use*)
VAR 
  i: INTEGER;
BEGIN 
  i := 0;
  REPEAT 
   Out.Char(str[i]); Out.Ln;
   IF str[i] # 0X THEN INC(i); END;
  INC(i);
  UNTIL (i = LEN(str));
  Out.Int(i, 0); Out.Ln;
  RETURN i
END getInputLength;

PROCEDURE parseCommand(cmd: ARRAY OF CHAR);
VAR 
  i, j: INTEGER;
  host, protocol: ARRAY 64 OF CHAR;
  path: ARRAY 246 OF CHAR;
  port: ARRAY 5 OF CHAR;
  gport, sport, nport: ARRAY 5 OF CHAR;
BEGIN 
  i := 0; j := 0;
  gport := "3000";
  sport := "300";
  nport := "1900";

  (* 
  REPEAT 
    host[i] := cmd[i];
  UNTIL cmd[i] = ':'; *)


  WHILE (i < LEN(cmd)) & (cmd[i] # ':') DO
    protocol[i] := cmd[i];
    INC(i);
  END;
    protocol[i] := 0X;

  IF protocol = "gemini" THEN 
    COPY(gport, port);
  ELSIF protocol = "spartan" THEN 
    COPY(sport, port);
  ELSIF protocol = "nex" THEN 
    COPY(nport, port);
  ELSE
    Out.String("Unknown protocol: "); Out.String(protocol); Out.Ln;
    HALT(1);
  END;

  (* Skip "://" *)
  IF (i < LEN(cmd) - 2) & (cmd[i] = ':') & (cmd[i + 1] = '/') & (cmd[i + 2] = '/') THEN
    INC(i, 3);
  ELSE
    Out.String("Invalid URL format. Missing '://'."); Out.Ln;
    HALT(2);
  END;
   
  WHILE (i < LEN(cmd)) & (cmd[i] # '/') DO
     IF (i = LEN(cmd) - 1) THEN 
       Out.String("Invalid URL format. Missing '/'."); Out.Ln; HALT(4);
     END;
     host[j] := cmd[i];
     INC(i); INC(j); 
  END;
  host[j] := 0X;
  j := 0; 
  (* path needs to include the slash *)
  WHILE (i < LEN(cmd)) & (cmd[i] # 0X) DO
    path[j] := cmd[i];
    INC(i); INC(j);
  END;
  path[j] := 0X; (* Null-terminate *)
  IF (path = "/") THEN 
    Out.String("No path was interpreted. Aborting."); Out.Ln; HALT(6);
  END;
  Out.String("Parsed protocol: "); Out.String(protocol); Out.Ln;
  Out.String("Parsed host: "); Out.String(host); Out.Ln;
  Out.String("Parsed path: "); Out.String(path); Out.Ln;

arg.host := host;
arg.protocol := protocol;
arg.path := path;
arg.port := port;
END parseCommand;

PROCEDURE find(strone, strtwo: ARRAY OF CHAR): strTypes.pstring;
VAR 
i,j: INTEGER;
newstr: strTypes.pstring;
len1, len2, totalLen: INTEGER;
BEGIN 
len1 := Strings.Length(strone);
len2 := Strings.Length(strtwo);
totalLen := len1 + len2 + 2;
Out.String("length of the new str: "); Out.Int(totalLen, 0); Out.Ln;
NEW(newstr, totalLen);
IF newstr # NIL THEN 

  (*Strings.Append(newstr^, strone);*)
  (*Strings.Append(newstr^, dot);*)
  (*newstr^[len1] := ".";*)
  (*Strings.Append(newstr^, strtwo);*)
  i := 0; j := 0;
  REPEAT 
    newstr^[i] := strone[i];
    INC(i);
   UNTIL i = len1;
    newstr^[len1] := ".";
    INC(i);
   REPEAT
    newstr^[i] := strtwo[j];
    INC(i); INC(j); 
  UNTIL j = len2;
    newstr^[totalLen - 1] := 0X;
ELSE 
  Out.String("failed to initialize new string"); Out.Ln;
END;
Out.String("the result of the new string: "); Out.String(newstr^); Out.Ln;
RETURN newstr

END find;

PROCEDURE ConnectGemini;
BEGIN

Out.String("hello gemini"); Out.Ln;

END ConnectGemini;

PROCEDURE Main;
VAR 
  argLen: INTEGER;
  tmp: ARRAY 246 OF CHAR;
  (*something: strTypes.pstring;*)
BEGIN 
  IF Args.argc > 1 THEN 
    tmp := "";
    Args.Get(1, tmp);
    Out.String(tmp); Out.Ln;
    argLen := Strings.Length(tmp);
    Out.Int(argLen, 0); Out.Ln;
    NEW(cmd, argLen + 1); (* Allocate memory dynamically for cmd *)
    COPY(tmp, cmd^);
    cmd^[argLen] := 0X; (* Null-terminate the string *)
    Out.String("pstring to string cmd: "); Out.String(cmd^); Out.Ln;
    Out.Int(LEN(cmd^), 0); Out.Ln;
    parseCommand(cmd^);
    arg.prothost := find(arg.protocol, arg.host);
    Out.String("#####################################"); Out.Ln;
    Out.String("prothost: "); Out.String(arg.prothost^); Out.Ln;
    Out.String("port: "); Out.String(arg.port); Out.Ln;
    Out.String("path: "); Out.String(arg.path); Out.Ln;
    (*something := getFilename();
    Out.String("filename is"); Out.String(something^); Out.Ln;*)
    IF arg.prothost^ = "spartan.mozz.us" THEN 
       ConnectSpartan; 
    ELSIF arg.prothost^ = "nex.mozz.us" THEN 
       ConnectNex; 
    ELSIF arg.prothost^ = "gemini.mozz.us" THEN 
       ConnectGemini; 
    END;
  ELSE 
    Out.String("Usage: protocol://host/path"); Out.Ln;
  END;
END Main;

BEGIN 
  Main;
END uget.

(*MODULE uget;

IMPORT Args, SPARTAN, NEX, strTypes, Out, dynamicarray, GEMINI;

VAR 
cmd: strTypes.pstring;

PROCEDURE ConnectSpartan*;
VAR 
  s: SPARTAN.Client;
  answer: strTypes.pstring;
  a: dynamicarray.dynamicarray;
BEGIN 
  (*s := SPARTAN.Create(cmd);*)

END ConnectSpartan;

PROCEDURE parseCmd(cmd: ARRAY OF CHAR);
VAR 
  i,j: INTEGER;
  host: ARRAY 64 OF CHAR;
  path: ARRAY 264 OF CHAR;
  port: ARRAY 5 OF CHAR;
  geminiport, spartanport, nexport: ARRAY 5 OF CHAR;
BEGIN
  i := 0; j := 0; 
  geminiport := "3000";
  spartanport := "300";
  nexport := "1900";
  REPEAT 
   (*IF cmd[i] # NIL THEN *)
    host[i] := cmd[i];
    IF cmd[i] = "/" THEN 
       IF cmd[i+1] = "/" THEN 
          host[i] := cmd[i];
          host[i+1] := cmd[i+1];
          host[i + 2] := 0X;
          Out.String("appended host"); Out.String(host); Out.Ln;
        END;
    ELSE 
       Out.String("Host should be in the format: protocol ,':', '/', '/', you are missing the second slash"); Out.Ln;
       Out.String("current parsed host: "); Out.String(host); Out.Ln;

    END;
        IF host = "gemini://" THEN 
        COPY(geminiport, port);
        Out.String("byouhaakimaero...shinumonoga"); Out.Ln;  
    ELSIF host = "spartan://" THEN 
        COPY(spartanport, port);
    ELSIF host = "nex://" THEN 
        COPY(nexport, port);
    ELSE
       Out.String("unknown host, aborting"); HALT(1);
    END; 
    INC(i);
     
    IF cmd[i] = "/" THEN 
         Out.String("found a slash"); Out.Ln;
         path[j] := cmd[i];
    ELSE 
         Out.String("there is no slash after host, aborting"); HALT(2); 
    END;
    INC(j);     
    path[j] := cmd[i];
     (*ELSE
       Out.String("Null cmd");
    END;*)
  INC(i);
  UNTIL i = LEN(cmd);
  Out.String("Parsed path: "); Out.String(path); Out.Ln;   

END parseCmd;

PROCEDURE parseCommand(cmd: ARRAY OF CHAR);
VAR
i,j: INTEGER;
host: ARRAY 64 OF CHAR;
path: ARRAY 246 OF CHAR;
port: ARRAY 5 OF CHAR;
gport, sport, nport: ARRAY 5 OF CHAR;

BEGIN 
i := 0; j := 0;
gport := "3000";
sport := "300";
nport := "1900";

REPEAT 
IF cmd[i] # 0X THEN 
   Out.String("Current character: '"); Out.Char(cmd[i]); Out.String("'"); Out.Ln;
ELSE 
  Out.String("Dont try looking at nil content"); Out.Ln;
END;
INC(i);

UNTIL i = LEN(cmd);

END parseCommand;


PROCEDURE getInputLength(cmd: ARRAY OF CHAR): INTEGER;
(* corrupted, dont use *)
VAR 
i: INTEGER;

BEGIN 
Out.String("ENTERED getinputlength"); Out.Ln;
i := 0;
REPEAT 
IF cmd[i] # 0X THEN INC(i); 
ELSE 
Out.String("null command");

END;
UNTIL i = LEN(cmd);
RETURN i;
Out.String("LEFT getinputlength"); Out.Ln;
END getInputLength;

PROCEDURE Main;
VAR 
argLen: INTEGER;
tmp: ARRAY 246 OF CHAR;
BEGIN 
Out.String("ENTERED Main"); Out.Ln;
  IF Args.argc > 1 THEN 
Out.String("there is an argument"); Out.Ln;
(*Out.String("assigned inputlength of cmd to arglen"); Out.Ln;*)
    Args.Get(1, tmp);
    argLen := getInputLength(tmp);
    NEW(cmd, argLen + 1);
    COPY(tmp, cmd^);
    cmd^[argLen] := 0X;
    parseCommand(cmd^);
  ELSE 
    Out.String("Usage: protocol://host/path"); Out.Ln;
  END;

END Main; 


BEGIN 

Main;



END uget.*)
