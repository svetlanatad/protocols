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

PROCEDURE get(hostname, resource: ARRAY OF CHAR);
VAR
  conn: LONGINT;
  b: BOOLEAN;
  buf: ARRAY 16 OF CHAR;
  req: ARRAY 512 OF CHAR;
  i: LONGINT;
  arr: dynamicarray.dynamicarray;
BEGIN
   arr := dynamicarray.Create();
   b := Internet.Connect(hostname, "3000", conn);
   zeroBuf(req);
   IF b THEN 
     Strings.Append(hostname, req);
     Strings.Append(" ", req);
     Strings.Append(resource, req);
     Strings.Append(" 0", req);
     Strings.Append(eol, req);
     b := Internet.Write(conn, req);
     IF b THEN
       i := 0;
       REPEAT
         zeroBuf(buf);
         b := Internet.ReadBuf(conn, buf, i); 
         Out.String("-------------"); Out.Ln;
         Out.String(buf); Out.Ln;
         arr.appender(arr, buf);
         Out.String("arr = "); Out.Ln;
         Out.String("-------------------------------------------------"); Out.Ln;
         Out.String(arr^.content^); Out.Ln;
         Out.String("-------------------------------------------------"); Out.Ln;
         Out.String("-------------"); Out.Ln;
       UNTIL ~b OR (i = 0);
       Internet.Disconnect(conn);
     ELSE
       Out.String("failed to send request"); Out.Ln;
     END
   ELSE
     Out.String("unable to connect"); Out.Ln
   END;
   Out.String("got everything"); Out.Ln
END get;


BEGIN
  eol[0] := 0DX;
  eol[1] := 0AX;
  eol[2] := 0X;
  get("127.0.0.1", "/index.gmi");
 
END test.

