MODULE test;
IMPORT Out, Strings, strUtils, Internet, dynamicarray;

VAR eol: ARRAY 3 OF CHAR;

PROCEDURE zeroBuf(VAR str: ARRAY OF CHAR);
VAR
  i: INTEGER;
BEGIN
  i := 0; 
  REPEAT
    str[i] := 0X;
    INC(i)
  UNTIL i = LEN(str);
END zeroBuf;
(*
PROCEDURE readUntil0D0A(VAR conn: LONGINT; VAR initialArray: ARRAY OF CHAR);
VAR
  buf: ARRAY 64 OF CHAR;
  i, j, k: LONGINT;
  b, found: BOOLEAN;
BEGIN
  i := 0;
  zeroBuf(buf);
  b := Internet.ReadBuf(conn, buf, i); 
  j := 0; found := FALSE;
  REPEAT
    IF buf[j] = 0AX THEN found := TRUE END;
    INC(j);
  UNTIL found OR (j = i) OR (j = LEN(buf) -1); (* to check later *)
  k := 0;
  IF found THEN
      
      initialArray[k] := buf[j];
      INC(k); INC(j);
    UNTIL 
  ELSE
  (* we need to think of this *)
  END;
END readUntil0D0A; *)

PROCEDURE get(hostname, resource: ARRAY OF CHAR);
VAR
  conn: LONGINT;
  b: BOOLEAN;
  buf: ARRAY 16 OF CHAR;
  req: ARRAY 512 OF CHAR;
  i, k: LONGINT;
  arr: dynamicarray.dynamicarray;
BEGIN
   arr := dynamicarray.Create();
   b := Internet.Connect(hostname, "300", conn);
   zeroBuf(req);
   IF b THEN 
     Strings.Append(hostname, req);
     Strings.Append(" ", req);
     Strings.Append(resource, req);
     Strings.Append(" 0", req);
     Strings.Append(eol, req);
     b := Internet.Write(conn, req);
     IF b THEN
       (*readUntil0D0A(conn);*)
       i := 0;
       k := 0;
       REPEAT
         zeroBuf(buf);
         b := Internet.ReadBuf(conn, buf, i); 
         Out.String("-------------"); Out.Ln;
         Out.String(buf); Out.Ln;
         Out.String("-------------"); Out.Ln;
         IF k = 0 THEN arr.appender(arr, ""); Out.String("tried to skip appending"); Out.Ln; ELSE arr.appender(arr, buf); END;
         Out.String("arr = "); Out.Ln;
         Out.String("-------------------------------------------------"); Out.Ln;
         Out.String(arr^.content^); Out.Ln;
         Out.String("-------------------------------------------------"); Out.Ln;
         INC(k);

       UNTIL ~b OR (i = 0);
       Internet.Disconnect(conn);
     ELSE
       Out.String("failed to send request"); Out.Ln;
     END
   ELSE
     Out.String("unable to connect"); Out.Ln
   END;
   Out.String("got everything"); Out.Ln;
   dynamicarray.writetofile(arr, "aaa.txt");
END get;


BEGIN
  eol[0] := 0DX;
  eol[1] := 0AX;
  eol[2] := 0X;
  (*get("127.0.0.1", "/index.gmi");*)
  get("spartan.mozz.us", "/specification.gmi");
 
END test.

