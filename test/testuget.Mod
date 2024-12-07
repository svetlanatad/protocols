MODULE uget;

IMPORT Args, Out;

TYPE 
  arg = RECORD 
    host: ARRAY 64 OF CHAR;
    path: ARRAY 246 OF CHAR;
    port: ARRAY 5 OF CHAR;
END;

VAR 
  cmd: POINTER TO ARRAY OF CHAR;

PROCEDURE ConnectSpartan*;
BEGIN 
Out.String("spartan"); Out.Ln;
END ConnectSpartan;

PROCEDURE getInputLength(str: ARRAY OF CHAR): INTEGER;
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
  host, path, protocol: ARRAY 64 OF CHAR;
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

  (* Validate protocol *)
  IF protocol = "gemini" THEN 
    COPY(gport, port);
  ELSIF protocol = "spartan" THEN 
    COPY(sport, port);
  ELSIF protocol = "nex" THEN 
    COPY(nport, port);
  ELSE
    Out.String("Unknown protocol: "); Out.String(host); Out.Ln;
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
     IF (i = 74) THEN 
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

  Out.String("Parsed protocol: "); Out.String(protocol); Out.Ln;
  Out.String("Parsed host: "); Out.String(host); Out.Ln;
  Out.String("Parsed path: "); Out.String(path); Out.Ln;
END parseCommand;

PROCEDURE Main;
VAR 
  argLen: INTEGER;
  tmp: ARRAY 246 OF CHAR;
BEGIN 
  IF Args.argc > 1 THEN 
    Args.Get(1, tmp);
    Out.String(tmp); Out.Ln;
    argLen := getInputLength(tmp);
    NEW(cmd, argLen + 1); (* Allocate memory dynamically for cmd *)
    COPY(tmp, cmd^);
    cmd^[argLen] := 0X; (* Null-terminate the string *)
    parseCommand(cmd^);
  ELSE 
    Out.String("Usage: protocol://host/path"); Out.Ln;
  END;
END Main;

BEGIN 
  Main;
END uget.
