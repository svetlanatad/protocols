MODULE uget;

IMPORT Args, SPARTAN, NEX, strTypes, Out, dynamicarray, GEMINI, Strings, http, https;


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
  arg: ARG; (* TODO get rid of global, move to Main *)

PROCEDURE findslash(str: ARRAY OF CHAR): BOOLEAN;
VAR 
  i: INTEGER;
  b: BOOLEAN;
BEGIN 
  i := 1;
  b := FALSE;
  REPEAT
    IF (str[i] = '/') THEN 
      b := TRUE;
    END;
    INC(i); 
  UNTIL i = LEN(str);
RETURN b
END findslash;

PROCEDURE getFilename(): strTypes.pstring;

VAR 
  i,j: INTEGER;
  filen: strTypes.pstring;
  b: BOOLEAN;
  def: ARRAY 16 OF CHAR;
BEGIN 
  b := findslash(arg.path);
  def := "";
  IF ~b THEN  
    i := 0; j := 1;
    NEW(filen, LEN(arg.path));
    REPEAT 
      filen^[i] := arg.path[j];
      INC(i); INC(j);
    UNTIL i = LEN(arg.path) - 1; 
 
    filen^[LEN(arg.path)-1] := 0X;
    RETURN filen;
  ELSE 
     NEW(filen, LEN(def)+1);
     def := SPARTAN.defName;
     COPY(def, filen^);
     filen^[LEN(def)] := 0X;
     Out.String("File name was set as default. URL path contained an illegal character: "); Out.String(filen^); Out.Ln;
     RETURN filen;
   END;
END getFilename;

PROCEDURE ConnectSpartan;
VAR 
  s: SPARTAN.Client;
  name, answer: strTypes.pstring;
  a: dynamicarray.dynamicarray;
BEGIN 
  s := SPARTAN.Create(arg.host, arg.port, arg.path);
  answer := s.Get(s);
  name := getFilename();
  a := s.Save(s, name^);
  
END ConnectSpartan;

PROCEDURE ConnectGemini;
VAR 
  g: GEMINI.Client;
  name, answer: strTypes.pstring;
  a: dynamicarray.dynamicarray;
BEGIN
 g := GEMINI.Create(arg.host, arg.port, arg.path);
 Out.String("trying to initialize socket"); Out.Ln;
 g.Init(g);
 Out.String("left init in connect gemini"); Out.Ln;
 answer := g.Get(g);
 name := getFilename();
 a := g.Save(g, name^); 

END ConnectGemini;


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
 

PROCEDURE ConnectHttp;
VAR 
  h: http.Client; 
  answer: strTypes.pstring;

BEGIN 
  h := http.Create(arg.host, arg.port, arg.path);
  (*h.appendAuthHdr(h, "sona", "sona");*)
  answer := h.Get(h);
  h.Save(h);

END ConnectHttp;



PROCEDURE ConnectHttps;
VAR 
  h: https.TLSClient; 
  answer: strTypes.pstring;

BEGIN 
  h := https.Create(arg.host, arg.port, arg.path);
  h.Init(h);
  Out.String("________________________________________"); Out.Ln;
  Out.String("host="); Out.String(arg.host); Out.Ln;
  Out.String("port="); Out.String(arg.port); Out.Ln;
  Out.String("path="); Out.String(arg.path); Out.Ln;
  Out.String("________________________________________"); Out.Ln;
  answer := h.Get(h);
  h.Save(h);

END ConnectHttps;

PROCEDURE ConnectHttpsAuth(usr: ARRAY OF CHAR; pwd: ARRAY OF CHAR);

VAR 
  h: https.TLSClient;
  answer: strTypes.pstring;
BEGIN
  Out.String("Entered ConnectHttpsAuth"); Out.Ln; 
  h := https.Create(arg.host, arg.port, arg.path);
  h.appendAuthHdr(h, usr, pwd);
  h.Init(h);
  answer := h.Get(h); 
  h.Save(h);

END ConnectHttpsAuth;


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
  gport, sport, nport, hport, hsport: ARRAY 5 OF CHAR;
BEGIN 
  i := 0; j := 0;
  gport := "1965";
  sport := "300";
  nport := "1900";
  hport := "80";
  hsport := "443";

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
  ELSIF protocol = "http" THEN 
    COPY(hport, port);
  ELSIF protocol = "https" THEN 
    COPY(hsport, port);
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

PROCEDURE getCommand(i: INTEGER): strTypes.pstring;
VAR 
  argLen: INTEGER;
  tmp: ARRAY 246 OF CHAR;
  cmd: strTypes.pstring;
BEGIN 
  tmp := "";
  Args.Get(i, tmp);
  Out.String(tmp); Out.Ln;
  argLen := Strings.Length(tmp);
  Out.Int(argLen, 0); Out.Ln;
  NEW(cmd, argLen + 1); (* Allocate memory dynamically for cmd *)
  COPY(tmp, cmd^);
  cmd^[argLen] := 0X; (* Null-terminate the string *)
  Out.String("pstring to string cmd: "); Out.String(cmd^); Out.Ln;
 
RETURN cmd

END getCommand;

PROCEDURE Main;
VAR 
  argLen: INTEGER;
  tmp: ARRAY 246 OF CHAR;
  cmd: strTypes.pstring;
  usr: strTypes.pstring;
  pwd: strTypes.pstring;
  (*something: strTypes.pstring;*)
BEGIN 
  IF Args.argc = 2 THEN
      cmd := getCommand(1); 
      (*tmp := "";
      Args.Get(1, tmp);
      Out.String(tmp); Out.Ln;
      argLen := Strings.Length(tmp);
      Out.Int(argLen, 0); Out.Ln;
      NEW(cmd, argLen + 1); (* Allocate memory dynamically for cmd *)
      COPY(tmp, cmd^);
      cmd^[argLen] := 0X; (* Null-terminate the string *)
      Out.String("pstring to string cmd: "); Out.String(cmd^); Out.Ln;
      Out.Int(LEN(cmd^), 0); Out.Ln;*)

      parseCommand(cmd^);
      arg.prothost := find(arg.protocol, arg.host);
      Out.String("#####################################"); Out.Ln;
      Out.String("prothost: "); Out.String(arg.prothost^); Out.Ln;
      Out.String("port: "); Out.String(arg.port); Out.Ln;
      Out.String("path: "); Out.String(arg.path); Out.Ln;
      (*something := getFilename();
      Out.String("filename is"); Out.String(something^); Out.Ln;*)
      IF arg.protocol = "spartan" THEN 
         ConnectSpartan; 
      ELSIF arg.protocol = "nex" THEN 
         ConnectNex; 
      ELSIF arg.protocol = "gemini" THEN
         ConnectGemini; 
      ELSIF arg.protocol = "http" THEN 
         ConnectHttp;
      ELSIF arg.protocol = "https" THEN
         ConnectHttps;
      ELSE
         Out.String("unknown protocol: "); Out.String(arg.protocol); Out.Ln;
      END;
     ELSIF Args.argc > 2 THEN 
      cmd := getCommand(2);
      (*tmp := "";
      Args.Get(2, tmp);
      Out.String(tmp); Out.Ln;
      argLen := Strings.Length(tmp);
      Out.Int(argLen, 0); Out.Ln;
      NEW(cmd, argLen + 1); (* Allocate memory dynamically for cmd *)
      COPY(tmp, cmd^);
      cmd^[argLen] := 0X; (* Null-terminate the string *)
      Out.String("pstring to string cmd: "); Out.String(cmd^); Out.Ln;
      Out.Int(LEN(cmd^), 0); Out.Ln;*)
        IF cmd^ = "-u" THEN 
             cmd := getCommand(4);
             (* 
             tmp := "";
             Args.Get(4, tmp);
             Out.String(tmp); Out.Ln;
             argLen := Strings.Length(tmp);
             Out.Int(argLen, 0); Out.Ln;
             NEW(cmd, argLen + 1); (* Allocate memory dynamically for cmd *)
             COPY(tmp, cmd^);
             cmd^[argLen] := 0X; (* Null-terminate the string *)
             Out.String("pstring to string cmd: "); Out.String(cmd^); Out.Ln;
             Out.Int(LEN(cmd^), 0); Out.Ln;*)
		IF cmd^ = "-p" THEN 
                   usr := getCommand(3);
                   (*tmp := "";
                   Args.Get(3, tmp);
                   Out.String(tmp); Out.Ln;
                   argLen := Strings.Length(tmp);
                   Out.Int(argLen, 0); Out.Ln;
                   NEW(usr, argLen + 1); (* Allocate memory dynamically for cmd *)
                   COPY(tmp, usr^);
                   usr^[argLen] := 0X; (* Null-terminate the string *)
                   Out.String("pstring to string usr: "); Out.String(usr^); Out.Ln;
                   Out.Int(LEN(usr^), 0); Out.Ln;*)
                   pwd := getCommand(5);
                   IF pwd^ = "" THEN Out.String("Warning: Your password is blank"); Out.Ln; END;
                   cmd := getCommand(1); 
                   Out.String("parsing the following command: "); Out.String(cmd^); Out.Ln;
                   parseCommand(cmd^); 
                   IF arg.protocol = "https" THEN ConnectHttpsAuth(usr^, pwd^); 
                   ELSE 
                      Out.String("Authentication not yet implemented for the following protocol: "); Out.String(arg.protocol); Out.Ln; HALT(6);
                   END;
               
                   (*tmp := "";
                   Args.Get(5, tmp);
                   Out.String(tmp); Out.Ln;
                   argLen := Strings.Length(tmp);
                   Out.Int(argLen, 0); Out.Ln;
                   NEW(pwd, argLen + 1); (* Allocate memory dynamically for cmd *)
                   COPY(tmp, pwd^);
                   pwd^[argLen] := 0X;
                   Out.String("pstring to string pwd: "); Out.String(pwd^); Out.Ln;
                   Out.Int(LEN(pwd^), 0); Out.Ln;*)
                   ELSE 
                      Out.String("Usage: protocol://path-to-file.extension -u username -p password"); Out.Ln;
                   END;
                   ELSE 
                      Out.String("Usage: protocol://path-to-file.extension -u username -p password"); Out.Ln;
                   END;
                  
                    
  ELSE
    Out.String("Usage: protocol://host/path [-u | username -p password]" ); Out.Ln;
  END;
END Main;

BEGIN 
  Main;
END uget.

